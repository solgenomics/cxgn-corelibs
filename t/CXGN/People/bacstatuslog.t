#!/usr/bin/perl
use strict;
use warnings;
use English;

use List::Util qw/sum/;

use Test::More;

use CXGN::DB::Connection;

my $dbh=CXGN::DB::Connection->new();
BEGIN {
  use_ok(  'CXGN::People::BACStatusLog'  )
    or BAIL_OUT('could not include the module being tested');
}


my $bac_status_log = CXGN::People::BACStatusLog->new($dbh);
isa_ok( $bac_status_log, 'CXGN::People::BACStatusLog' );

$bac_status_log->bac_by_bac_progress_statistics;

$dbh->disconnect(42);

done_testing;


