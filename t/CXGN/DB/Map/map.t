use strict;
use Test::More tests=>5;

BEGIN {
    diag("Checking if we can load the module...");
    use_ok ( "CXGN::DB::Map" );
}
diag("Testing CXGN::DB::Map");

my $map = CXGN::DB::Map->retrieve(13);

is ( $map->get("map_id"), 13, "map_id is 13");
isa_ok ($map, "CXGN::DB::Map", "$map");

is ( $map->get("number_chromosomes"), 12, "chromosome number");
is ( $map->get("short_name"), "Tomato FISH map", "it's the FISH map!");
