package CXGN::Garbage::job_dispatch;
use strict;

my @typical_nodes = ( "node1", 
		      "node1",
		      "node2",
#	"node2",
		      "node3",
		      "node3",
		      "node4",
		      "node4",
		      "node5",
		      "node5",
		      "node6",
		      "node6",
		      "node7",
		      "node7",
		      "node8",
		      "node8",
		      "node9",
		      "node9",
		      "node10",
		      "node10",
		      "node11",
		      "node11",
		      "node12",
		      "node12",
		      "node13",
		      "node13",
		      "node14",
#	"node14",
		      "node15",
		      "node15"
		      );

# [0] = working directory
# [1] = command
# [2] = label (name)
# [3] = exit code
# [4] = allocated node

my ($n_done, $n_jobs);
sub dispatch_jobs {
    my ($jobs_ref, $node_ref) = @_;

    my ($job, $job_no, $working_directory, $command, $label, $node, $pid);
    $n_jobs = @{$jobs_ref};
    $n_done = 0;
    my %running_jobs = ();
    my @free_nodes = ();

    $job_no = 0;
    if (!defined($node_ref)) {
	@free_nodes = @typical_nodes;
    } else {
	@free_nodes = @{$node_ref};
    }

    foreach $job ( @{$jobs_ref} ) {
	$working_directory = $job->[0];
	$command = $job->[1];
	$label = $job->[2];

	
	if (@free_nodes == 0) {
	    wait_jobfinish(\@free_nodes, \%running_jobs);
	}
	$node = shift @free_nodes;
	if ($label) {
	    print "Starting job #$job_no of $n_jobs ($label) on node $node\n";
	}
	$job_no++;

	if (($pid = fork()) == 0) {
	    my $rsh_command;

	    # Child process split off to mind this instance of RSH while we
	    # pound off starting other RSH processes
	    $rsh_command = "rsh_wrapper.sh $node \"cd $working_directory ; $command\"";
	    exec $rsh_command;

	    # This can't execute unless exec failed. If exec failed, we are
	    # still forked, so we exit the child
	    die "Failed executing RSH command \"$rsh_command\" ($!)";
	} else {
	    # This process (parent)
	    $running_jobs{$pid} = [ $node, $job ];

	    # Assign allocated node
	    $job->[4] = $node;
	}
    }

    print STDERR "All jobs started, waiting for running jobs (";
    print STDERR scalar(keys(%running_jobs)),") to finish\n";
    while(keys(%running_jobs)>0) {
	wait_jobfinish(\@free_nodes, \%running_jobs);
    }
    print STDERR "Parallel dispatching of $job_no jobs finished.\n";

    # Count number of jobs which failed, return to caller who decides
    # to die or not because of it
    my @failed = ();
    for(my $i=0;$i<$job_no;$i++) {
	if ($jobs_ref->[$i]->[3] != 0) {
	    push @failed, $i;
	}
    }

    foreach ( @failed ) {
	print STDERR "$jobs_ref->[$_]->[2] failed ($jobs_ref->[$_]->[4])"
	    . "(Exit code $jobs_ref->[$)]->[3])\n";
	print STDERR "Command: $jobs_ref->[$_]->[1]\n";
    }

    return @failed;
}

sub wait_jobfinish {
    my ($free_ref, $run_ref) = @_;
    my ($pid, $job, $node);

    $pid = wait;
    $n_done++;

    # These two error conditions indicate serious problems with this module
    # or whatever has happened in the program which called this module.
    if ($pid == -1) {
	die "There are no free nodes but wait() returns -1 ($!)\n";
    }
    if (! defined($run_ref->{$pid})) {
	print STDERR "Error: unknown child process $pid returned by wait()\n";
	print STDERR "That shouldn't happen unless this script is broken!\n";
	die "Refusing to continue, nothing must be working\n";
    }
    $node = $run_ref->{$pid}->[0];
    $job = $run_ref->{$pid}->[1];

    # We do not stop here if a job fails, instead we continue until every
    # job has been started and finished. We return to the caller of this
    # module the number of failed jobs -- they decide whether or not to
    # continue. The idea is for the caller to treat calling this module
    # with a job list like running a single command via system()
    if ($? && $job->[2]) {
	print STDERR "Job $job->[2] (sent to $job->[4]) failed. Exit code: ",$?/256,"\n";
    } else {
      printf STDERR "$n_done jobs finished (%4.1f completed)\n",
	($n_done/$n_jobs*100.0);
    }
    $job->[3] = $?/256;
    push @{$free_ref}, $node;
    delete $run_ref->{$pid};
}

return 1;
