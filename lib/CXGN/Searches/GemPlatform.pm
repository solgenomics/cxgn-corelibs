package CXGN::Searches::GemPlatform;

use strict;
use warnings;
use English;
use Carp;

use CXGN::Tools::Class qw/parricide/;

use CXGN::Searches::GemPlatform::Query;
use CXGN::Searches::GemPlatform::Result;

use base qw/CXGN::Search::DBI::Simple CXGN::Search::WWWSearch/;

=head1 NAME

  CXGN::Searches::GemPlatform - a CXGN Search object - takes
     L<CXGN::Searches::GemPlatform::Query> objects and returns
     L<CXGN::Searches::GemPlatform::Result> objects.

=head1 SYNOPSIS

=head1 SOME SCRIPTS THAT USE THIS

coming soon

=cut

=head1 AUTHOR(S)

    Aureliano Bombarely

=cut

__PACKAGE__->creates_result('CXGN::Searches::GemPlatform::Result');
__PACKAGE__->uses_query('CXGN::Searches::GemPlatform::Query');

sub DESTROY {
  my $this = shift;
  our @ISA;
  return parricide($this,@ISA);
}

###
1;
###
