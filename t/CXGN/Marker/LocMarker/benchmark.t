#!/usr/bin/perl

use strict;
use CXGN::DB::Connection;
use CXGN::Marker::LocMarker;
use CXGN::Marker::Search;
use Benchmark;

my $dbh = CXGN::DB::Connection->new({
    dbhost => 'scopolamine',
    dbname => 'sandbox',
    dbbranch => 'devel',
    });


sub search_1200_locs_locmarkers {  
  my $msearch = CXGN::Marker::Search->new($dbh);
  $msearch->must_be_mapped();
  $msearch->perform_search();
#  print $msearch->query_text()."\n" if $_ == 0;

#  my @locs = $msearch->fetch_id_list();
#my @locs = $msearch->fetch_full_markers();
#foreach my $loc (@locs){
#  $loc->locations();
#}

  my @locs = $msearch->fetch_location_markers();

}


sub search_1200_locs_fullmarkers_with_location {

  my $msearch = CXGN::Marker::Search->new($dbh);
  $msearch->must_be_mapped();
  $msearch->perform_search();
#  print $msearch->query_text()."\n" if $_ == 0;

#  my @locs = $msearch->fetch_id_list();
#my @locs = $msearch->fetch_full_markers();
#foreach my $loc (@locs){
#  $loc->locations();
#}

  my @locs = $msearch->fetch_full_markers();

  foreach my $loc(@locs){
    $loc->locations();
  }

}

sub search_1200_locs_fullmarkers {

  my $msearch = CXGN::Marker::Search->new($dbh);
  $msearch->must_be_mapped();
  $msearch->perform_search();
#  print $msearch->query_text()."\n" if $_ == 0;

#  my @locs = $msearch->fetch_id_list();
#my @locs = $msearch->fetch_full_markers();
#foreach my $loc (@locs){
#  $loc->locations();
#}

  my @locs = $msearch->fetch_full_markers();


}

sub plain_ol_query {

  my $stuff = $dbh->selectall_arrayref("SELECT DISTINCT  marker_id, location_id, lg_name, lg_order, position, confidence_id, subscript, map_version_id, map_id  FROM ((SELECT  marker_id, location_id, lg_name, lg_order, position, confidence_id, subscript, map_version_id, map_id  FROM marker_to_map)INTERSECT (SELECT  marker_id, location_id, lg_name, lg_order, position, confidence_id, subscript, map_version_id, map_id  FROM marker_to_map WHERE position IS NOT NULL) ) as midq INNER JOIN ((SELECT marker_id FROM marker)) as mlq using(marker_id) ORDER BY lg_order, position, subscript, confidence_id desc");

}


timethese(100, {
		locmarkers => \&search_1200_locs_locmarkers,
		fullmarkerlocs => \&search_1200_locs_fullmarkers_with_location,
		fullmarkers => \&search_1200_locs_fullmarkers,
		plainquery => \&plain_ol_query,
});
