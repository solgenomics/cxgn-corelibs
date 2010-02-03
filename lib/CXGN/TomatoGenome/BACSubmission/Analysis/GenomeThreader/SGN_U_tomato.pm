=head2 GenomeThreader_SGN_U_tomato

  Secondary input parameters:
    gth_sgnu_tomato_seqs_file - library of SGN unigene sequences to use
    gth_binary   - (optional) full path to gth executable

=cut

package CXGN::TomatoGenome::BACSubmission::Analysis::GenomeThreader::SGN_U_tomato;
use strict;
use warnings;
use base 'CXGN::TomatoGenome::BACSubmission::Analysis::GenomeThreader::Base';
use CXGN::TomatoGenome::BACPublish qw/resource_file/;

__PACKAGE__->run_for_new_submission(1); #set this to be run on new BAC submissions

sub list_params {
  return ( gth_sgnu_tomato_seq_file => '(optional) full path to fasta file of SGN unigenes to use',
	   gth_binary   => '(optional) full path to gth executable',
	 );
}

sub _fileset {
  my ($self,$aux_inputs,$submission) = @_;
  return ($aux_inputs->{gth_sgnu_tomato_seq_file} || resource_file('lycopersicum_combined_unigene_seqs'),
	  (map { $self->analysis_generated_file($submission,$_) } qw /out err game_xml gff3/),
	 );
}

sub _dbname {
  return 'SGN Tomato Unigenes';
}


1;
