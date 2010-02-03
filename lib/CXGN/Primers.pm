#!/usr/bin/perl

package CXGN::Primers;

use CXGN::DB::Connection;
use strict;

sub get_sequence {
    my $sequence_name = shift;

    my $dbh = CXGN::DB::Connection->new() or die "cannot connect: $!\n";

    my $sequence =  &get_sequence_1($sequence_name,$dbh);
    if ($sequence eq "") {
	$sequence = &get_sequence_2($sequence_name,$dbh);
    }

    $dbh->disconnect(42) or die "cannot disconnect: $!\n";

    return $sequence;
}

sub get_sequence_2 {
    my ($sequence_name,$dbh) = @_;

    my $select = "select seq from unigene join unigene_member using "
	. "(unigene_id) join est using (est_id) where sequence_name = '$sequence_name';";
    my $sth = $dbh->prepare("$select");
    $sth->execute;
    my $sequence = $sth->fetchrow();
    $sth->finish;

    return $sequence;
}

sub get_sequence_1 {
    my ($sequence_name,$dbh) = @_;
    
    my $select = "select seq from unigene_consensi join unigene "
	. "using (consensi_id) where sequence_name = '$sequence_name';";
    my $sth = $dbh->prepare("$select");
    $sth->execute;
    my $sequence = $sth->fetchrow();
    $sth->finish;

    return $sequence;
}

1;
