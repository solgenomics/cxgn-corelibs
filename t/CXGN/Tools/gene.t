#!/usr/bin/perl
use Modern::Perl;

use Test::More tests => 9;

use CXGN::Tools::Gene;
use Data::Dumper;

my $gene = CXGN::Tools::Gene->new("AT1G01010.1");

$gene->fetch_sigp();
ok(ref($gene) eq "CXGN::Tools::Gene", "Gene object exists and is correctly blessed");

my $ss = $gene->property('nn_score');
ok($ss, "Gene has property 'nn_score' after explicit fetch: $ss");

ok($gene->get_signal_score(), "Gene can use get_signal_score() to achieve the same thing");

my $ps = $gene->get_sequence('protein');
diag(substr($ps, 0, 50) . "...");
ok($ps, "Gene grabbed the protein sequence with implicit fetching");

my @domains = $gene->get_domains();
diag(Dumper(\@domains));
ok(@domains, "Arabidopsis gene has " . scalar(@domains) . " domain");

my $unigene = CXGN::Tools::Gene->new("SGN-U323444");
ok($unigene, "Unigene object created");
my $protein = $unigene->get_sequence('protein');
diag(substr($protein, 0, 50) . "...");
ok($protein, "Unigene has protein sequence");
my $signal_score = $unigene->get_signal_score();
ok($signal_score, "Unigene has a signal score: $signal_score");
(@domains) = $unigene->get_domains();
diag(Dumper(\@domains));
ok(@domains, "Unigene has " . scalar(@domains) . " domain");

