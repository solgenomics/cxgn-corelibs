#!/usr/bin/perl -w

use strict;

use GD;
use Test::More tests => 7;
use CXGN::Tools::WebImageCache;

my $CACHE_EXPIRY = 5; # 5 seconds validity

my $cache = CXGN::Tools::WebImageCache->new();
$cache->set_key("abc");
$cache->set_expiration_time($CACHE_EXPIRY);
$cache->set_temp_dir("cview");
$cache->set_basedir("/tmp"); # would get this from VHost...
$cache->set_map_name("map1"); 

my $image_data;
my $image_map_data;

is($cache->is_valid(), 0, "initial cache validity check");

if (! $cache->is_valid()) {

    # generate the image and associated image map.
    # ...
    my $image = GD::Image->new(500, 500);
    $image->line(100, 100, 400, 400, $image->colorAllocate(0, 0, 0));
    
    $image_data = $image->png();
    $image_data =~ s/\n//g;
    $image_map_data = 
	qq { <map name="mapmap" id="mapmap"><area shape="rect" coords="780,-6,810,7" href="/search/markers/markerinfo.pl?marker_id=1284" alt="" /><area shape="rect" coords="780,-6,810,7" href="/search/markers/markerinfo.pl?marker_id=166" alt="" /><area shape="rect" coords="780,-6,810,7" href="/search/markers/markerinfo.pl?marker_id=166" alt="" /></map>};
    
    #$image_map_data = $map_image->get_image_map("map1");
    $cache->set_image_data( $image_data );
    $cache->set_image_map_data($image_map_data);
}

is($cache->is_valid(), 1, "is cache valid test");
is($cache->get_image_data(), $image_data, "image data test");
is($cache->get_image_map_data(), $image_map_data, "image map data test");
my $image_name = $cache->get_cache_name();
like($cache->get_image_html(), qr/$image_name/, "file name test");

# let the cache expire...
#
sleep($CACHE_EXPIRY + 2);

is($cache->is_valid(), 0, "expired cache test");

# clean up the cache files
#

END { is($cache->destroy(), 2, "cache destruction test"); }
