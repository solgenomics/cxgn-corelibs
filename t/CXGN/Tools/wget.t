#!/usr/bin/perl
use strict;
use warnings;

use File::Temp qw/tempfile/;

use Test::More tests => 15;
use Test::Exception;
use IO::Pipe;

use POSIX;
use CXGN::Tools::File qw/file_contents/;

BEGIN {
  use_ok(  'CXGN::Tools::Wget', 'wget_filter', 'clear_cache'  );
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

package TestWebServer;
use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);
use strict;
use warnings;
my $hits = 0;
$|++;

sub handle_request {
    my $self = shift;
    my $cgi  = shift;

    print "HTTP/1.0 200 OK\r\n";
    respond($cgi);
}

sub respond {
    my $cgi = shift;
    return if !ref $cgi;

    $hits++;
    print $cgi->header(), "$hits\n";
}
package main;

TEST_WGET_FILTER_CONCURRENCY();

sub TEST_WGET_FILTER_CONCURRENCY {
    # We don't want to use any previously-generated cache
    clear_cache();

    my $webpid  = TestWebServer->new(8080)->background();
    diag "Starting a test web server on port 8080, pid = $webpid";

    my $pipe = IO::Pipe->new;

    if (my $testpid = fork()) { # parent
        $pipe->reader;
        my $file = wget_filter( 'http://localhost:8080' );
        my ($hits) = split /\n/, file_contents($file);
        is($hits,1,'wget_filter concurrency');

        # We don't need the webserver anymore
        kill 9, $webpid;

        # Read from the child
        while( <$pipe> ) {
            is($_,1,'wget_filter concurrency');
        }

    } elsif (defined $testpid) { # child
        $pipe->writer;
        my $file = wget_filter( 'http://localhost:8080' );
        my ($hits) = split /\n/, file_contents($file);
        print $pipe $hits;

        # Don't run END/DESTROY blocks
        POSIX::exit(0);
    }
}
