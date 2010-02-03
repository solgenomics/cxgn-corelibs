=head2 RepeatMasker

  Secondary input parameters:
    repeatmasker_lib_file - library of repetitive sequences to use
    repeatmasker_binary   - (optional) full path to RepeatMasker executable script

=cut

package CXGN::TomatoGenome::BACSubmission::Analysis::RepeatMasker;
use base qw/CXGN::TomatoGenome::BACSubmission::Analysis/;
use Carp;
use English;
use File::Spec;
use File::Basename;

use POSIX;

use CXGN::Tools::File qw/ executable_is_in_path file_contents /;
use CXGN::Annotation::GAMEXML::FromFile qw/gff_to_game_xml/;
use CXGN::TomatoGenome::BACPublish qw/resource_file/;
use CXGN::Tools::Wget;

__PACKAGE__->run_for_new_submission(1); #set this to be run on new BAC submissions

sub list_params {
  return ( repeatmasker_lib_file => 'full path to fasta file of repeats to use',
	   repeatmasker_binary   => '(optional) full path to RepeatMasker executable',
	 );
}

sub run {
  my $self = shift;
  my $submission = shift; #BACSubmission object
  my $aux_inputs = shift; #hash ref of auxiliary inputs

  #find all the various files we need to run repeatmasker
  my $repeatmasker_bin     = find_repeatmasker($aux_inputs);
  my $repeat_lib_file      = $aux_inputs->{repeatmasker_lib_file} || resource_file('repeats_master');
  my $vector_screened_seqs = $submission->vector_screened_sequences_file;
  my ($outfile,$errfile,$gff3file,$gamefile) =
    map {$self->analysis_generated_file($submission,$_)} qw/out err gff3 game_xml/;
  my $repeatmasker_native  = "$vector_screened_seqs.out"; #and it always writes to this too
  my $repeatmasker_gff2  = "$vector_screened_seqs.out.gff"; #and it always writes to this too
  my $tempdir = $submission->_tempdir;
  -w $tempdir or confess "Cannot write to temp dir '$tempdir'";

  #run repeatmasker
  unless($ENV{CXGNBACSUBMISSIONFAKEANNOT}) {
    my $rm = CXGN::Tools::Run->run( $repeatmasker_bin,
				    '-q',
				    '-nolow',
				    '-gff',
				    -lib     => $repeat_lib_file,
				    -parallel => 2, #use 2 processors
				    $vector_screened_seqs,
				    { working_dir => $tempdir,
				      out_file    => $outfile,
				      err_file    => $errfile,
				    }
				  );

    #convert the repeatmasker to gff3
    do { my $fi = Bio::Tools::RepeatMasker->new( -file => $repeatmasker_native );
	 my $fo = $submission->_open_gff3_out($gff3file);
	 while (my $feature_pair = $fi->next_result() ) {
	   $feature_pair->primary_tag('nucleotide_motif');
	   my $old = $feature_pair->feature1;
	   my $f = Bio::SeqFeature::Annotated->new( -feature => $old );
	   my ($target_id) = ($f->get_Annotations('Target'))[0]->target_id;
	   $f->add_Annotation('ID',$self->_unique_bio_annotation_id("${target_id}_alignment"));
	   $fo->write_feature( $f );
	 }
       };

    #convert the GFF3 to GAME XML if this is a finished bac
    if( $submission->is_finished ) {
      gff_to_game_xml($vector_screened_seqs, $gff3file, $gamefile,
		      program_name   => 'RepeatMasker',
		      database_name  => $self->_dbname,
		      program_date   => asctime(gmtime).' GMT',
		      gff_version    => 3,
		     );
    }
    else {
      $submission->_write_unfinished_bac_xml_stub($gamefile);
    }
  } else {
    warn "look at me, I'm not really running RepeatMasker\n";
    `touch $gamefile $repeatmasker_native $gff3file $repeatmasker_gff2 $vector_screened_seqs.masked`;
  }

  #return the result files
  return ($gamefile, $gff3file, $repeatmasker_gff2, $repeatmasker_native, $submission->repeat_masked_sequences_file);
}
sub _dbname {
  'tomato repeats master'
}

#figure out where our geneseqer executable is
sub find_repeatmasker {
  my $aux = shift;

  return ($aux->{repeatmasker_binary} && -x $aux->{repeatmasker_binary})
      || (executable_is_in_path 'RepeatMasker' && 'RepeatMasker')
      || croak 'Cannot find RepeatMasker binary';
}

sub check_ok_to_run {
  my $self = shift;
  my $submission = shift; #BACSubmission object
  my $aux_inputs = shift; #hash ref of auxiliary inputs

  no warnings;

#   croak "Specified RepeatMasker library (repeatmasker_lib_file='$aux_inputs->{repeatmasker_lib_file}') could not be found or was not readable"
#     unless $aux_inputs->{repeatmasker_lib_file} && -r $aux_inputs->{repeatmasker_lib_file};

  croak "Could not find RepeatMasker executable.  Do you need to set the 'repeatmasker_binary' analysis option?"
    unless find_repeatmasker($aux_inputs);

  return 1;
}



###
1;#do not remove
###
