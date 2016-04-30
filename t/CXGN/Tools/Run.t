
use strict;
use Test::More;
use CXGN::Tools::Run;

my $ctr = CXGN::Tools::Run->run_cluster(
    '/bin/hostname',

    { 
	backend => 'slurm',
	out_file => '/tmp/test1',
    });
    
print STDERR "Checking if it is alive...\n";
while (my $alive = $ctr->alive()) { 
    print STDERR "it is alive ($alive)...\n";
}

print STDERR "Generating output...\n";
print STDERR $ctr->out()."\n";
print STDERR "ERROR OUTPUT:\n";
print STDERR $ctr->err()."\n";
# my $ctr2 = CXGN::Tools::Run->run_cluster(
#     'sleep',
#     60,
#     { backend => 'slurm'}
#     );
    
# while (my $alive = $ctr->alive()) { 
#     print "it is alive ($alive)...\n";
#     sleep(10);
# }

print STDERR "Done.\n";
