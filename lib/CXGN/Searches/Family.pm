package CXGN::Searches::Family;

use strict;
use warnings;

use CXGN::Tools::Class qw/parricide/;
use CXGN::Searches::Family::Query;
use CXGN::Searches::Family::Result;

use base qw/CXGN::Search::DBI::Simple CXGN::Search::WWWSearch/;

__PACKAGE__->creates_result('CXGN::Searches::Family::Result');
__PACKAGE__->uses_query('CXGN::Searches::Family::Query');

sub DESTROY {
	my $self = shift;
	our @ISA;
	return parricide($self, @ISA);
}

1;
