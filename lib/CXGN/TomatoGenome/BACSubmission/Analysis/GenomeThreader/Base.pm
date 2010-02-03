package CXGN::TomatoGenome::BACSubmission::Analysis::GenomeThreader::Base;
use strict;
use warnings;
use base qw/CXGN::TomatoGenome::BACSubmission::Analysis/;
use Carp;
use English;
use CXGN::Tools::File qw/executable_is_in_path/;
use CXGN::Annotation::GAMEXML::FromFile qw/gthxml_to_game_xml/;

sub un_xed_genomic_seqs {
  my ($self,$submission) = @_;

  #make the un-xed seqs file if necessary
  unless ( $self->{un_xed_seqs_file} && -s $self->{un_xed_seqs_file} ) {
    my $un_xed_seqs = $self->analysis_generated_file($submission,'un_xed_seqs');
    my $vector_screened_seqs = $submission->vector_screened_sequences_file;
    open my $xfile, '<', $vector_screened_seqs
      or confess "could not open '$vector_screened_seqs' for reading: $!";
    open my $nfile, '>', $un_xed_seqs
      or confess "could not open un-xed-seqs file '$un_xed_seqs' for writing: $!";
    while (my $line = <$xfile>) {
      unless($line =~ /^\s*[>#]/) {   #don't munge identifier or comment (comment?) lines
	$line =~ tr/X/N/;
      }
      print $nfile $line;
    }
    $self->{un_xed_seqs_file} = $un_xed_seqs;
  }
  return $self->{un_xed_seqs_file};
}

sub output_files {
  my ($self, $submission) = @_;

  my @files = my ($cdna_file,$outfile,$errfile,$game_xml_file,$gff3_out_file) =
    $self->_fileset({},$submission);

  shift @files;
  return @files;
}

#run genomethreader analysis
sub run {
    my $self = shift;
    my $submission = shift;     #BACSubmission object
    my $aux_inputs = shift;     #hash ref of auxiliary inputs

    #decide all the places where our various files are or should go
    my $gth_exec             = find_gth($aux_inputs);
    my $un_xed_seqs          = $self->un_xed_genomic_seqs($submission);

    my ($cdna_file,$outfile,$errfile,$game_xml_file,$gff3_out_file) =
        $self->_fileset($aux_inputs,$submission);

    #symlink the cdna file into our submission's temp dir
    my $local_cdna = File::Spec->catfile( $submission->_tempdir, 'gth_cdna_file'.ref($self));
    -l $local_cdna
        or symlink( $cdna_file, $local_cdna )
            or die "$! symlinking '$local_cdna' -> '$cdna_file'";

    unless ($ENV{CXGNBACSUBMISSIONFAKEANNOT}) {
        my $gs_est_job = CXGN::Tools::Run->run( $gth_exec,
                                                '-xmlout',
                                                -minalignmentscore => '0.90',
                                                -mincoverage       => '0.90',
                                                -seedlength        => 16,
                                                -species => 'arabidopsis',
                                                -cdna    => $local_cdna,
                                                -genomic => $un_xed_seqs,
                                                { out_file => $outfile,
                                                  err_file => $errfile,
                                                }
                                              );

        #convert the geneseqer output to gamexml if it's a finished bac,
        #otherwise write a 'not supported' comment into the file and leave
        #it at that
        if ($submission->is_finished) {
            eval {
                gthxml_to_game_xml( $submission->vector_screened_sequences_file,$outfile,$game_xml_file,
                                    program_name  => $self->analysis_name,
                                    database_name => $self->_dbname,
                                  );
            }; if( $EVAL_ERROR ) {
                die $EVAL_ERROR unless $EVAL_ERROR =~ /not well-formed \(invalid token\)/;
                $submission->_write_gth_parse_error_bac_xml_stub( $game_xml_file );
            }
         } else {
            $submission->_write_unfinished_bac_xml_stub($game_xml_file);
        }

        eval {
            #now convert the gthxml to gff3
            my $gth_in = Bio::FeatureIO->new( -format => 'gthxml', -file => $outfile, -mode => $self->_parse_mode );
            my $gff3_out = $submission->_open_gff3_out($gff3_out_file);
            while ( my $f = $gth_in->next_feature ) {

                #set each feature's source to the name of the gth subclass that's running this
                $self->_recursive_source($f,$self->analysis_name);

                #make some ID and Parent tags in the subfeatures
                $self->_make_gff3_id_and_parent($f);
                $gff3_out->write_feature($f);
            }
        }; if( $EVAL_ERROR ) {
            #workaround for a gth bug.  will probably be fixed when we upgrade gth
            die $EVAL_ERROR unless $EVAL_ERROR =~ /not well-formed \(invalid token\)/;
            open my $gff3, '>', $gff3_out_file or die "$! opening gff3 in error workaround";
            print $gff3 <<EOF;
##gff-version 3
# no results.  genomethreader produced invalid output XML.
EOF
            open my $out, '>', $outfile or die "$_ touching outfile in error workaround";
        }
    } else {
        warn "look at me, I'm faking running '$gth_exec'\n";
        `touch $game_xml_file $gff3_out_file $outfile`;
    }

    return ($game_xml_file, $gff3_out_file, $outfile);
}

sub _parse_mode {
  'both_merged';
}

sub _feature_id {
  my ($self,$feat,$parent_ID)  = @_;
  if($feat->type->name eq 'mRNA') {
    "${parent_ID}_AGS"
  } elsif ( $feat->type->name eq 'match') {
    #get the target name of the first subfeature's target
    my ($target_id) = (($feat->get_SeqFeatures)[0]->get_Annotations('Target'))[0]->target_id;
    $target_id.'_alignment'
  } elsif ( $feat->type->name eq 'region') {
    'PGL'
  } else {			#just name the feature for its source and type
    my $src = $feat->source;
    $src =~ s/GenomeThreader/GTH/; #< shorten the sources a little
    $src =~ s/(tom|pot)ato/$1/; #< shorten the sources a little
    $src.'_'.$feat->type->name;
  }
}

#figure out where our executable is
sub find_gth {
  my $aux = shift;

  return ($aux->{gth_binary} && -x $aux->{gth_binary})
      || (executable_is_in_path 'gth' && 'gth')
      || croak 'Cannot find GenomeThreader binary';
}

#check that we have everything we need to run
sub check_ok_to_run {
  my ($self,$submission,$aux_input) = @_;

  my @fileset = $self->_fileset($aux_input,$submission);

  croak "Specified gth_sgne/u_seq_file '$fileset[0]' could not be found or was not readable"
    unless $fileset[0] && -r $fileset[0];

  croak "Could not find gth executable.  Do you need to set the 'gth_binary' analysis option?"
    unless find_gth($aux_input);

  return 1;
}


###
1;#do not remove
###
