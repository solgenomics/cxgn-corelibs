#!/usr/bin/perl
use strict;
use warnings;
use English;

use File::Temp qw/tempdir/;
use File::Find;
use File::Copy;
use File::Spec;

use Data::Dumper;

use Test::More tests => 91;
use Test::Exception;
use Test::Warn;

BEGIN {
  use_ok('CXGN::Publish', qw/publish link_or_print orig_basename mkdir_or_print parse_versioned_filepath publishing_history/ );
  use_ok('CXGN::Publish::VersionedFile');
}

use CXGN::Tools::File qw/file_contents/;

#make a temp dir to do our dirty business
our $tempdir = tempdir(CLEANUP => 1);

sub printfiles {
  find({ wanted => sub {
	   print;
	   print "\n";
	 },
	 no_chdir => 1,
       },
       "$tempdir/pub");
}
sub find_if_debugging {
  system("find $tempdir") if $ENV{CXGNPUBLISHDEBUG};
}

{
### first, test parse_versioned_filepath
    my %filepath_tests = ( '/tmp/myfile.v3.seq.foo' =>
                           { dir  => '/tmp',
                             name => 'myfile',
                             extension  => '.seq.foo',
                             basename => 'myfile.v3.seq.foo',
                             version  => 3,
                             obsolete_timestamp => undef,
                             fullpath => '/tmp/myfile.v3.seq.foo',
                             fullpath_unversioned => '/tmp/myfile.seq.foo',
                             dir_unversioned => '/tmp',
                             basename_unversioned => 'myfile.seq.foo',
                           },
                           './myfiles.v2.seq.20060203040506' =>
                           { dir  => '.',
                             name => 'myfiles',
                             extension  => '.seq',
                             basename => 'myfiles.v2.seq.20060203040506',
                             version => 2,
                             obsolete_timestamp => 20060203040506,
                             fullpath => './myfiles.v2.seq.20060203040506',
                             fullpath_unversioned => './myfiles.seq',
                             dir_unversioned => '.',
                             basename_unversioned => 'myfiles.seq',
                           },
                           './somefile.v234' =>
                           { dir  => '.',
                             name => 'somefile',
                             extension  => '',
                             basename => 'somefile.v234',
                             version => 234,
                             obsolete_timestamp => undef,
                             fullpath => './somefile.v234',
                             fullpath_unversioned => './somefile',
                             dir_unversioned => '.',
                             basename_unversioned => 'somefile',
                           },
                         );

    while (my ($filepath,$test) = each %filepath_tests) {
        my $parsed = parse_versioned_filepath($filepath);
        is_deeply( $parsed, $test,'parse_versioned_filepath works')
            or diag( "'$filepath' was parsed as:\n",
                     Dumper($parsed),
                     "but should have been parsed as:\n",
                     Dumper($test),
                   );
    }
}


#make a few empty files
system "touch $tempdir/foo.ish.bar $tempdir/bar.ish.foo $tempdir/file_with_no_ext";
mkdir "$tempdir/pub";

#publish them once and check they're there
publish(['cp',"$tempdir/foo.ish.bar","$tempdir/pub"],
	['cp',"$tempdir/bar.ish.foo","$tempdir/pub"],
	['cp',"$tempdir/file_with_no_ext","$tempdir/pub"],
       );
find_if_debugging();
ok(-f "$tempdir/pub/foo.v1.ish.bar", 'got first version file 1');
ok(-f "$tempdir/pub/bar.v1.ish.foo", 'got first version file 2');
ok(-f "$tempdir/pub/file_with_no_ext.v1", 'got first version file 3');
is(readlink("$tempdir/pub/curr/foo.ish.bar"), "../foo.v1.ish.bar", 'got curr link for first version file 1');
is(readlink("$tempdir/pub/curr/bar.ish.foo"), "../bar.v1.ish.foo", 'got curr link for first version file 2');
is(readlink("$tempdir/pub/curr/file_with_no_ext"), "../file_with_no_ext.v1", 'got curr link for first version file 2');
ok( -f "$tempdir/pub/curr/README.txt", 'curr links dir readme was made');

#test a versionedfile for this
{ my $vf = CXGN::Publish::VersionedFile->new("$tempdir/pub/foo.v1.ish.bar");
  is( $vf->current_version, 1, 'got correct current_version');
  is( $vf->current_file->stringify, "$tempdir/pub/foo.v1.ish.bar", 'got correct current_file');
  is_deeply( {$vf->previous_versions}, {}, 'got correct previous versions' );
}

#publish them again without changing them, and check that the versions didn't change
publish(['cp',"$tempdir/foo.ish.bar","$tempdir/pub"],
	['cp',"$tempdir/bar.ish.foo","$tempdir/pub"],
       );
find_if_debugging();
ok(! -f "$tempdir/pub/foo.v2.ish.bar", 'skipped unchanged file 1');
ok( -f "$tempdir/pub/foo.v1.ish.bar", 'previous version still there');
ok(! -f "$tempdir/pub/bar.v2.ish.foo", 'skipped unchanged file 2');
ok( -f "$tempdir/pub/bar.v1.ish.foo", 'previous version still there');
ok( ! -f "$tempdir/pub/old/README.txt", 'old dir readme has not yet been made');
is(readlink "$tempdir/pub/curr/foo.ish.bar", "../foo.v1.ish.bar", 'curr symlink still points 1');
is(readlink "$tempdir/pub/curr/bar.ish.foo", "../bar.v1.ish.foo", 'curr symlink still points 2');

#test a versionedfile for this
foreach my $f ( "$tempdir/pub/foo.v1.ish.bar",
                "$tempdir/pub/foo.ish.bar",
              ) {
    my $vf = CXGN::Publish::VersionedFile->new($f);
    is( $vf->current_version, 1, 'got correct current_version');
    is( $vf->current_file->stringify, "$tempdir/pub/foo.v1.ish.bar", 'got correct current_file');
    is_deeply( {$vf->previous_versions}, {}, 'got correct previous versions' );
}

change_files("$tempdir/foo.ish.bar","$tempdir/bar.ish.foo");
find_if_debugging();
publish(['cp',"$tempdir/foo.ish.bar","$tempdir/pub"],
	['cp',"$tempdir/bar.ish.foo","$tempdir/pub"],
       );
find_if_debugging();
ok(-f "$tempdir/pub/foo.v2.ish.bar", 'got second version file 1');
ok(-f "$tempdir/pub/bar.v2.ish.foo", 'got second version file 2');
is(readlink "$tempdir/pub/curr/foo.ish.bar", "../foo.v2.ish.bar", 'curr symlink points to new version 1');
is(readlink "$tempdir/pub/curr/bar.ish.foo", "../bar.v2.ish.foo", 'curr symlink points to new version 2');
ok(-f "$tempdir/pub/old/README.txt", 'old dir and README have been made');


#test a versionedfile for this
{ my $vf = CXGN::Publish::VersionedFile->new("$tempdir/pub/foo.v1.ish.bar");
  is( $vf->current_version, 2, 'got correct current_version');
  is( $vf->current_file->stringify, "$tempdir/pub/foo.v2.ish.bar", 'got correct current_file');
  my %pv = $vf->previous_versions;
  is( scalar(keys %pv), 1, 'got correct previous version count' );
  like( $pv{1}->stringify, qr|$tempdir/pub/old/foo\.v1\.ish\.bar\.\d+$|, 'got correct previous version file string' );
}

my @matches = glob("$tempdir/pub/old/foo.v1.ish.bar.*");
is(scalar(@matches),1,'correct number of archived file 1s');
@matches = glob("$tempdir/pub/old/bar.v1.ish.foo.*");
is(scalar(@matches),1,'correct number of archived file 2s');

change_files("$tempdir/foo.ish.bar");
publish(['cp',"$tempdir/foo.ish.bar","$tempdir/pub"],
	['cp',
	 sub{
	   is(shift,3,'got correct version number passed to subroutine ref');
	   "$tempdir/bar.ish.foo"
	 },
	 "$tempdir/pub/bar.ish.foo"
	],
       );
find_if_debugging();
ok(-f "$tempdir/pub/foo.v3.ish.bar", 'got third version file 1');
ok(-f "$tempdir/pub/bar.v3.ish.foo", 'got third version file 2');
is(readlink "$tempdir/pub/curr/foo.ish.bar", "../foo.v3.ish.bar", 'curr symlink points to new version 1');
is(readlink "$tempdir/pub/curr/bar.ish.foo", "../bar.v3.ish.foo", 'curr symlink points to new version 2');

@matches = glob("$tempdir/pub/old/foo.v*.ish.bar.*");
is(scalar(@matches),2,'correct number of archived file 1s');
@matches = glob("$tempdir/pub/old/bar.v*.ish.foo.*");
is(scalar(@matches),2,'correct number of archived file 2s');

#test that errors cause it to die
chmod 0000,"$tempdir/pub/";
change_files("$tempdir/foo.ish.bar","$tempdir/bar.ish.foo");
warnings_like {
    throws_ok {
        publish(['cp',"$tempdir/foo.ish.bar","$tempdir/pub"],
                ['cp',"$tempdir/bar.ish.foo","$tempdir/pub"],
               );
    } qr/permission denied/i, 'dies on error';
} [qr/operation failed/i, qr/rollback/,qr/rollback/], 'got warnings too';
find_if_debugging();
chmod 0700,"$tempdir/pub/";

#test that it is robust w.r.t. having just old versions in old/, with no
#current published version
unlink grep -f,glob("$tempdir/pub/*");

# printfiles;
# print "bleh\n";
change_files("$tempdir/foo.ish.bar","$tempdir/bar.ish.foo");
publish(['cp',"$tempdir/foo.ish.bar","$tempdir/pub"],
	['cp',"$tempdir/bar.ish.foo","$tempdir/pub"],
       );
find_if_debugging();
#printfiles;
ok(-f "$tempdir/pub/foo.v3.ish.bar", 'handles missing current version 1');
ok(-f "$tempdir/pub/bar.v3.ish.foo", 'handles missing current version 2');
is(readlink "$tempdir/pub/curr/foo.ish.bar", "../foo.v3.ish.bar", 'curr symlink points to current version 1');
is(readlink "$tempdir/pub/curr/bar.ish.foo", "../bar.v3.ish.foo", 'curr symlink points to current version 2');

#test touch
unlink "$tempdir/pub/curr/foo.ish.bar";
ok(! -l "$tempdir/pub/curr/foo.ish.bar",'successfully deleted link');
publish(['touch',"$tempdir/pub/foo.v3.ish.bar"],
	['touch',"$tempdir/pub/bar.v3.ish.foo"],
       );
is(readlink "$tempdir/pub/curr/foo.ish.bar", "../foo.v3.ish.bar", 'curr symlink points to current version 1');
is(readlink "$tempdir/pub/curr/bar.ish.foo", "../bar.v3.ish.foo", 'curr symlink points to current version 2');

#test link_or_print
my $linktest1 = File::Spec->catfile($tempdir,'pub','linktest1');
my $linktest2 = File::Spec->catfile($tempdir,'pub','linktest2');
system("echo fonebone > $linktest1");
ok(-f "$tempdir/pub/linktest1", 'echo worked');

ok(link_or_print($linktest1,$linktest2),'link returned success');
is(file_contents($linktest2),file_contents($linktest1),'link seems to have worked');

#test that link_or_print can take dir args
my $linktestdir = File::Spec->catdir($tempdir,'linktest');
mkdir $linktestdir
  or die 'could not make dir $linktestdir: $!';

ok(link_or_print($linktest1,$linktestdir),'link with dir target returned success');
is(file_contents($linktest1),file_contents("$linktestdir/linktest1"),'link with dir target seems to have worked');
is(file_contents("$linktestdir/linktest1"),"fonebone\n",'sanity check');

#test versioned rm and rm -f
publish(['rm',"$tempdir/pub/foo.ish.bar"],
       );
ok(! -f "$tempdir/pub/foo.v3.ish.bar", 'versioned delete deletes');
ok(-f "$tempdir/pub/bar.v3.ish.foo", 'versioned delete does not delete everything in the directory');
ok(! -l "$tempdir/pub/curr/foo.ish.bar", 'curr symlink is deleted by rm');
is(readlink "$tempdir/pub/curr/bar.ish.foo", "../bar.v3.ish.foo", 'curr symlink points to current version 2');

#test a versionedfile for this
{ my $vf = CXGN::Publish::VersionedFile->new("$tempdir/pub/foo.ish.bar");
  is( $vf->current_version, undef, 'got correct current_version');
  is( $vf->current_file, undef, 'got correct current_file');
  like( $vf->previous_versions->{1}->stringify, qr!old/foo.v1.ish.bar.\d+$!, 'got prev version 1' );
  like( $vf->previous_versions->{2}->stringify, qr!old/foo.v2.ish.bar.\d+$!, 'got prev version 2' );
}

#this should NOT die
lives_ok {
  publish(['rm -f',"$tempdir/pub/foo.ish.bar"]);
} 'versioned rm -f does NOT die if target does not exist';

#this SHOULD die
warnings_like {
    throws_ok {
        publish(['rm',"$tempdir/pub/foo.ish.bar"],
                ['rm',"$tempdir/pub/bar.ish.bar"],
               );
    } qr/no version/, 'versioned rm DOES die if target does not exist';
} [qr/operation failed/,qr/no operations/i], 'and got warnings';

#this should NOT die
lives_ok {
  publish(['rm',"$tempdir/pub/bar.ish.foo"]);
} 'repeat of versioned rm that should have been rolled back';


#if we try to publish again, with no perms, should do nothing, no movement
chmod 0000,"$tempdir/pub/";
warnings_like {
    throws_ok {
        publish(['cp',"$tempdir/foo.ish.bar","$tempdir/pub"],
                ['cp',"$tempdir/bar.ish.foo","$tempdir/pub"],
               );
    } qr/permission denied/i, 'dies on error';
} [qr/operation failed/i, qr/rollback/,qr/rollback/], 'got warnings too';
find_if_debugging();
chmod 0700,"$tempdir/pub/";


#if we publish again, we should get the same versions
publish(['cp',"$tempdir/foo.ish.bar","$tempdir/pub"],
	['cp',"$tempdir/bar.ish.foo","$tempdir/pub"],
       );
find_if_debugging();
#printfiles;
ok(-f "$tempdir/pub/foo.v3.ish.bar", 'publish same file again, get the same version');
ok(-f "$tempdir/pub/bar.v3.ish.foo", 'publish same file again, get the same version');
is(readlink "$tempdir/pub/curr/foo.ish.bar", "../foo.v3.ish.bar", 'curr symlink points to current version 3');
is(readlink "$tempdir/pub/curr/bar.ish.foo", "../bar.v3.ish.foo", 'curr symlink points to current version 3');

#test versioned rm and rm -f
publish(['rm',"$tempdir/pub/foo.ish.bar"],
        ['rm',"$tempdir/pub/bar.ish.foo"],
       );
ok(! -f "$tempdir/pub/foo.v3.ish.bar", 'versioned delete deletes');
ok(! -f "$tempdir/pub/bar.v3.ish.foo", 'versioned delete deletes the other file too' );
ok(! -l "$tempdir/pub/curr/foo.ish.bar", 'curr symlink is deleted by rm');
ok(! -l "$tempdir/pub/curr/bar.ish.foo", 'curr symlink is deleted by rm');

my $foo_hist = publishing_history("$tempdir/pub/foo.ish.bar");
my $bar_hist = publishing_history("$tempdir/pub/bar.ish.foo");
like( $foo_hist->{fullpath}, qr"$tempdir/pub/old/foo.v3.ish.bar.\d+$", 'fullpath looks right for foo');
is( $foo_hist->{fullpath_unversioned}, "$tempdir/pub/foo.ish.bar" );
like( $bar_hist->{fullpath}, qr"$tempdir/pub/old/bar.v3.ish.foo.\d+$", 'fullpath looks right for bar');
is( $bar_hist->{fullpath_unversioned}, "$tempdir/pub/bar.ish.foo" );

my $nonexistent_hist = publishing_history("$tempdir/pub/does.not.exist");
is_deeply( $nonexistent_hist,
           {
            fullpath => undef,
            fullpath_unversioned => "$tempdir/pub/does.not.exist",
            version => undef,
            obsolete_timestamp => undef,
            ancestors => [],
            lingerers => [],
           },
           'nonexistent hist looks right',
         )
    or diag "nonexistent actual:\n".Dumper($nonexistent_hist);

#test orig_basename
is(orig_basename("$tempdir/pub/monkey.v3.shines"),'monkey.shines','orig_basename works for regular published file');
is(orig_basename("$tempdir/pub/old/hooj.v3.choons.in.the.middle.200606865162165"),'hooj.choons.in.the.middle','orig_basename works on filenames in old/');

#test mkdir_or_print
mkdir_or_print("$tempdir/testdir/foo/bar/baz");
ok(-d "$tempdir/testdir/foo/bar/baz",'mkdir_or_print works');



sub change_files {
  foreach my $filename (@_) {
    our $change_file_inc++;
    open my $file, ">$filename" or die "Could not open $filename for writing: $!";
    print $file "this is change number $change_file_inc\n";
  }
}
