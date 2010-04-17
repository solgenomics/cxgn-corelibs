#!/usr/bin/perl
use strict;
use CXGN::Map::Version;
use CXGN::DB::Connection;
use Test::More tests => 3;
my $dbh=CXGN::DB::Connection->new;

my $new_map_version = CXGN::Map::Version->new($dbh,{map_id=>9});
ok($new_map_version,'Created a new map version object with map_id');

my $map_version_id = $new_map_version->insert_into_database();
ok($map_version_id,'Inserted a new map version id into the db');

$new_map_version = CXGN::Map::Version->new($dbh,{map_version_id=>36});
ok($new_map_version,'Created a new map version object with map_version_id');

$dbh->rollback();
