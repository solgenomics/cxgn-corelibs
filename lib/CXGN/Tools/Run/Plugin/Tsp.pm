package CXGN::Tools::Run::Plugin::Tsp;

=head1 NAME

CXGN::Tools::Run::Plugin::Tsp - CXGN::Tools::Run backend using task-spooler (tsp), with optional podman job containers

=head1 SYNOPSIS

  my $job = CXGN::Tools::Run->new({ backend => 'Tsp', temp_base => $dir });
  $job->run_cluster($cmd);
  while ($job->alive()) { sleep 1; }

=head1 DESCRIPTION

Drop-in replacement for the Slurm plugin on a single host. Jobs are
queued with tsp; see CXGN::Tools::Run::Tsp for the configuration
(environment variables) that makes each job run in its own podman
container.

The tsp job id is stored in cluster_job_id(). The tsp job label and the
podman container name are "bbjob-" followed by the CXGN::Tools::Run jobid.

=cut

use Moose::Role;

use Carp qw | croak |;
use Cwd;
use File::Slurp qw | read_file write_file |;
use File::Spec;
use CXGN::Tools::Run::Tsp;

sub job_label {
    my $self = shift;
    return 'bbjob-'.$self->jobid();
}

sub check_job {
    my $self = shift;

    IPC::Cmd::can_run('tsp')
	or croak "tsp command not in path, cannot submit jobs. Maybe you need to install the task-spooler package?";

    if (CXGN::Tools::Run::Tsp::podman_url()) {
	IPC::Cmd::can_run('podman')
	    or croak "a podman URL is configured, but the podman command is not in path";
    }

    $self->in_file()
	and croak "in_file not supported by run_cluster";

    foreach my $acc ('out_file','err_file') {
	my $file = $self->$acc;
	croak "filehandle or non-stringifying out_file or err_file not supported by run_cluster"
	    if $file && "$file" =~ /^([\w:]+=)?[A-Z]+\(0x[\da-f]+\)$/;
    }
}

sub run_job {
    my ( $self, @cmd ) = @_;

    $self->check_job();
    $self->command(\@cmd); #< store the command for use in error messages

    my $tempdir = $self->job_tempdir();
    if (! $self->out_file()) { $self->out_file(File::Spec->catfile($tempdir, 'out')); }
    if (! $self->err_file()) { $self->err_file(File::Spec->catfile($tempdir, 'err')); }

    my $workdir = getcwd();
    my $cmd_string = "#!/bin/bash\n\n";
    $cmd_string .= "cd '$workdir' || exit 1\n" if $workdir;
    # group the command so that the redirections apply to all of it, not just its last part
    $cmd_string .= "{\n".join(" ", @cmd)."\n} > ".$self->out_file()." 2> ".$self->err_file()."\n";

    my $cmd_temp_file = File::Spec->catfile($tempdir, 'cmd');
    write_file($cmd_temp_file, $cmd_string);
    CXGN::Tools::Run::Tsp::prepare_job_dir($tempdir, $cmd_temp_file);

    my $id = CXGN::Tools::Run::Tsp::submit($self->job_label(), $cmd_temp_file, $workdir);
    $self->cluster_job_id($id);

    $self->store_job_data();
    return $self->jobid();
}

sub alive {
    my $self = shift;

    my $state = CXGN::Tools::Run::Tsp::job_state($self->cluster_job_id(), $self->job_label());

    if ($state->{state} eq 'queued' || $state->{state} eq 'running') {
	return $state->{state};
    }

    if ($state->{state} eq 'unknown') {
	# tsp no longer knows the job (tsp server restarted, or the job was
	# dropped from its list of finished jobs).
	print STDERR "CXGN::Tools::Run::Plugin::Tsp: tsp has no record of job ".$self->cluster_job_id()." (".$self->job_label().")\n";
    }
    elsif (defined($state->{signal})) {
	$self->_write_tsp_die("tsp job ".$self->cluster_job_id()." was killed by signal $state->{signal}");
    }
    elsif ($state->{exit}) {
	$self->_write_tsp_die("tsp job ".$self->cluster_job_id()." exited with status $state->{exit}");
    }

    $self->_die_if_error;
    return;
}

sub _write_tsp_die {
    my ($self, $message) = @_;

    return if $self->_diefile_exists;
    my $err = (-f $self->err_file()) ? read_file($self->err_file()) : '';
    write_file($self->_diefile_name(), "$message\n$err");
}

sub _die_if_error {
    my $self = shift;

    if ($self->_diefile_exists) {
	my $error_string = __PACKAGE__.": tsp job id: ".($self->cluster_job_id() // '')."\n"
	    . $self->_file_contents( $self->_diefile_name );
	$self->_error_string($error_string);
	if ($self->_raise_error && !$self->_told_to_die) {
	    croak($error_string);
	}
    }
}

sub _cluster_queue_jobs_count {
    return CXGN::Tools::Run::Tsp::queue_length();
}

sub _check_nodes_states { return; }

sub _flush_qstat_cache { return; }

sub _global_qstat { return {}; }

sub out {
    my ($self) = @_;
    unless(ref($self->out_file)) {
	return read_file($self->out_file);
    }
}

sub cancel {
    my $self = shift;

    # record the cancellation first, so that alive() does not report the
    # resulting non-zero exit (or signal) as a job failure
    $self->_told_to_die(1);
    $self->_write_tsp_die("tsp job ".$self->cluster_job_id()." was cancelled");
    CXGN::Tools::Run::Tsp::cancel($self->cluster_job_id(), $self->job_label());
}

1;
