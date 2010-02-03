
=head2 AUGUSTUS::ab_initio

  Secondary input parameters:
    blat_exec       - path to blat executable, defaults to looking for it in path
    augustus_exec   - path to augustus executable, defaults to looking for it in path
    blat2hints_exec - path to blat2hints.pl script, defaults to /usr/share/augustus/scripts/blat2hints.pl

=cut

package CXGN::TomatoGenome::BACSubmission::Analysis::AUGUSTUS::ab_initio;
use base qw/CXGN::TomatoGenome::BACSubmission::Analysis::AUGUSTUS::Base/;

use CXGN::Tools::Wget qw/wget_filter/;

__PACKAGE__->run_for_new_submission(1);

sub _get_cdna_seqs_file { } #< return no cdnas, go completely ab initio


1;
