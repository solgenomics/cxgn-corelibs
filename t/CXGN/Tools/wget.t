#!/usr/bin/perl
use strict;
use warnings;

use File::Temp qw/tempfile/;

use Test::More tests => 13;
use Test::Exception;

use CXGN::Tools::File qw/file_contents/;

BEGIN {
  use_ok(  'CXGN::Tools::Wget', 'wget_filter'  );
}

my (undef,$tempfile) = tempfile(UNLINK => 1);

lives_ok( sub { wget_filter( 'http://www.sgn.cornell.edu/' => $tempfile ); }, 'fetched http without error' );
ok( -f $tempfile, 'download target exists');
ok( file_contents($tempfile) =~ /solanaceae/i, 'download worked');

lives_ok( sub { wget_filter( 'http://www.sgn.cornell.edu/' => $tempfile,
            sub {
                my $line = shift;
                $line =~ s/solanaceae/monkeys in the middle of the desert/i;
                return $line;
            }
        );
},'fetched http without error' );
ok( file_contents($tempfile) =~ /monkeys in the middle of the desert/, 'download filters work');

#test downloading from ftp
lives_ok( sub { wget_filter( 'ftp://ftp.sgn.cornell.edu/tomato_genome/bacs/validate_submission.v*.pl' => $tempfile ); },'fetch from ftp ' . $@ );
ok( file_contents($tempfile) =~ /BACSubmission/, 'ftp download worked');

SKIP: {
    eval { wget_filter('cxgn-resource://nyarlathotep') };
    if ($@ =~ m/DBI connect/) {
        skip "Could not connect to database", 3;
    }
    #try to get a nonexistent cxgn-resource url
    throws_ok( sub { wget_filter( 'cxgn-resource://no-existe!'); }, qr/no cxgn-resource found/,  'wget of nonexistent resource dies');

    #try to get one that exists
    my $file = wget_filter( 'cxgn-resource://test' );
    ok( -f $file, 'wget of existing resource succeeds' );
    unlink $file;

    #test test-fetching
    # this should die if unsuccessful, we just need to see that it took a
    # sufficiently short time

    my $begin = time;
    wget_filter( 'cxgn-resource://tom_pot_combined_ests', {test_only => 1});
    my $fetch_time = time - $begin;
    ok( $fetch_time < 10, 'test fetching seems to be working' );
}

#test caching and aging
wget_filter( 'http://tycho.usno.navy.mil/cgi-bin/timer.pl' => $tempfile );
my (undef,$tempfile2) = tempfile(UNLINK => 1);
sleep 3;
wget_filter( 'http://tycho.usno.navy.mil/cgi-bin/timer.pl' => $tempfile2 );
unlike(`diff -q $tempfile $tempfile2`,qr/differ/,'caching works');
wget_filter( 'http://tycho.usno.navy.mil/cgi-bin/timer.pl' => $tempfile2, {max_age => 1} );
like(`diff -q $tempfile $tempfile2`, qr/differ/, 'caching expiry works');

