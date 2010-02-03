#!/usr/bin/perl

use strict;

use Test::More qw /no_plan/;
use CXGN::DB::Connection;
use CXGN::Transcript::Unigene;

my $dbh = CXGN::DB::Connection->new();

# instatiate some unigenes and check whether they are ok...
# 
my $unigene = CXGN::Transcript::Unigene->new($dbh, 333333);

my $unigene_id = $unigene->get_unigene_id();
my $sgn_id = $unigene->get_sgn_id();
my $sequence = $unigene->get_sequence();
my $build_id = $unigene->get_build_id();
my $member_count = $unigene->get_nr_members();
my @arabidopsis_annotations = $unigene->get_arabidopsis_annotations(1e-20);
my @genbank_annotations = $unigene->get_genbank_annotations(1e-20);
#my @interpro_domains = $unigene->get_interpro_domains();
my $cds = $unigene->get_estscan_cds();
my $protein = $unigene->get_estscan_protein();
my $estscan_direction = $unigene->get_estscan_direction();

print STDERR ">$unigene_id, $build_id, $member_count, ".join("|", @genbank_annotations)." ".length($sequence)."\n$sequence\n";
print STDERR ">cds ".length($cds)." $estscan_direction\n$cds\n";
is($unigene_id, 333333, "unigene id check");
is($sgn_id, "SGN-U333333", "sgn id check");
is(length($sequence), 780, "sequence length check");
is($member_count, 2, "member count check");
is($build_id, 23, "build id check");
print STDERR "ARABIDO: ".(join "\t", @{$arabidopsis_annotations[0]})."\n";
like($arabidopsis_annotations[0]->[7], qr/phosphomutase/, "arabidopsis annotation check");
like($genbank_annotations[0]->[7], qr/phosphoglucomutase/, "genbank annotation check");
#like($interpro_domains[0]->[0], qr/IPR005844/, "interpro domain check");
is(length($cds), 576, "cds sequence check");
is(length($protein), 576/3, "protein sequence check");
is($estscan_direction, "F", "estscan diretion check");

# instantiate a singleton unigene and test the sequence and other things
#
my $singleton = CXGN::Transcript::Unigene->new($dbh, 333450);
my $singleton_sequence = $singleton->get_sequence();
is(length($singleton_sequence), 823, "singleton unigene sequence length");
