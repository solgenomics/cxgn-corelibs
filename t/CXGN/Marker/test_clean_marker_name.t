#!/usr/bin/perl

# test clean_marker_name. 
# Run this anytime you make a change to that routine. 

use strict;
use CXGN::DB::Connection;
use CXGN::Marker::Tools qw(clean_marker_name);
use Test::More 'no_plan';

my $dbh = CXGN::DB::Connection->new();

my $marker_names = $dbh->selectcol_arrayref('select alias from sgn.marker_alias');

foreach my $name (@$marker_names){

  my $name2 = clean_marker_name($name);
  my $name3 = clean_marker_name($name2);
  is($name2, $name3, "$name2 becomes $name3");

}






