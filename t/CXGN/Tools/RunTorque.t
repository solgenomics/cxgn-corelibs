
use strict;
use Test::More;
use CXGN::Tools::Run;

my $hostname = `/bin/hostname`;

my $ctr2 = CXGN::Tools::Run->run_cluster(
    '/bin/hostname',
    { backend => 'torque'}
    );

while (my $alive = $ctr2->alive()) { 
    sleep(1);
}

is($ctr2->out(), $hostname, "Check output from clusterjob (torque)");

