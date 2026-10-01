package CXGN::Tools::Run::Tsp;

=head1 NAME

CXGN::Tools::Run::Tsp - helper functions for running jobs with task-spooler (tsp), optionally inside podman containers

=head1 SYNOPSIS

  use CXGN::Tools::Run::Tsp;

  my $id = CXGN::Tools::Run::Tsp::submit($label, $cmd_file, $workdir);
  my $state = CXGN::Tools::Run::Tsp::job_state($id, $label);
  # $state->{state} is one of queued, running, finished, unknown
  # $state->{exit} is the exit code once finished (undef if killed)
  CXGN::Tools::Run::Tsp::cancel($id, $label);

=head1 DESCRIPTION

Used by CXGN::Tools::Run::Plugin::Tsp and CXGN::Job as a replacement for
Slurm on a single host. tsp provides the queue (number of concurrent
jobs, job ids, state, exit codes). If a podman URL is configured, each
job runs in its own container through the podman API (the host's
rootful podman socket mounted into the breedbase container);
otherwise jobs run directly in the tsp server's container.

Configuration is read from the environment so that it is the same for
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
  BB_JOB_HOST_UID          if set, job directories are chowned to this uid
                           before submission (only useful with rootless podman,
                           which maps container root to this host uid)
  BB_JOB_PODMAN_ARGS       extra arguments for podman run, e.g. "--memory 8g"

=cut

use strict;
use warnings;

use Carp qw | croak |;
use IPC::Cmd;
use Socket qw | inet_ntoa |;

our $DEFAULT_IMAGE = 'docker.io/breedbase/breedbase:latest';

sub podman_url {
    return $ENV{BB_JOB_PODMAN_URL} || '';
}

=head2 podman_command()

The podman client command for the configured URL, as a list: podman-remote
(Debian package podman-remote) if installed, otherwise podman --remote.

=cut

sub podman_command {
    my $url = podman_url();
    if (IPC::Cmd::can_run('podman-remote')) {
        return ('podman-remote', '--url', $url);
    }
    return ('podman', '--remote', '--url', $url);
}

=head2 runner_command($label, $cmd_file, $workdir)

Returns the command (as a list) that tsp should run for a job script:
either bash directly, or podman run with the configured image, mounts
and hosts.

=cut

sub runner_command {
    my ($label, $cmd_file, $workdir) = @_;

    my $url = podman_url();
    if (!$url) {
        return ('/bin/bash', $cmd_file);
    }

    my @cmd = (podman_command(), 'run', '--rm', '--init',
               "--name=$label", '--network=host', '--entrypoint', '/bin/bash');

    foreach my $host (split /\s+/, $ENV{BB_JOB_ADD_HOSTS} // 'breedbase_db') {
        next unless $host;
        my $packed = gethostbyname($host);
        if (!$packed) {
            warn "CXGN::Tools::Run::Tsp: could not resolve $host, not passing it to the job container\n";
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

=head2 submit($label, $cmd_file, $workdir)

Queues the job script with tsp and returns the tsp job id.

=cut

sub submit {
    my ($label, $cmd_file, $workdir) = @_;

    my @runner = runner_command($label, $cmd_file, $workdir);
    print STDERR "CXGN::Tools::Run::Tsp: submitting [$label] ".join(" ", @runner)."\n";

    open(my $ts, '-|', 'tsp', '-L', $label, @runner)
        or croak "CXGN::Tools::Run::Tsp: could not run tsp: $!";
    my $id = <$ts>;
    close($ts);

    chomp($id) if defined($id);
    if (!defined($id) || $id !~ /^\d+$/) {
        croak "CXGN::Tools::Run::Tsp: tsp did not return a job id (got '".($id // '')."')";
    }
    return $id;
}

=head2 job_state($id, $label)

Returns a hashref with the state of tsp job $id: state (queued, running,
finished or unknown), exit (exit code, if finished normally) and signal
(signal number, if killed). If $label is given and the tsp job with that
id has a different label (for example because the tsp server was
restarted and job ids started over), the state is unknown.

=cut

sub job_state {
    my ($id, $label) = @_;

    my %state = (state => 'unknown', exit => undef, signal => undef);
    return \%state unless defined($id) && $id =~ /^\d+$/;

    my ($line) = grep { /^\Q$id\E\s/ } `tsp -l 2>/dev/null`;
    return \%state unless $line;

    my ($tsp_state) = $line =~ /^\d+\s+(\S+)/;
    my ($tsp_label) = $line =~ /\s\[([^\]]*)\]/;
    if (defined($label) && (!defined($tsp_label) || $tsp_label ne $label)) {
        return \%state;
    }

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

=head2 cancel($id, $label)

Removes a queued job, or kills a running one. For podman jobs, also stops
the job container, since killing the podman client does not always stop
the container.

=cut

sub cancel {
    my ($id, $label) = @_;

    my $state = job_state($id, $label);
    if ($state->{state} eq 'queued') {
        system('tsp', '-r', $id);
    }
    elsif ($state->{state} eq 'running') {
        system('tsp', '-k', $id);
    }

    if (podman_url() && $label) {
        system(join(' ', map { "'$_'" } podman_command(), 'stop', '-i', '-t', '10', $label).' >/dev/null 2>&1');
    }
}

=head2 queue_length()

Number of queued and running tsp jobs.

=cut

sub queue_length {
    return scalar(grep { /^\d+\s+(queued|running|allocating)\s/ } `tsp -l 2>/dev/null`);
}

=head2 prepare_job_dir($dir, @files)

If BB_JOB_HOST_UID is set, chowns the job directory and files to that uid,
so that rootless podman job containers can write to them.

=cut

sub prepare_job_dir {
    my @paths = @_;

    my $uid = $ENV{BB_JOB_HOST_UID};
    return unless defined($uid) && $uid =~ /^\d+$/ && podman_url();

    chown($uid, $uid, @paths) == scalar(@paths)
        or warn "CXGN::Tools::Run::Tsp: could not chown @paths to $uid: $!\n";
}

1;
