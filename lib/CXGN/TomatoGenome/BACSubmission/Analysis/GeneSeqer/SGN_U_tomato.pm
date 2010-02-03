=head2 GeneSeqer::SGN_U_tomato

  Secondary input parameters:
    geneseqer_binary       - (optional) path to the GeneSeqer executable
    geneseqer_ug_seq_file  - path to the file containing unigene sequences in FASTA
                             format that we should annotate this BAC submission
                             against

=cut

package CXGN::TomatoGenome::BACSubmission::Analysis::GeneSeqer::SGN_U_tomato;
use base 'CXGN::TomatoGenome::BACSubmission::Analysis::GeneSeqer::Base';
__PACKAGE__->run_for_new_submission(0); #this is kind of obsolete, so don't run it by default
sub _fileset {
  my ($self,$aux_inputs,$submission) = @_;
  return ($aux_inputs->{geneseqer_ug_seq_file},
	  (map {$self->analysis_generated_file($submission,$_)} qw/out err game_xml gff3/),
	 );
}


1;

