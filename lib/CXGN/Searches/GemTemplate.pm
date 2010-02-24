package CXGN::Searches::GemTemplate;

use strict;
use warnings;
use English;
use Carp;

use CXGN::Tools::Class qw/parricide/;

use CXGN::Searches::GemTemplate::Query;
use CXGN::Searches::GemTemplate::Result;

use base qw/CXGN::Search::DBI::Simple CXGN::Search::WWWSearch/;

=head1 NAME

  CXGN::Searches::GemTemplate - a CXGN Search object - takes
     L<CXGN::Searches::GemTemplate::Query> objects and returns
     L<CXGN::Searches::GemTemplate::Result> objects.

=cut

our $VERSION = '0.01';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

=head1 SOME SCRIPTS THAT USE THIS

coming soon

=cut

=head1 AUTHOR(S)

 Aureliano Bombarely
 (ab782#cornell.edu)

=cut

__PACKAGE__->creates_result('CXGN::Searches::GemTemplate::Result');
__PACKAGE__->uses_query('CXGN::Searches::GemTemplate::Query');

sub DESTROY {
  my $this = shift;
  our @ISA;
  return parricide($this,@ISA);
}


###
1;#
###
