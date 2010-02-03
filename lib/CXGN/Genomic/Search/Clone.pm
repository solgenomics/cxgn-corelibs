package CXGN::Genomic::Search::Clone;
use strict;
use warnings;
use English;
use Carp;

use CXGN::DB::Connection;
use CXGN::Genomic::Clone;

use CXGN::Tools::Class qw/parricide/;

use CXGN::Genomic::Search::Clone::Query;
use CXGN::Genomic::Search::Clone::Result;

use CXGN::CDBI::SGN::Unigene;

use base qw/CXGN::Search::DBI::CDBI CXGN::Search::WWWSearch/;

=head1 NAME

  CXGN::Genomic::Search::Clone - a CXGN Search object - takes
     L<CXGN::Genomic::Search::Clone::Query> objects and returns
     L<CXGN::Genomic::Search::Clone::Result> objects.

=head1 SYNOPSIS

coming soon

=head1 BASE CLASS(ES)

L<CXGN::Search::DBI::CDBI>

=head1 SOME SCRIPTS THAT USE THIS

coming soon

=head1 ASSOCIATED CLASSES

  Result: L<CXGN::Genomic::Search::Clone::Result>
  Query:  L<CXGN::Genomic::Search::Clone::Query>
  Class::DBI return: L<CXGN::CDBI::SGN::Unigene>

=cut

__PACKAGE__->creates_result('CXGN::Genomic::Search::Clone::Result');

__PACKAGE__->uses_query('CXGN::Genomic::Search::Clone::Query');

__PACKAGE__->transforms_rows('CXGN::Genomic::Clone');


sub DESTROY {
  my $this = shift;
  our @ISA;
  return parricide($this,@ISA);
}

=head1 AUTHOR(S)

    Robert Buels

=cut


###
1;#do not remove
###
