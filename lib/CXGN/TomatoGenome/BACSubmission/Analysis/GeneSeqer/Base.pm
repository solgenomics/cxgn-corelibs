package CXGN::TomatoGenome::BACSubmission::Analysis::GeneSeqer::Base;
use base qw/CXGN::TomatoGenome::BACSubmission::Analysis/;
use Carp;
use English;
use File::Spec;
use File::Temp;

use CXGN::Tools::File qw/ executable_is_in_path file_contents /;
use CXGN::Annotation::GAMEXML::FromFile qw/geneseqer_to_game_xml/;
use CXGN::Annotation::GAMEXML::Combine qw/combine_game_xml_files/;

sub list_params {
  return ( geneseqer_binary  => '(optional) path to the GeneSeqer executable',
	   geneseqer_est_seq_file => <<EOD,
path to the file containing EST sequences in FASTA format that we should
annotate this BAC submission against
EOD
	   geneseqer_ug_seq_file => <<EOD,
path to the file containing unigene sequences in FASTA format that we should
annotate this BAC submission against
EOD
	 );
}

#check that we have everything we need to run
sub check_ok_to_run {
  my $self = shift;
  my $submission = shift;
  my $aux_input = shift; #hash ref of auxiliary inputs

  my @fileset = $self->_fileset($aux_input,$submission);

  croak "Specified geneseqer_est/ug_seq_file '$fileset[0]' could not be found or was not readable"
    unless $fileset[0] && -r $fileset[0];

  croak "Could not find GeneSeqer executable.  Do you need to set 'geneseqer_binary' analysis option?"
    unless find_geneseqer($aux_input);

  return 1;
}

sub _fileset {
  confess 'abstract, not implemented!';
}

#figure out where our geneseqer executable is
sub find_geneseqer {
  my $aux = shift;

  return ($aux->{geneseqer_binary} && -x $aux->{geneseqer_binary})
    || (executable_is_in_path 'GeneSeqer' && 'GeneSeqer')
    || croak 'Cannot find GeneSeqer binary';
}

#run geneseqer analysis
sub run {
  my $self = shift;
  my $submission = shift; #BACSubmission object
  my $aux_inputs = shift; #hash ref of auxiliary inputs

  #decide all the places where our various files are or should go
  my $gs_exec              = find_geneseqer($aux_inputs);
  my $vector_screened_seqs = $submission->vector_screened_sequences_file;

  my ($ests_file,$gs_est_outfile,$gs_est_errfile,$geneseqer_game_xml_file,$gs_gff3_out_file) =
    $self->_fileset($aux_inputs,$submission);

  my @gs_options = ( #command-line options for geneseqer
		    -s => 'Arabidopsis',
		    -m => 50000,
		    -x => 16,
		    -y => 30,
		    -z => 50,
		    -L => $vector_screened_seqs,
		   );
  unless($ENV{CXGNBACSUBMISSIONFAKEANNOT}) {
    my $gs_est_job = CXGN::Tools::Run->run( $gs_exec,
					    @gs_options,
					    -E => $ests_file,
					    { out_file => $gs_est_outfile,
					      err_file    => $gs_est_errfile,
					    }
					  );

    #convert the geneseqer output to gamexml
    if($submission->is_finished) {
      geneseqer_to_game_xml( $vector_screened_seqs, $gs_est_outfile, $geneseqer_game_xml_file );
    }
    else {
      $submission->_write_unfinished_bac_xml_stub($geneseqer_game_xml_file);
    }

    #convert the geneseqer output to gff3

    my $gs_in = Bio::FeatureIO->new( -format => 'geneseqer', -file => $gs_est_outfile, -mode => 'both_merged' );
    my $gff3_out = $submission->_open_gff3_out($gs_gff3_out_file);
    while ( my $f = $gs_in->next_feature ) {

      #set each feature's source to the name of the geneseqer subclass that's running this
      $self->_recursive_source($f,$self->analysis_name);

      #make some ID and Parent tags in the subfeatures
      $self->_make_gff3_id_and_parent($f);
      $gff3_out->write_feature($f);
    }
  } else {
    warn "look at me, I'm faking running '$gs_exec ".join(' ',@gs_options)."'\n";
    `touch $geneseqer_game_xml_file $gs_gff3_out_file $gs_est_outfile`;
  }

  return ($geneseqer_game_xml_file, $gs_gff3_out_file, $gs_est_outfile);
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
    $feat->source.'_'.$feat->type->name;
  }
}


1;
