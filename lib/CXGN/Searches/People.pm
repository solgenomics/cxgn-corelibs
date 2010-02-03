package CXGN::Searches::People;

use strict;
use warnings;
use English;
use Carp;

use CXGN::Tools::Class qw/parricide/;

use CXGN::Searches::People::Query;
use CXGN::Searches::People::Result;

use base qw/CXGN::Search::DBI::Simple CXGN::Search::WWWSearch/;

=head1 NAME

  CXGN::Searches::People - a CXGN Search object - takes
     L<CXGN::Searches::People::Query> objects and returns
     L<CXGN::Searches::People::Result> objects.

=head1 SYNOPSIS

coming soon

=head1 BASE CLASS(ES)

L<CXGN::Search::DBI::CDBI>, L<CXGN::Search::WWWSearch>

=head1 SOME SCRIPTS THAT USE THIS

coming soon

=cut

=head1 AUTHOR(S)

    Evan Herbst

=cut

__PACKAGE__->creates_result('CXGN::Searches::People::Result');
__PACKAGE__->uses_query('CXGN::Searches::People::Query');

sub DESTROY {
  my $this = shift;
  our @ISA;
  return parricide($this,@ISA);
}

###
1;
###
