
=head2 BLAST::tomato_bacs

  BLAST versus the other submitted tomato bacs

  Secondary input parameters:
    blastall_binary   - (optional) full path to blastall executable
    tomato_bacs_blast_db - (optional) file_base of the L<CXGN::BlastDB> to use

=cut

package CXGN::TomatoGenome::BACSubmission::Analysis::BLAST::tomato_bacs;
use base 'CXGN::TomatoGenome::BACSubmission::Analysis::BLAST::Base';

use Carp;
use CXGN::Genomic::CloneIdentifiers qw/parse_clone_ident/;

__PACKAGE__->run_for_new_submission(1);
sub list_params {
  blastall_binary => 'optional full path to blastall executable',
  tomato_bacs_blast_db => 'optional file_base of the CXGN::BlastDB E. coli genome blast database to use'
}
sub _fileset {
  my ($self,$aux_inputs) = @_;
  return ($aux_inputs->{tomato_bacs_blast_db} || 'bacs/tomato_bacs');
}

sub _blastparams {
  -e => '1e-3', -p => 'blastn'
}

sub _target_name {
  my ($self,$tgt) = @_;
  return "clone-$tgt";
}

sub _use_line {
  my ($self,$line) = @_;
  my ($qname,$hname, $percent_id, $hsp_len, $mismatches,$gapsm,
      $qstart,$qend,$hstart,$hend,$evalue,$bits) = split /\s+/,$line;

  return unless $percent_id > 70 && $hsp_len >= 1000;

  #FIXME: this munges BAC names without using CXGN::Genomic::CloneIdentifiers
  my $hbac = parse_clone_ident($hname,'versioned_bac_seq')
    or confess "can't parse bac sequence identifier '$hname'";
  my $qbac = parse_clone_ident($qname,'versioned_bac_seq')
    or confess "can't parse bac sequence identifier '$qname'";

  foreach (qw/col row plate lib clonetype/) {
    if($qbac->{$_} ne $hbac->{$_}) {
#      warn "$qbac->{$_} eq $hbac->{$_}\n";
      return 1;
    }
  }

  return; #the bac idents must have been equal
}




1;


