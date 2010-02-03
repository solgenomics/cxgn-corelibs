
=head2 BLAST::tomato_chloroplast

  BLAST versus tomato chloroplast genome (genbank: AM087200)

  Secondary input parameters:
    blastall_binary   - (optional) full path to blastall executable
    tomato_chloroplast_blast_db - (optional) file_base of the L<CXGN::BlastDB> to use

=cut

package CXGN::TomatoGenome::BACSubmission::Analysis::BLAST::tomato_chloroplast;
use base 'CXGN::TomatoGenome::BACSubmission::Analysis::BLAST::Base';

__PACKAGE__->run_for_new_submission(1);
sub list_params {
  blastall_binary => 'optional full path to blastall executable',
  tomato_chloroplast_blast_db => 'optional file_base of the CXGN::BlastDB E. coli genome blast database to use'
}
sub _fileset {
  my ($self,$aux_inputs) = @_;
  return ($aux_inputs->{tomato_chloroplast_blast_db} || 'screening/organelle/tomato_chloroplast');
}

sub _blastparams {
  -e => '1e-4', -p => 'blastn'
}

sub _use_line {
  my ($self,$line) = @_;
  my ($qname,$hname, $percent_id, $hsp_len, $mismatches,$gapsm,
      $qstart,$qend,$hstart,$hend,$evalue,$bits) = split /\s+/,$line;
  return $percent_id > 90 && $hsp_len >= 300;
}

1;

