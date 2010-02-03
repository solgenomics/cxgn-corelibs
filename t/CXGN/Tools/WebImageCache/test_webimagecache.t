#!/usr/bin/perl -w

use Test::More;
use CXGN::Tools::WebImageCache;
use CXGN::Cview::MapImage;
use CXGN::Cview::Chromosome;

my $cache = CXGN::Tools::WebImageCache->new();
$cache->set_key("abc");
$cache->set_expiration_time(10); # seconds, this would be a day.
$cache->set_temp_dir("cview");
$cache->set_basedir("/data/local/website/sgn/documents/tempfiles/"); # would get this from VHost...
$cache->set_map_name("map1"); 
if (! $cache->is_valid()) {
    print STDERR "Regenerating the image...\n";
    # generate the image and associated image map.
    # ...
    my $map_image = CXGN::Cview::MapImage->new("", 200, 200);
    my $chr = CXGN::Cview::Chromosome->new(100, 10, 10);
    $chr->set_url("http://sgn.cornell.edu/");
    $map_image->add_chromosome($chr);

    my $image_data = $map_image->render_png_string();
    my $image_map_data = $map_image->get_image_map("map1");
    $cache->set_image_data( $image_data );
    $cache->set_image_map_data($image_map_data);
}
else { 
    print STDERR "Using the cached version...\n"; 
}
print $cache->get_image_html();
