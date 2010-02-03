
=head2 BLAST::E_coli_K12

  BLAST versus E. coli genome (genbank: NC_000913.2)

  Secondary input parameters:
    blastall_binary   - (optional) full path to blastall executable
    e_coli_genome_blast_db - (optional) file_base of the L<CXGN::BlastDB> to use

=cut

package CXGN::TomatoGenome::BACSubmission::Analysis::BLAST::E_coli_K12;
use base 'CXGN::TomatoGenome::BACSubmission::Analysis::BLAST::Base';

__PACKAGE__->run_for_new_submission(1);
sub list_params {
  return ( blastall_binary => 'optional full path to blastall executable',
	   e_coli_genome_blast_db => 'optional file_base of the CXGN::BlastDB E. coli genome blast database to use',
	 );
}
sub _fileset {
  my ($self,$aux_inputs) = @_;
  return ($aux_inputs->{e_coli_genome_blast_db} || 'E.coli_K12/Ecoli_genome');
}

sub _blastparams {
  -e => '1e-20', -p => 'blastn'
}

sub _use_line {
  my ($self,$line) = @_;
  my ($qname,$hname, $percent_id, $hsp_len, $mismatches,$gapsm,
      $qstart,$qend,$hstart,$hend,$evalue,$bits) = split /\s+/,$line;
  return $percent_id > 90 && $hsp_len >= 300;
}

1;
