package CXGN::Unigene::Search;

use CXGN::Unigene::Search::Query;
use CXGN::Unigene::Search::Result;

use CXGN::CDBI::SGN::Unigene;

use base qw/CXGN::Search::DBI::CDBI CXGN::Search::WWWSearch/;

__PACKAGE__->creates_result('CXGN::Unigene::Search::Result');

__PACKAGE__->uses_query('CXGN::Unigene::Search::Query');

__PACKAGE__->transforms_rows('CXGN::CDBI::SGN::Unigene');

###
1;#do not remove
###
