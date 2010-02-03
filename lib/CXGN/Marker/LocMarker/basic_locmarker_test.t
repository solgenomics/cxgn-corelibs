#!/usr/bin/perl
use strict;
use Test::More 'no_plan';
use CXGN::DB::Connection;
use CXGN::Marker::LocMarker;
use CXGN::Marker::Search;
# use Test::Pod; # should test the pod eventually

my $dbh = CXGN::DB::Connection->new({
    dbhost => 'scopolamine',
    dbname => 'sandbox',
    dbbranch => 'devel',
    });

my $msearch = CXGN::Marker::Search->new($dbh);
$msearch->must_be_mapped();
$msearch->random();
$msearch->perform_search();
my ($loc) = $msearch->fetch_location_markers();

isa_ok($loc, 'CXGN::Marker::LocMarker');
my $chr = $loc->chr();
my $pos = $loc->position();
my $sub = $loc->subscript();
my $conf = $loc->confidence();
my $mv = $loc->map_version();
ok($chr > 0);
ok($pos+0 eq $pos);
ok($conf+0 eq $conf);
ok($mv > 0);

















