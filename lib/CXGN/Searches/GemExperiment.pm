package CXGN::Searches::GemExperiment;

use strict;
use warnings;
use English;
use Carp;

use CXGN::Tools::Class qw/parricide/;

use CXGN::Searches::GemExperiment::Query;
use CXGN::Searches::GemExperiment::Result;

use base qw/CXGN::Search::DBI::Simple CXGN::Search::WWWSearch/;

=head1 NAME

  CXGN::Searches::GemExperiment - a CXGN Search object - takes
     L<CXGN::Searches::GemExperiment::Query> objects and returns
     L<CXGN::Searches::GemExperiment::Result> objects.


=cut

our $VERSION = '0.01';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

coming soon

=cut

=head1 AUTHOR(S)

 Aureliano Bombarely
 (ab782@cornell.edu)

=cut

__PACKAGE__->creates_result('CXGN::Searches::GemExperiment::Result');
__PACKAGE__->uses_query('CXGN::Searches::GemExperiment::Query');

sub DESTROY {
  my $this = shift;
  our @ISA;
  return parricide($this,@ISA);
}


###
1;#
###
