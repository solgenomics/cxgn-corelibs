=head2 GeneSeqer_SGN_E_tomato

  Secondary input parameters:
    geneseqer_binary       - (optional) path to the GeneSeqer executable
    geneseqer_est_seq_file - path to the file containing EST sequences in FASTA
                             format that we should annotate this BAC submission
                             against

=cut

package CXGN::TomatoGenome::BACSubmission::Analysis::GeneSeqer::SGN_E_tomato;
use base 'CXGN::TomatoGenome::BACSubmission::Analysis::GeneSeqer::Base';
__PACKAGE__->run_for_new_submission(0);
sub _fileset {
  my ($self,$aux_inputs,$submission) = @_;

  return ($aux_inputs->{geneseqer_est_seq_file},
	  (map {$self->analysis_generated_file($submission,$_)} qw/out err game_xml gff3/),
	 );
}


1;

