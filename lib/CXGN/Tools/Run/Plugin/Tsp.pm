package CXGN::Tools::Run::Plugin::Tsp;

=head1 NAME

CXGN::Tools::Run::Plugin::Tsp - CXGN::Tools::Run backend using task-spooler (tsp), with optional podman job containers

=head1 SYNOPSIS

  my $job = CXGN::Tools::Run->new({ backend => 'Tsp', temp_base => $dir });
  $job->run_cluster($cmd);
  while ($job->alive()) { sleep 1; }

=head1 DESCRIPTION

Replacement for the Slurm plugin on a single host. tsp provides the
queue (number of concurrent jobs, job ids, state, exit codes). If a
podman URL is configured, each job runs in its own container through the
podman API (the host's rootful podman socket mounted into the breedbase
container); otherwise jobs run directly in the tsp server's container.

The tsp job id is stored in cluster_job_id(). The tsp job label and the
podman container name are "bbjob-" followed by the CXGN::Tools::Run
jobid; the label is checked against tsp's job list, so that a restart of
the tsp server (which restarts job ids at 0) can't make an old job look
like a new one.

Configuration is read from the environment, so that it is the same for
the web server and the tsp server:

  TS_SOCKET                tsp socket (default: tsp's default)
  BB_JOB_PODMAN_URL        podman API URL, e.g. unix:///run/podman-host/podman.sock.
                           If not set, jobs run without podman. (CONTAINER_HOST
                           is deliberately not used: it may point to a rootless
                           podman, whose job containers can't write the
                           root-owned 0600 tempfiles the web server creates.)
  BB_JOB_IMAGE             image for job containers
                           (default docker.io/breedbase/breedbase:latest)
  BB_JOB_MOUNTS            whitespace-separated host_path:container_path[:options]
                           bind mounts for job containers. Host paths are
                           paths on the podman host, not in this container.
  BB_JOB_ADD_HOSTS         whitespace-separated host names to resolve here and
                           pass to job containers with --add-host
                           (default: breedbase_db)
  BB_JOB_PODMAN_ARGS       extra arguments for podman run, e.g. "--memory 8g"

=cut

use Moose::Role;

use Carp qw | croak |;
use Cwd;
use File::Slurp qw | read_file write_file |;
use File::Spec;
use IPC::Cmd;
use Socket qw | inet_ntoa |;

my $DEFAULT_IMAGE = 'docker.io/breedbase/breedbase:latest';

sub job_label {
    my $self = shift;
    return 'bbjob-'.$self->jobid();
}

sub check_job {
    my $self = shift;

    IPC::Cmd::can_run('tsp')
	or croak "tsp command not in path, cannot submit jobs. Maybe you need to install the task-spooler package?";

    if ($self->_podman_url()) {
	(IPC::Cmd::can_run('podman-remote') || IPC::Cmd::can_run('podman'))
	    or croak "a podman URL is configured, but neither podman-remote nor podman is in path";
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

    my @runner = $self->_runner_command($cmd_temp_file, $workdir);
    print STDERR __PACKAGE__.": submitting [".$self->job_label()."] ".join(" ", @runner)."\n";

    open(my $ts, '-|', 'tsp', '-L', $self->job_label(), @runner)
	or croak __PACKAGE__.": could not run tsp: $!";
    my $id = <$ts>;
    close($ts);

    chomp($id) if defined($id);
    if (!defined($id) || $id !~ /^\d+$/) {
	croak __PACKAGE__.": tsp did not return a job id (got '".($id // '')."')";
    }
    $self->cluster_job_id($id);

    $self->store_job_data();
    return $self->jobid();
}

sub alive {
    my $self = shift;

    my $state = $self->_tsp_state();

    if ($state->{state} eq 'queued' || $state->{state} eq 'running') {
	return $state->{state};
    }

    if ($state->{state} eq 'unknown') {
	# tsp no longer knows the job (tsp server restarted, or the job was
	# dropped from its list of finished jobs).
	print STDERR __PACKAGE__.": tsp has no record of job ".$self->cluster_job_id()." (".$self->job_label().")\n";
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

# see CXGN::Tools::Run::job_state()
sub job_state {
    my $self = shift;

    my $state = $self->_tsp_state();

    if ($state->{state} ne 'finished') {
	return ($state->{state}, "tsp: $state->{state}");
    }
    if ($self->_diefile_exists && $self->_file_contents($self->_diefile_name) =~ /was cancelled/) {
	return ('canceled', 'tsp: cancelled');
    }
    if (defined($state->{signal})) {
	return ('failed', "tsp: killed by signal $state->{signal}");
    }
    if (defined($state->{exit}) && $state->{exit} == 0) {
	return ('finished', 'tsp: exit code 0');
    }
    return ('failed', 'tsp: exit code '.($state->{exit} // 'unknown'));
}

sub cancel {
    my $self = shift;

    # record the cancellation first, so that alive() does not report the
    # resulting non-zero exit (or signal) as a job failure
    $self->_told_to_die(1);
    $self->_write_tsp_die("tsp job ".$self->cluster_job_id()." was cancelled");

    my $state = $self->_tsp_state();
    if ($state->{state} eq 'queued') {
	system('tsp', '-r', $self->cluster_job_id());
    }
    elsif ($state->{state} eq 'running') {
	system('tsp', '-k', $self->cluster_job_id());
    }

    # killing the podman client does not always stop the job container
    if ($self->_podman_url()) {
	system(join(' ', map { "'$_'" } $self->_podman_command(), 'stop', '-i', '-t', '10', $self->job_label()).' >/dev/null 2>&1');
    }
}

sub out {
    my ($self) = @_;
    unless(ref($self->out_file)) {
	return read_file($self->out_file);
    }
}

sub _cluster_queue_jobs_count {
    return scalar(grep { /^\d+\s+(queued|running|allocating)\s/ } `tsp -l 2>/dev/null`);
}

sub _check_nodes_states { return; }

sub _flush_qstat_cache { return; }

sub _global_qstat { return {}; }

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

sub _write_tsp_die {
    my ($self, $message) = @_;

    # the job directory may be gone when an old job is checked or cancelled
    return if !$self->job_tempdir() || ! -d $self->job_tempdir();
    return if $self->_diefile_exists;
    my $err = (-f $self->err_file()) ? read_file($self->err_file()) : '';
    write_file($self->_diefile_name(), "$message\n$err");
}

# tsp's record of this job: state (queued, running, finished or unknown),
# exit (exit code, if finished normally) and signal (if killed). The state
# is unknown if tsp has no job with this id and label.
sub _tsp_state {
    my $self = shift;

    my $id = $self->cluster_job_id();
    my %state = (state => 'unknown', exit => undef, signal => undef);
    return \%state unless defined($id) && $id =~ /^\d+$/;

    my ($line) = grep { /^\Q$id\E\s/ } `tsp -l 2>/dev/null`;
    return \%state unless $line;

    my ($tsp_state) = $line =~ /^\d+\s+(\S+)/;
    my ($tsp_label) = $line =~ /\s\[([^\]]*)\]/;
    return \%state if !defined($tsp_label) || $tsp_label ne $self->job_label();

    if ($tsp_state eq 'queued' || $tsp_state eq 'running' || $tsp_state eq 'allocating') {
	$state{state} = $tsp_state eq 'allocating' ? 'queued' : $tsp_state;
	return \%state;
    }

    $state{state} = 'finished';
    my $info = `tsp -i $id 2>/dev/null`;
    if ($info =~ /exit code (-?\d+)/) {
	$state{exit} = $1;
    }
    elsif ($info =~ /killed by signal (\d+)/) {
	$state{signal} = $1;
    }
    return \%state;
}

sub _podman_url {
    return $ENV{BB_JOB_PODMAN_URL} || '';
}

# podman-remote (Debian package podman-remote) if installed, otherwise podman --remote
sub _podman_command {
    my $self = shift;
    my $url = $self->_podman_url();
    if (IPC::Cmd::can_run('podman-remote')) {
	return ('podman-remote', '--url', $url);
    }
    return ('podman', '--remote', '--url', $url);
}

# the command tsp runs for the job script: bash directly, or podman run
# with the configured image, mounts and hosts
sub _runner_command {
    my ($self, $cmd_file, $workdir) = @_;

    if (!$self->_podman_url()) {
	return ('/bin/bash', $cmd_file);
    }

    my @cmd = ($self->_podman_command(), 'run', '--rm', '--init',
	       '--name='.$self->job_label(), '--network=host', '--entrypoint', '/bin/bash');

    foreach my $host (split /\s+/, $ENV{BB_JOB_ADD_HOSTS} // 'breedbase_db') {
	next unless $host;
	my $packed = gethostbyname($host);
	if (!$packed) {
	    warn __PACKAGE__.": could not resolve $host, not passing it to the job container\n";
	    next;
	}
	push @cmd, "--add-host=$host:".inet_ntoa($packed);
    }

    foreach my $mount (split /\s+/, $ENV{BB_JOB_MOUNTS} // '') {
	push @cmd, '-v', $mount if $mount;
    }

    push @cmd, split(/\s+/, $ENV{BB_JOB_PODMAN_ARGS}) if $ENV{BB_JOB_PODMAN_ARGS};
    push @cmd, '-w', $workdir if $workdir;
    push @cmd, ($ENV{BB_JOB_IMAGE} || $DEFAULT_IMAGE), $cmd_file;

    return @cmd;
}

1;
