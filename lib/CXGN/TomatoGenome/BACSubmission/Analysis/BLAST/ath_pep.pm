
=head2 BLAST::ath_pep

  BLAST versus TAIR Arabidopsis peptides.

  Secondary input parameters:
    blastall_binary   - (optional) full path to blastall executable
    ath_pep_blast_db - (optional) file_base of the L<CXGN::BlastDB> to use

=cut

package CXGN::TomatoGenome::BACSubmission::Analysis::BLAST::ath_pep;
use base 'CXGN::TomatoGenome::BACSubmission::Analysis::BLAST::Base';

__PACKAGE__->run_for_new_submission(1);
sub list_params {
  return ( blastall_binary => 'optional full path to blastall executable',
	   ath_pep_blast_db => 'optional file_base of the CXGN::BlastDB arabidopsis peptides blast database to use',
	 );
}
sub _fileset {
  my ($self,$aux_inputs) = @_;
  return ($aux_inputs->{ath_pep_blast_db} || 'ath1/ATH1_pep');
}

# sub _use_line {
#   my ($self,$line) = @_;
#   my ($qname,$hname, $percent_id, $hsp_len, $mismatches,$gapsm,
#       $qstart,$qend,$hstart,$hend,$evalue,$bits) = split /\s+/,$line;
#   return $percent_id > 98 && $mismatches < 10 && $gapsm <= 1;
# }
sub _blastparams {
  -e => '1e-20', -p => 'blastx'
}

1;

