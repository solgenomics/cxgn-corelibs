
use strict;
use Test::More;
use CXGN::Tools::Run;

my $ctr = CXGN::Tools::Run->run_cluster(
    'sleep 20',

    { 
	backend => 'slurm',
	out_file => '/tmp/test1',
    });
    
print STDERR "Checking if it is alive...\n";
while (my $alive = $ctr->alive()) { 
    print STDERR "it is alive ($alive)...\n";
    $ctr->cancel();

    sleep(1);
}

eval { 
    print STDERR "Generating output...\n";
    print STDERR $ctr->out()."\n";
    print STDERR "ERROR OUTPUT:\n";
    print STDERR $ctr->err()."\n";
};
if ($@) { 
    print STDERR "An error occurred: $@\n";
}

#  my $ctr2 = CXGN::Tools::Run->run_cluster(
#      '/bin/hostname',
#      { backend => 'torque'}
#      );
   
#  while (my $alive = $ctr2->alive()) { 
#      print "it is alive ($alive)...\n";
#      sleep(2);
#  }

# print STDERR "Generating output...\n";
# print STDERR $ctr2->out()."\n";
# print STDERR "ERROR OUTPUT:\n";
# print STDERR $ctr2->err()."\n";


# print STDERR "Done.\n";
