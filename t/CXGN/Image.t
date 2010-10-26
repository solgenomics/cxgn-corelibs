
use strict;
use warnings;

use File::Basename;
use Test::More tests=> 3 * 11;
use CXGN::Image;
use CXGN::DB::Connection;

my $dbh = CXGN::DB::Connection->new();

my $image_dir = '/tmp/test_images';
mkdir ($image_dir);

my @image_ids = (); #keep track of image ids created to remove them later



foreach my $image_file ('t/CXGN/data/tv_test_1.png', 't/CXGN/data/tv_test_1.JPG', 't/CXGN/data/test.pdf') { 
    my ($filename, $dir, $ext) = File::Basename::fileparse($image_file, qr/\..*/);
    my $image = CXGN::Image->new(dbh=>$dbh, image_id=>undef, image_dir=>$image_dir);
    
    #diag("processing image");
    $image->process_image($image_file);
    
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
    
    is(scalar(split '/', $image->image_subpath()), 16, "image path length check");
    
    $image->set_description("Blablabla");
    is($image->get_description(), "Blablabla", "description test");
    
    is($image->get_original_filename(), $filename, 'original filename test');
    is($image->get_file_ext(), $ext, "file extension test");
    $image->set_name("foo");
    is($image->get_name(), "foo", "image name test");

    push @image_ids, $image->get_image_id();
    

}    
$dbh->commit();    

foreach my $id (@image_ids) { 
    my $image = CXGN::Image->new(dbh=>$dbh, image_id=>$id, image_dir=>$image_dir);
    $image->hard_delete(); ### only works with postgres user right now.
}

$dbh->disconnect();
    


