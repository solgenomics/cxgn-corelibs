#!/usr/bin/perl
use strict;
use warnings;
use English;

use List::Util qw/sum/;

use Test::More tests => 5;

use CXGN::DB::Connection;

my $dbh=CXGN::DB::Connection->new();
BEGIN {
  use_ok(  'CXGN::People::BACStatusLog'  )
    or BAIL_OUT('could not include the module being tested');
}


my $bac_status_log = CXGN::People::BACStatusLog->new($dbh);
isa_ok( $bac_status_log, 'CXGN::People::BACStatusLog' );

my @bacs_to_complete = $bac_status_log->get_number_bacs_to_complete();

my $first = shift @bacs_to_complete;

is( $first, sum( @bacs_to_complete ), 'get_number_bacs_to_complete returns sum, then other values');

my @pct_finished = $bac_status_log->get_chromosomes_percent_finished();
$first = shift @pct_finished;
cmp_ok( $first, '<', 100, 'sum pct is in right range');
cmp_ok( $first, '>', 1, 'sum pct in right range 2');

$bac_status_log = undef;

$dbh->disconnect(42);
