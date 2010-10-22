
use strict;
use warnings;

use Test::More tests=>8;
use CXGN::Image;
use CXGN::DB::Connection;

my $dbh = CXGN::DB::Connection->new();

my $image = CXGN::Image->new(dbh=>$dbh, image_id=>undef, image_dir=>'/tmp');

#diag("processing image");
$image->process_image('Image/tv_test_1.png');

#diag("calculating md5sum");

my $md5sum = $image->get_md5sum();

#diag("checking files");
my $image_full_dir = $image->get_image_dir()."/".$image->image_subpath();
ok(-e $image_full_dir, "image path test");
ok(-e $image->get_filename('thumbnail'), "thumbnail test");
ok(-e $image->get_filename('small'), "small test");
ok(-e $image->get_filename('medium'), "medium test");
ok(-e $image->get_filename('large'), "large test");

is(length($md5sum), 32, "md5sum length check");

is(scalar(split /\//, $image->image_subpath()), 16, "image path length check");
#diag($image->get_md5sum());
#diag($image->image_subpath());
$dbh->disconnect();

$image->set_description("Blablabla");
is($image->get_description(), "Blablabla", "description test");

$image->set_name("foo");
is($image->get_name(), "foo", "image name test");
