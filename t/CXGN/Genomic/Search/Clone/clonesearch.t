#!/usr/bin/perl
use strict;
use warnings;
use CXGN::Genomic::Search::Clone;
use CXGN::DB::Connection;
use Data::Dumper;

use Test::More tests=>6;

sub dbtee {
#  warn @_;
  wantarray ? @_ : $_[0];
}


my $search = CXGN::Genomic::Search::Clone->new;
ok($search);
my $dbconn = CXGN::DB::Connection->new;
ok($dbconn);

my $query = $search->new_query;
$query->estimated_length(' > ?',130_000);
$search->page_size(20);

my $result = $search->do_search($query);
$result->autopage($query,$search);
my $total = $result->total_results;

#test a simple query
my @ids1 = map {$_->[0]} @{$dbconn->selectall_arrayref('select c.clone_id from genomic.clone as c where c.estimated_length > ? limit 500',undef,130_000)};

my $resultcount = 0;
my $good = 1;
while(my $c = $result->next_result and $resultcount < @ids1) {
  unless($c->clone_id == $ids1[$resultcount]) {
    $good = 0;
    diag "Mismatch: ".$c->clone_id." is not ",$ids1[$resultcount],"\n";
    last;
  }
#   else {
#     diag $c->clone_id.' == '.@ids1[$resultcount]."\n";
#   }
  $resultcount++;
}
#print "got ",scalar(@ids1)." ids, count is $resultcount\n";
ok($good && $resultcount == @ids1,'first search ok');


#test a more complicated grouped, ordered query WHEN TESTING THINGS
# LIKE THIS KEEP IN MIND that in mysql (at least), when a GROUP BY is
# specified, mysql also orders the returned rows by the expressions in
# the GROUP BY
my $groupby = join(',',(map {"c.$_"} CXGN::Genomic::Clone->columns));
my $sql = dbtee("select c.clone_id,count(*) from genomic.clone as c left join genomic.chromat as chr using(clone_id) group by $groupby having count(chr.chromat_id)=1 order by c.estimated_length");
my $numreads1 = $dbconn->selectall_arrayref("$sql limit 30");
my ($numreads_count) = $dbconn->selectrow_array(dbtee("select count(*) from ($sql) as foo "));
$query->clear();
$query->num_reads('=1');
$query->orderby('estimated_length'=>'');
$result = $search->do_search($query);
$result->autopage($query,$search);
# print Dumper($numreads1);
# $Data::Dumper::Maxdepth = 3;
# print Dumper($result);

sub readcount {
  my $c = shift;
  my $gsscount = 0;
  my @chromats = $c->chromat_objects;
  scalar(@chromats);
}
ok(testquery::test_query($numreads1,$numreads_count,$result,[\&readcount]),'more complicated grouped, ordered');


$sql = dbtee("select c.clone_id,stat.status from genomic.clone as c left join sgn_people.bac_status as stat on stat.bac_id = c.clone_id where stat.status='in_progress'");
my $statuses = $dbconn->selectall_arrayref($sql);
my ($statuses_count) = $dbconn->selectrow_array(dbtee("select count(*) from ($sql) as foo"));

$query->clear();
$query->sequencing_status("=?",'in_progress');
$result = $search->do_search($query);
$result->autopage($query,$search);

sub seqstatus {
  shift->sequencing_status
}
ok( testquery::test_query( $statuses, $statuses_count, $result, [ \&seqstatus ] ),'sequencing status');

$sql = dbtee("select c.clone_id,stat.status,count(chr.chromat_id) FROM genomic.clone as c LEFT JOIN chromat as chr ON c.clone_id=chr.clone_id LEFT JOIN sgn_people.bac_status as stat ON stat.bac_id = c.clone_id WHERE stat.status='in_progress' OR c.estimated_length > 90000 GROUP BY $groupby,stat.status HAVING count(chr.chromat_id)=1");
my $compound = $dbconn->selectall_arrayref($sql);
my ($compound_count) = $dbconn->selectrow_array(dbtee("select count(*) from ($sql) as foo"));

#test a query with compound search terms
$query->page(0);
$query->num_reads('=?',1);
#recall: a sequencing_status parameter is set above, and the query is not cleared
$query->compound('&t OR &t','estimated_length','sequencing_status');
$query->estimated_length('> ?',90_000);
$result = $search->do_search($query);
$result->autopage($query,$search);

ok( testquery::test_query( $compound, $compound_count, $result, [ \&seqstatus, \&readcount ] ), 'compound terms' );


package testquery;
use Carp;

=head2 test_query

  Desc:	given the results of a Clone Search and a manual search, compare the two and return true if they match
  Args:	
  Ret :	
  Side Effects:	
  Example:

=cut

sub test_query {
  my ( $manual, $manualcount, $fromsearch, $datasubs ) = @_;
  (ref $datasubs) eq 'ARRAY'
    or croak 'data subroutines must be in an array ref'
      if $datasubs;

  unless( $manualcount == $fromsearch->total_results ) {
    warn "Count mismatch: manual query matched $manualcount rows, automatic query reported matching ".$fromsearch->total_results."\n";
    return 0;
  }

  my $good = 1;
  my $resultcount = 0;
  while (my $c = $fromsearch->next_result and $resultcount < @$manual) {
    if ( $c->clone_id eq $manual->[$resultcount]->[0]) {
      my $datacol = 1;
      if($datasubs) {
	foreach my $datasub (@$datasubs) { #do checks on the derived data
	  my $subresult = $datasub->($c) || '';
	  unless($subresult eq $manual->[$resultcount]->[$datacol]) {
	    $good = 0;
	    carp  "Data mismatch: ".$c->clone_id." has ".$manual->[$resultcount]->[$datacol]." from manual query, but has $subresult from the automatic query\n";
	    last;
	  }
	  $datacol++;
	}
      }
    } else {
      carp "Error in clones returned: Search::Clone query gave clone '".$c->clone_id."', while the manual query gave clone '".$manual->[$resultcount]->[0]."'\n";
      $good = 0;
      last;
    }
    $resultcount++;
  }

  carp "Mismatch in result count: manual query matched ".@$manual.", while the automatic query matched ".$resultcount
    unless $resultcount == @$manual;

  return $good && $resultcount == @$manual;
}
$dbconn->rollback();

###
1;#do not remove
###
