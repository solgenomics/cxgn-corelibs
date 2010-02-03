
use strict;
use Test::More qw / no_plan /;
use CXGN::Map;

use CXGN::DB::Connection;

my $db = CXGN::DB::Connection->new();
#my $db = CXGN::DB::InsertDBH::connect({
#    dbname => 'sandbox',
#    dbhost => 'scopolamine',
#    dbschema => 'sgn',
#    dbargs => {AutoCommit => 0,
#	       RaiseError => 1}});

my $map = CXGN::Map->new($db, { map_id => 9 } );

foreach my $lg ($map->get_chr_names()) { 
    my ($north, $south, $center) = $map -> get_centromere($lg);
#    print STDERR "$lg\t$north\t$south\t$center\n";
    if ($lg ne "11") { 
	isnt ($north, undef, "testing centromere for chromosome $lg on map without centromeres...\n");
    }
}

my $map2 = CXGN::Map->new($db, {map_id=>5});

foreach my $lg ($map2->get_chr_names()) { 
    my ($north, $south, $center) = $map2 -> get_centromere($lg);
 #   print STDERR "$lg\t$north\t$south\t$center\n";
    is ($north, undef, "testing centromere for chromosome $lg on map without centromeres...\n");
}
