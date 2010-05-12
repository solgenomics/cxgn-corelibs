#!/usr/bin/env perl
use strict;
use warnings;
use English;
use Carp;
use FindBin;
use Getopt::Std;

use CXGN::DB::Connection;
use CXGN::Tools::Wget qw/wget_filter/;

use Test::More;
use Test::Exception;

sub usage {
  my $message = shift || '';
  $message = "Error: $message\n" if $message;
  die <<EOU;
$message
Usage:
  $FindBin::Script resource_name ...

  Check and test-download each of the cxgn-resources named.  If
  nothing is passed, or 'all' is passed, validate all cxgn-resources
  that are defined.

  Options:

    none

EOU
}
sub HELP_MESSAGE {usage()}

our %opt;
getopts('',\%opt) or usage();

my @resources = @ARGV;
s!^cxgn-resource://!!i foreach @resources;

if( !@resources || grep lc($_) eq 'all', @resources) {
  my $dbh = CXGN::DB::Connection->new;
  my $l = $dbh->selectcol_arrayref('select name from public.resource_file');
  @resources = @$l;
  $dbh->disconnect(42);
}

plan tests => scalar(@resources);

foreach my $resource_name (@resources) {
    #print "test-fetching cxgn-resource://$resource_name ...\n" unless $opt{q};
  lives_ok {
    wget_filter("cxgn-resource://$resource_name", {test_only => 1});
  } "fetched $resource_name ok";
}
