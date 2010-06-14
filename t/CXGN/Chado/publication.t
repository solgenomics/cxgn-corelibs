#!/usr/bin/perl

=head1 NAME

  publication.t
  A test for  CXGN::Chado::Publication class

=cut

=head1 SYNOPSIS

 perl publication.t



=head1 DESCRIPTION


=head2 Author

Naama Menda <n249@cornell.edu>


=cut

use strict;

use Test::More tests=>6; # qw/no_plan/;
use CXGN::DB::Connection;
use CXGN::Chado::Publication;

use Data::Dumper;

my $dbh = CXGN::DB::Connection->new(); 

my $q= "SELECT max (pub_id) FROM pub";
my $sth=$dbh->prepare($q);
$sth->execute();
my ($last_pub_id) = $sth->fetchrow_array();

# make a new publication and store it, all in a transaction. 
# then rollback to leave db content intact.

eval {
    my $pub = CXGN::Chado::Publication->new($dbh);
    my $title= "Test publication";
    my $volume="1";
    my $series="My Journal";
    my $issue= "10";
    my $pages="1-2";
    my $cvterm_name= "journal";

    $pub->set_title($title);
    $pub->set_volume($volume);
    $pub->set_series_name($series);
    $pub->set_issue($issue);
    $pub->set_pages($pages);
    $pub->set_cvterm_name($cvterm_name); #cvterm name has to be in cvterm table. See cv.name=publication   
    
    
    #store a pub_curator
    #now store some dbxref info 
    #abstract
    # and a bunch of authors
    
    my $pub_id= $pub->store();
    
    my $re_pub= CXGN::Chado::Publication->new($dbh, $pub_id);
    is($re_pub->get_title(), $title, "Title test");
    is($re_pub->get_volume(), $volume, "Volume test");
    is($re_pub->get_series_name(), $series, "series test");
    is($re_pub->get_issue(), $issue, "issue test");
    is($re_pub->get_pages(), $pages, "Pages test");
    is($re_pub->get_cvterm_name(), $cvterm_name, "cvterm_name test");
    
};

######ok (@term_list == 2, "get_parents");

if ($@) { 
    print STDERR "An error occurred: $@\n";
}

# rollback in any case
$dbh->rollback();

#reset table sequence
$dbh->do("SELECT setval ('pub_pub_id_seq', $last_pub_id, true)");


