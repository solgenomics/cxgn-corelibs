#!/usr/bin/env perl
use strict;
use warnings;

use CXGN::DB::Connection;
CXGN::DB::Connection->verbose(0); #get rid of warnings

use CXGN::Unigene::Search;

use Test::More tests => 5;

my $search = CXGN::Unigene::Search->new;
isa_ok($search,'CXGN::Unigene::Search','constructor');

my $query = $search->new_query;
isa_ok($query,'CXGN::Search::QueryI','new query constructor');

$query->unigene_id('=24234');
my $result = $search->do_search($query);
isa_ok($result,'CXGN::Search::ResultI','search returns result object');
is($result->total_results,1,'search should return 1 result');

my $ug = $result->next_result;
is($ug->unigene_id,24234,'returned obj has correct id');


