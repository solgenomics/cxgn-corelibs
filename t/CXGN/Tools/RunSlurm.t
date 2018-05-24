use strict;
use Test::More qw | no_plan |;
use CXGN::Tools::Run;

my @job_array;

# submit some jobs to cluster
#
for (1..4) {
    my $outfile = '/tmp/test'.$_;
    
    my $job = CXGN::Tools::Run->new(
        {
            backend => 'Slurm',
	    temp_base => '/tmp',
            out_file => $outfile,
        }
    );
    $job->run_cluster('/bin/hostname');
    push @job_array, $job;
}

# wait for all jobs to finish
#
foreach (@job_array) {
    while (my $alive = $_->alive()) {
        print STDERR "it is alive ($alive)... TO: ".$_->out_file()."\n";
        sleep(1);
    }
}

# check all job outputs and remove the temp files
#
my $hostname = `/bin/hostname`;

foreach my $job (@job_array) {
    is($job->out(), $hostname, "Check output from clusterjob (slurm)");
    #unlink $job->out_file;
}

done_testing();
