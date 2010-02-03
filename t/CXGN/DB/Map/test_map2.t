use strict;

#use lib "../Map.pm";
use CXGN::DB::Map;


my $map = CXGN::DB::Map->retrieve(10);

print "Map ID: ".($map->get("map_id"))."\n";
print "Nr Chr: ".($map->get("deprecated_by"))."\n";
