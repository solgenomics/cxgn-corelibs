package CXGN::Searches::Images;

use strict;
use warnings;
use English;
use Carp;

use CXGN::Tools::Class qw/parricide/;

use CXGN::Searches::Images::Query;
use CXGN::Searches::Images::Result;

use base qw/CXGN::Search::DBI::Simple CXGN::Search::WWWSearch/;

=head1 NAME

  CXGN::Searches::Images - a CXGN Search object - takes
     L<CXGN::Searches::Images::Query> objects and returns
     L<CXGN::Searches::Images::Result> objects.

=head1 SYNOPSIS

coming soon

=head1 BASE CLASS(ES)

L<CXGN::Search::DBI::CDBI>, L<CXGN::Search::WWWSearch>

=head1 SOME SCRIPTS THAT USE THIS

coming soon

=cut

=head1 AUTHOR(S)

    Jessica Reuter

=cut

__PACKAGE__->creates_result('CXGN::Searches::Images::Result');
__PACKAGE__->uses_query('CXGN::Searches::Images::Query');

sub DESTROY {
  my $this = shift;
  our @ISA;
  return parricide($this,@ISA);
}

###
1;
###
