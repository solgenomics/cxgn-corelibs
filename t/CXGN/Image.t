use strict;
use warnings;

use File::Basename;
use File::Temp;

use Test::More tests=> 3 * 11;

use CXGN::Image;
use CXGN::DB::Connection;

my $dbh = CXGN::DB::Connection->new; #< note that this connection has autocommit off

my $image_dir = File::Temp->newdir;

# keep track of image ids created to remove them later
my @image_ids;

foreach my $image_file ('t/CXGN/data/tv_test_1.png', 't/CXGN/data/tv_test_1.JPG', 't/CXGN/data/test.pdf') {
    my ($filename, $dir, $ext) = File::Basename::fileparse($image_file, qr/\..*/);
    my $image = CXGN::Image->new(dbh=>$dbh, image_id=>undef, image_dir=>$image_dir);

    $image->process_image($image_file);

    my $md5sum = $image->get_md5sum();

    my $image_full_dir = $image->get_image_dir()."/".$image->image_subpath();
    ok(-e $image_full_dir, "image path test");
    ok(-e $image->get_filename('thumbnail'), "thumbnail test");
    ok(-e $image->get_filename('small'), "small test");
    ok(-e $image->get_filename('medium'), "medium test");
    ok(-e $image->get_filename('large'), "large test");

    is(length($md5sum), 32, "md5sum length check");

    like( $image->image_subpath,
          qr! ( [0-9A-Fa-f]{2} / ){4}  [0-9A-Fa-f]{16} !x,
          'image subpath looks right',
         );

    $image->set_description("Blablabla");
    is($image->get_description(), "Blablabla", "description test");

    is($image->get_original_filename(), $filename, 'original filename test');
    is($image->get_file_ext(), $ext, "file extension test");
    $image->set_name("foo");
    is($image->get_name(), "foo", "image name test");

    push @image_ids, $image->get_image_id();
}

foreach my $id (@image_ids) {
    my $image = CXGN::Image->new( dbh => $dbh, image_id => $id, image_dir => $image_dir );
    $image->hard_delete(); ### only works with postgres user right now.
}

$dbh->commit();
$dbh->disconnect();
