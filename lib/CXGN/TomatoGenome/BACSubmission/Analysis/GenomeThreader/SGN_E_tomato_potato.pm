=head2 GenomeThreader::SGN_E_tomato_potato

  Secondary input parameters:
    gth_sgne_tomato_potato_seq_file - library of SGN EST sequences to use
    gth_binary   - (optional) full path to gth executable

=cut

package CXGN::TomatoGenome::BACSubmission::Analysis::GenomeThreader::SGN_E_tomato_potato;
use base 'CXGN::TomatoGenome::BACSubmission::Analysis::GenomeThreader::Base';
use CXGN::TomatoGenome::BACPublish qw/resource_file/;

__PACKAGE__->run_for_new_submission(1); #set this to be run on new BAC submissions

sub list_params {
  return ( gth_sgne_tomato_potato_seq_file => '(optional) full path to fasta file of SGN ESTs to use',
	   gth_binary   => '(optional) full path to gth executable',
	 );
}

sub _fileset {
  my ($self,$aux_inputs,$submission) = @_;
  return ($aux_inputs->{gth_sgne_tomato_potato_seq_file} || resource_file('sgn_ests_tomato_potato'),
	  (map { $self->analysis_generated_file($submission,$_) } qw /out err game_xml gff3/),
	 );
}
sub _dbname {
  return 'SGN Combined Tomato and Potato ESTs';
}


1;
