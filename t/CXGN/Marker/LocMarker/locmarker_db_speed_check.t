#!/usr/bin/perl
use DBI;
my $dbh = DBI->connect("dbi:Pg:dbname=sandbox;host=scopolamine", "web_usr", "tomato");

#use CXGN::DB::Connection;
#my $dbh = CXGN::DB::Connection->new({
#    dbhost => 'scopolamine',
#    dbname => 'sandbox',
#    dbbranch => 'devel',
#    });

#for (0..200){
#  $dbh->do("set search_path=sgn_dev; SELECT * FROM (SELECT DISTINCT  marker_id, location_id, lg_name, lg_order, position, confidence_id, subscript, map_version_id, map_id  FROM ((SELECT  marker_id, location_id, lg_name, lg_order, position, confidence_id, subscript, map_version_id, map_id  FROM sgn_dev.marker_to_map)INTERSECT (SELECT  marker_id, location_id, lg_name, lg_order, position, confidence_id, subscript, map_version_id, map_id  FROM sgn_dev.marker_to_map WHERE position IS NOT NULL) INTERSECT (SELECT  marker_id, location_id, lg_name, lg_order, position, confidence_id, subscript, map_version_id, map_id  FROM sgn_dev.marker_to_map WHERE subscript IS NOT NULL) ) as midq INNER JOIN ((SELECT marker_id FROM marker)) as mlq using(marker_id)) AS rquery ORDER BY RANDOM() LIMIT 1");
#}
$dbh->do("set search_path=sgn_dev;SELECT DISTINCT  marker_id, location_id, lg_name, lg_order, position, confidence_id, subscript, map_version_id, map_id  FROM ((SELECT  marker_id, location_id, lg_name, lg_order, position, confidence_id, subscript, map_version_id, map_id  FROM marker_to_map)INTERSECT (SELECT  marker_id, location_id, lg_name, lg_order, position, confidence_id, subscript, map_version_id, map_id  FROM marker_to_map WHERE position IS NOT NULL) ) as midq INNER JOIN ((SELECT marker_id FROM marker)) as mlq using(marker_id) ORDER BY lg_order, position, subscript, confidence_id desc");
