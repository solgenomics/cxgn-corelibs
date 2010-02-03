package CXGN::Searches::Library;

use strict;
use warnings;
use English;
use Carp;

use CXGN::Tools::Class qw/parricide/;

use CXGN::Searches::Library::Query;
use CXGN::Searches::Library::Result;

use base qw/CXGN::Search::DBI::Simple CXGN::Search::WWWSearch/;

=head1 NAME

  CXGN::Searches::Library - a CXGN Search object - takes
     L<CXGN::Searches::Library::Query> objects and returns
     L<CXGN::Searches::Library::Result> objects.

=head1 SYNOPSIS

=head1 SOME SCRIPTS THAT USE THIS

coming soon

=cut

=head1 AUTHOR(S)

    Evan Herbst

=cut

__PACKAGE__->creates_result('CXGN::Searches::Library::Result');
__PACKAGE__->uses_query('CXGN::Searches::Library::Query');

sub DESTROY {
  my $this = shift;
  our @ISA;
  return parricide($this,@ISA);
}

###
1;
###
