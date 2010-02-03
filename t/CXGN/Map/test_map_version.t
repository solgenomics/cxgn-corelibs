#!/usr/bin/perl
use strict;
use CXGN::Map::Version;
use CXGN::DB::Connection;
use CXGN::DB::InsertDBH;
use Data::Dumper;
use Test::More 'no_plan';
use Test::Exception;
CXGN::DB::Connection->verbose(0);
my $dbh=CXGN::DB::InsertDBH::connect({dbhost=>'scopolamine',dbname=>'sandbox',dbschema=>'sgn'});
eval
{
    my $new_map_version=CXGN::Map::Version->new($dbh,{map_id=>9});
    print $new_map_version->as_string();
    my $map_version_id=$new_map_version->insert_into_database();
    ok($map_version_id,'Created a new map version');
    print $new_map_version->as_string();
    print"---------------------------------------\n";
    $new_map_version=CXGN::Map::Version->new($dbh,{map_version_id=>36});
    print $new_map_version->as_string();
};
ok(!$@);
$dbh->rollback();
