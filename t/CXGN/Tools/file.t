#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;

use Time::HiRes qw/ usleep /;
use File::Temp qw/tempfile/;
use File::Spec::Functions qw/ tmpdir catfile/;

use_ok( 'CXGN::Tools::File', qw/size_changing read_commented_file/ );

my $test_string = "#monkeys in my pants and also in the attic!\nand the last line was a comment!\n"x42;
my ($tfh,$tf) = tempfile(UNLINK => 1);
print $tfh $test_string;
close $tfh;
is( read_commented_file($tf), "and the last line was a comment!\n"x42, 'read_commented_file');

#test size_changing

my $changing_file = catfile( tmpdir(), 'file.t-changing-size-tmp' );
unless(fork) { exec 'perl', '-E', 'my $n = shift; for (1..4){ open $f, ">>$n" or die $!; print $f "fog\n"x100; close $f; sleep 1 }', $changing_file }
usleep(500_000);
ok( size_changing($changing_file,1), "size_changing knows when it's changing" );
ok(! size_changing('/etc/fstab',1),"size_changing knows when it's not");

unlink $changing_file;
