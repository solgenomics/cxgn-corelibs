=head2 GenomeThreader::SGN_markers

  Secondary input parameters:
    gth_sgn_marker_seqs - (optional) full path to fasta file of SGN marker sequences to use
    gth_binary   - (optional) full path to gth executable

=cut

package CXGN::TomatoGenome::BACSubmission::Analysis::GenomeThreader::SGN_markers;
use base 'CXGN::TomatoGenome::BACSubmission::Analysis::GenomeThreader::Base';
use CXGN::TomatoGenome::BACPublish qw/resource_file/;

__PACKAGE__->run_for_new_submission(1); #set this to be run on new BAC submissions

sub list_params {
  return ( gth_sgn_marker_seqs => '(optional) full path to fasta file of SGN marker sequences to use',
	   gth_binary   => '(optional) full path to gth executable',
	 );
}

sub _fileset {
  my ($self,$aux_inputs,$submission) = @_;
  return ($aux_inputs->{gth_sgn_marker_seqs} || resource_file('sgn_marker_seqs'),
	  (map { $self->analysis_generated_file($submission,$_) } qw /out err game_xml gff3/),
	 );
}
sub _dbname {
  return 'SGN marker sequences';
}
sub _parse_mode {
  'alignments_merged'
}


1;
