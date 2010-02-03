
=head2 BLAST::nr

  BLAST versus Genbank NR

  Secondary input parameters:
    blastall_binary   - (optional) full path to blastall executable
    nr_blast_db - (optional) file_base of the L<CXGN::BlastDB> to use

  NOTE: This analysis takes 4 hours on a 3GHz opteron machine, so
  it is not automatically run for new bacs

=cut

package CXGN::TomatoGenome::BACSubmission::Analysis::BLAST::nr;
use base 'CXGN::TomatoGenome::BACSubmission::Analysis::BLAST::Base';

#it takes 4 hours on a 3Ghz opteron to blastx a bac against
#nr, so don't run this for every new submission
__PACKAGE__->run_for_new_submission(0);
sub list_params {
  return ( blastall_binary => 'optional full path to blastall executable',
	   nr_blast_db => 'optional file_base of the CXGN::BlastDB genbank nr blast database to use',
	 );
}
sub _fileset {
  my ($self,$aux_inputs) = @_;
  return ($aux_inputs->{nr_blast_db} || 'genbank/nr');
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

