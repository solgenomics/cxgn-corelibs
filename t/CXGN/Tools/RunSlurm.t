use strict;
use Test::More tests=>1;
use CXGN::Tools::Run;

my $ctr = CXGN::Tools::Run->run_cluster(
    '/bin/hostname',

    { 
	backend => 'slurm',
	out_file => '/tmp/test1',
    });
    
while (my $alive = $ctr->alive()) { 
    #print STDERR "it is alive ($alive)...\n";
    sleep(1);
}

my $hostname = `/bin/hostname`;

is($ctr->out(), $hostname, "Check output from clusterjob (slurm)");