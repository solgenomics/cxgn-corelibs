use strict;
use warnings;
use Test::More;
use CXGN::Map;
use CXGN::DB::Connection;

my $db   = CXGN::DB::Connection->new();
my $map  = CXGN::Map->new($db, { map_id => 9 } );
my $map2 = CXGN::Map->new($db, { map_id  =>5 });

my $num_tests = $map->get_chr_names() + $map2->get_chr_names() - 1;
plan( tests => $num_tests );

for my $lg ($map->get_chr_names()) {
    my ($north, $south, $center) = $map->get_centromere($lg);
    if ($lg ne "11") {
        isnt ($north, undef, "testing centromere for chromosome $lg on map without centromeres");
    }
}

for my $lg ($map2->get_chr_names()) {
    my ($north, $south, $center) = $map2->get_centromere($lg);
    is ($north, undef, "testing centromere for chromosome $lg on map without centromeres");
}

$db->disconnect;
done_testing();
