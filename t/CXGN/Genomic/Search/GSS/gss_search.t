#!/usr/bin/perl
use strict;
use CXGN::Genomic;
use CXGN::Genomic::Search::GSS;

use CXGN::DB::Connection;
use Data::Dumper;

CXGN::DB::Connection->verbose(0);

use Test::More tests => 2;

#right now, it only tests the very basics

my $search = CXGN::Genomic::Search::GSS->new;
ok($search);

my $query = $search->new_query;
$query->seq('length(&t) > 300');
$query->orderby(gss_id => 'ASC');
$search->page_size(20);

my $result = $search->do_search($query);
$result->autopage($query,$search);

#manual query
my $dbconn = CXGN::DB::Connection->new;
my @ids1 = map {$_->[0]} @{$dbconn->selectall_arrayref(<<EOSQL)};
SELECT g.gss_id
FROM genomic.gss AS g
JOIN genomic.qc_report AS q
  USING(gss_id)
WHERE length(g.seq) > 300
ORDER BY g.gss_id
LIMIT 100
EOSQL

my $resultcount = 0;
my $good = 1;
while(my $g = $result->next_result and $resultcount<@ids1) {
  unless($g->gss_id == $ids1[$resultcount]) {
    $good = 0;
    print "Mismatch: ".$g->gss_id." is not ",$ids1[$resultcount],"\n";
    last;
  }
  $resultcount++;
}
#print "got ",scalar(@ids1)." ids, count is $resultcount\n";
ok($good && $resultcount == @ids1);



