#!/usr/bin/perl

use strict;
use CXGN::DB::Connection;
use CXGN::Marker::LocMarker;
use CXGN::Marker::Search;

my $dbh = CXGN::DB::Connection->new({
    dbhost => 'scopolamine',
    dbname => 'sandbox',
    dbbranch => 'devel',
    });

#for (0..200){ # test a few times
  
  my $msearch = CXGN::Marker::Search->new($dbh);
  $msearch->must_be_mapped();
#  $msearch->has_subscript();
#  $msearch->random();
  #$msearch->marker_id(518);
  $msearch->perform_search();
  print $msearch->query_text()."\n" if $_ == 0;

#  my @locs = $msearch->fetch_id_list();
#my @locs = $msearch->fetch_full_markers();
#foreach my $loc (@locs){
#  $loc->locations();
#}

  my @locs = $msearch->fetch_location_markers();

#  foreach my $loc (@locs){
#    my $loc_id = $loc->location_id();
#    my $chr = $loc->chr();
#    my $pos = $loc->position();
#    my $sub = $loc->subscript();
#    my $conf = $loc->confidence();
#    my $mv = $loc->map_version();
#    my $map = $loc->map_id();
#  }

#}
