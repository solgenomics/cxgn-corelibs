
use strict;
use Test::More;
use CXGN::Tools::Run;

my $hostname = `/bin/hostname`;

my $ctr2 = CXGN::Tools::Run->new({ backend => 'Torque' });
$ctr2->run_cluster('/bin/hostname');

while (my $alive = $ctr2->alive()) { 
    sleep(1);
}

is($ctr2->out(), $hostname, "Check output from clusterjob (torque)");

