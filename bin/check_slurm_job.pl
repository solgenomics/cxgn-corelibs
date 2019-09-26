#!/usr/bin/perl

=head1 NAME

slurm/alive.pl - a script to query the state of slurm jobs

=head1 SYNOPSYS

slurm/alive.pl <job_id> <job_temp_dir>

=head1 DESCRIPTION

This script is used in conjunction with the CXGN::Tools::Run 
plugin RemoteSlurm that allows a slurm job to be launched on 
a remote server. The script needs to be in the $PATH on that
server.

=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>
September 2019

=cut
    
use strict;

use Slurm;

my $job_id = shift;
my $temp_dir  = shift || "/tmp";

print alive($job_id, $temp_dir);

sub alive {
    my $job_id = shift;
    my $job_temp_dir = shift;
    
    my $slurm = Slurm::new();
    
    my $job_info = $slurm->load_job($job_id);
    my $current_job = $job_info->{job_array}->[0];
    
    _check_nodes_states();

    print STDERR "Check job state...\n";

    if (IS_JOB_RUNNING($current_job)) {
        print STDERR "Slurm job is running...\n";
        return 1;
    }
    if (IS_JOB_COMPLETE($current_job)) {
        print STDERR "slurm job is complete...\n";
        return;
    }
    if (IS_JOB_FINISHED($current_job)) {
        print STDERR "Slurm job is finished...\n";
        return;
    }
    if (IS_JOB_COMPLETED($current_job)) {
        print STDERR "Slurm job is completed...\n";
        return;
    }
    if (IS_JOB_PENDING($current_job)) {
        print STDERR "Slurm job is pending...\n";
        return 1;
    }
    if (IS_JOB_COMPLETING($current_job)) {
        print STDERR "Slurm job is completing...\n";
        return 1;
    }
    if (IS_JOB_CONFIGURING($current_job)) {
        print STDERR "Slurm job is configuring...\n";
        return 1;
    }
    if (IS_JOB_STARTED($current_job)) {
        print STDERR "Slurm job is started...\n";
        return 1;
    }
    if (IS_JOB_RESIZING($current_job)) {
        print STDERR "Slurm job is resizing...\n";
        return 1;
    }
    if (IS_JOB_SUSPENDED($current_job)) {
        die "Slurm job is suspended...\n";
    }
    if (IS_JOB_CANCELLED($current_job)) {
        die "Slurm job is canceled...\n";
    }
    if (IS_JOB_FAILED($current_job)) {
        die "Slurm job is failed...\n";
	write_file(File::Spec->catfile($job_temp_dir, "died"), "Slurm job failed\n");
    }
    if (IS_JOB_TIMEOUT($current_job)) {
        die "Slurm job is timed out...\n";
	write_file(File::Spec->catfile($job_temp_dir, "died"), "Slurm job timed out\n");
    }
    if (IS_JOB_NODE_FAILED($current_job)) {
        die "Slurm job node failed...\n";
	write_file(File::Spec->catfile($job_temp_dir, "died"), "Slurm job node failed\n");
    }

    die "Slurm job is in an unknown state...\n";
}

sub _check_nodes_states {
    my $self = shift;

    my $slurm = Slurm::new();
    my $nodes_info = $slurm->load_node();
    my $node_array = $nodes_info->{node_array};

    foreach (@$node_array) {
        if (IS_NODE_UNKNOWN($_)) {
            die "Slurm node is unknown... Node: ".$_->{name}."\n";
        }
        if (IS_NODE_DOWN($_)) {
            die "Slurm node is down... Node: ".$_->{name}."\n";
        }
        if (IS_NODE_IDLE($_)) {
            print STDERR "Slurm node is idle... Node: ".$_->{name}."\n";
        }
        if (IS_NODE_ALLOCATED($_)) {
            print STDERR "Slurm node is allocated... Node: ".$_->{name}."\n";
        }
        if (IS_NODE_ERROR($_)) {
            die "Slurm node is in error... Node: ".$_->{name}."\n";
        }
        if (IS_NODE_NO_RESPOND($_)) {
            die "Slurm node is not responding... Node: ".$_->{name}."\n";
        }
        if (IS_NODE_FAIL($_)) {
            die "Slurm node is failed... Node: ".$_->{name}."\n";
        }
        if (IS_NODE_COMPLETING($_)) {
            print STDERR "Slurm node is completing... Node: ".$_->{name}."\n";
        }
        if (IS_NODE_MIXED($_)) {
            print STDERR "Slurm node is mixed (some CPUs are allocated some are not)... Node: ".$_->{name}."\n";
        }
        if (IS_NODE_FUTURE($_)) {
            die "Slurm node is in future state (not fully configured)... Node: ".$_->{name}."\n";
        }
        if (IS_NODE_DRAIN($_)) {
            die "Slurm node is in drain... Node: ".$_->{name}."\n";
        }
        if (IS_NODE_DRAINING($_)) {
            print STDERR "Slurm node is draining... Node: ".$_->{name}."\n";
        }
        if (IS_NODE_DRAINED($_)) {
            print STDERR "Slurm node is drained... Node: ".$_->{name}."\n";
        }
        if (IS_NODE_MAINT($_)) {
            die "Slurm node is in maintenance... Node: ".$_->{name}."\n";
        }
        if (IS_NODE_POWER_UP($_)) {
            print STDERR "Slurm node is powered up... Node: ".$_->{name}."\n";
        }
        if (IS_NODE_POWER_SAVE($_)) {
            print STDERR "Slurm node is in power save... Node: ".$_->{name}."\n";
        }
    }
    return;
}

