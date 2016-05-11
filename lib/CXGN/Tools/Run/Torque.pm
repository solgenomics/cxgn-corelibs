
package CXGN::Tools::Run::Torque;

use base 'CXGN::Tools::Run';

use Carp qw/ carp confess croak /;
use Data::Dumper;
use File::Slurp;

sub new { 
    my $class = shift;
    my @args = @_;

    return bless {}, $class;
}


sub _cluster_queue_jobs_count {
    my $cnt = scalar keys %{ shift->_global_qstat || {} };
    #print "jobs count: $cnt\n";
    return $cnt;
}

sub run_job {
    my ( $self, $cmd, $options ) = @_;

    $self->_command( $cmd ); #< store the command for use in error messages

    # set our job destination from configuration if running under the website
    if( defined $options->{queue} ) {
	$self->_jobdest($options->{queue});
    }
    
    if ( defined $options->{out_file}) { 
	$self->out_file($options->{out_file});
    }

    # TODO: change all SGN code to pass in queue =>, then remove this!
    elsif( defined $ENV{PROJECT_NAME} && $ENV{PROJECT_NAME} eq 'SGN' ) {
	require SGN::Context;
	if( my $q = SGN::Context->new->get_conf('web_cluster_queue') ) {
	    $self->_jobdest( $q );
	}
    }
    
    #check that qsub is actually in the path
    IPC::Cmd::can_run('qsub')
	or croak "qsub command not in path, cannot submit jobs to the cluster.  "
	."Maybe you need to install the torque package?";
    
  my $tempdir = $self->tempdir;
  $self->in_file
      and croak "in_file not supported by run_cluster";
  foreach my $acc ('out_file','err_file') {
      my $file = $self->$acc;
      $file = $self->$acc("$file"); #< stringify the argument

      croak "tempdir ".$self->tempdir." is not on /export/shared or /export/prod, but needs to be for cluster jobs.  Do you need to set a different temp_base?\n"
	unless $self->cluster_accessible($tempdir);

      croak "filehandle or non-stringifying out_file, err_file, or in_file not supported by run_cluster"
	  if $file =~ /^([\w:]+=)?[A-Z]+\(0x[\da-f]+\)$/;
      #print "file was $file\n";

    unless($self->cluster_accessible($file)) {
      if(index($file,$tempdir) != -1) {
		croak "tempdir ".$self->tempdir." is not on /data/shared or /data/prod, but needs to be for cluster jobs.  Do you need to set a different temp_base?\n";
      } else {
		croak "'$file' must be in a subdirectory of /data/shared or /data/prod in order to be accessible to all cluster nodes";
      }
    }
  }

  #check that our working directory, if set, is accessible from the cluster nodes
  if($self->_working_dir_isset) {
      $self->cluster_accessible($self->_working_dir)
      or croak "working directory '".$self->_working_dir."' is not a subdirectory of /data/shared or /data/prod, but should be in order to be accessible to the cluster nodes";
  }


  # if the cluster head node is currently is running more than
  # max_cluster_jobs jobs, don't overload it, block until the number
  # of jobs goes down.  prints a warning the first time in the run
  # that this happens
  $self->_wait_for_overloaded_cluster;

  ###submit the job with qsub in the form of a bash script that contains a perl script
  #we do this so we can use CXGN::Tools::Run to write
  my $working_dir = $self->_working_dir_isset ? "working_dir => '".$self->_working_dir."'," : '';
  my $cmd_string = do {
      local $Data::Dumper::Terse  = 1;
      local $Data::Dumper::Indent = 0;
      join ', ', map Dumper( "$_" ), @$cmd;
  };
  my $outfile = $self->out_file;
  my $errfile = $self->err_file;

    $cmd_string = <<EOSCRIPT;
#!/usr/bin/env perl

  # take PBS_O_* environment variables as our own, overriding local
  # node settings
  %ENV = ( %ENV,
	   map {
	       my \$orig = \$_;
	       if(s/PBS_O_//) {
		   \$_ => \$ENV{\$orig}
	       } else {
		   ()
	       }
	   }
	   keys \%ENV
          );

  CXGN::Tools::Run->run($cmd_string,
                        { out_file => '$outfile',
                          err_file => '$errfile',
                          existing_temp => '$tempdir',
                          $working_dir
                        });

EOSCRIPT



  # also, include a copy of this very module!
    $cmd_string .= read_file( "../cxgn-corelibs/lib/CXGN/Tools/Run.pm" );
  # disguise the ending EOF so that it passes through the file inclusion

    #print STDERR "running cmd_string:\n$cmd_string\n";
  #$self->dbp("cluster running command '$cmd_string'");
  my $cmd_temp_file = File::Temp->new( TEMPLATE =>
                                       File::Spec->catfile( File::Spec->tmpdir, 'cxgn-tools-run-cmd-temp-XXXXXX'), UNLINK => 0
                                     );
  $cmd_temp_file->print( $cmd_string );
  $cmd_temp_file->close;

  my $retry_count;
  my $qsub_retry_limit = 3; #< try 3 times to submit the job
  my $submit_success;
  until( ($submit_success = $self->_submit_cluster_job( $cmd_temp_file )) || ++$retry_count > $qsub_retry_limit ) {
      sleep 1;
      warn "CXGN::Tools::Run retrying cluster job submission.\n";
  }
  $submit_success or die "CXGN::Tools::Run: failed to submit cluster job, after $retry_count tries\n";

  $self->_die_if_error;

  return $self->_jobid();
}

sub _submit_cluster_job {
    my ($self, $cmd_temp_file) = @_;

    print STDERR "Submitting cluster job to torque...\n";

    my %resources = (
        ppn => $self->_procs_per_node || undef,
        nodes => $self->_nodes        || 1,
        vmem  => $self->_vmem         || undef,
       );
    my $resource_str = $self->_make_torque_resource_string(\%resources);

    #note that you can use a reference to a string as a filehandle, which is done here:

    print STDERR "COMMAND TEMP FILE = ".$cmd_temp_file."\n";
    my $qsub_cmd = join( ' ',
                         #my $qsub = CXGN::Tools::Run->run(
                         #dprinta(
			     "qsub",
			     #'-V',
			     #-r => 'n', #< not rerunnable, cause we'll notice it died
			     -o => '/dev/null',
			     #-e => $self->err_file,
			     -N => 'cluster_job', ###$self->_job_name,
			     #( $self->_working_dir_isset ? (-d => $self->working_dir)
			     #     : ()
			     #   ),
			     #( $self->_jobdest_isset ? (-q => $self->_jobdest)
			     #   : ()
			     # ),
			     -l => $resource_str,
			     $cmd_temp_file->filename(),
			     #{ in_file  => \$cmd_string,
			      # out_file => $self->out_file,
			     #}
	                    #)
	);
    print STDERR "running '$qsub_cmd'\n";
    print STDERR "COMMAND FILE: ".$cmd_temp_file->filename()."\n";
    #print STDERR read_file($cmd_temp_file->filename());
    my $jobid = `$qsub_cmd 2>&1`; #< string to hold the job ID of this job submission
    print STDERR "Received JOB ID of $jobid\n";
    # test hook for testing a qsub failure, makes the test fail the first time
    if( $ENV{CXGN_TOOLS_RUN_FORCE_QSUB_FAILURE} ) {
        $jobid = $ENV{CXGN_TOOLS_RUN_FORCE_QSUB_FAILURE};
        delete $ENV{CXGN_TOOLS_RUN_FORCE_QSUB_FAILURE};
    }

    $self->_flush_qstat_cache;  #< force a qstat update

    #check that we got a sane job id
    chomp $jobid;
    unless( $jobid =~ /^\d+(\.[a-zA-Z0-9-]+)+$/ || $jobid =~ /Submitted batch job (\d+)/ ) {
        warn "CXGN::Tools::Run error running `qsub`: $jobid\n";
        return;
    }

    if ($jobid =~ /Submitted batch job (\d+)/) { 
	$jobid = $1;
    }

    print STDERR "got jobid $jobid\n";


    $self->_jobid($jobid);      #< remember our job id

    return 1;
}


sub _make_torque_resource_string {
    my ($self, $r) = @_;
    my %r = %$r;

    # tweak nodes=
    my $ppn = delete $r{ppn};
    $r{nodes} .= ":ppn=$ppn" if $ppn;

    # tweak vmem=
    $r{vmem}  .= 'm' if defined $r{vmem};

    my $s = join ',',           #< joined by commas
        map {"$_=$r{$_}"}       #< print it as type=value
            grep defined $r{$_}, #< don't print any that are undef
                sort            #< in stable sorted order
                    keys %r;    #< for each resource type

    return $s;
}



=head2 run_cluster_perl

  Usage: my $job = CXGN::Tools::Run->run_cluster_perl({ args => see below })

  Desc : Like run_cluster, but calls a perl class method on a cluster
         node with the given args.  The method args can be anything
         that Storable can serialize.  The actual job launched on the
         node is something like:
            perl -M$class -e '$class->$method_name(@args)'

         where the @args are exactly what you pass in method_args.

  Args : {  method        => [ Class::Name => 'method_to_run' ],
            args          => arrayref of the method's arguments (can
                             be objects, datastructures, whatever),

            (optional)
            run_opts      => hashref of CXGN::Tools::Run options (see
                             run_cluster() above),
            load_packages => arrayref of perl packages to
                             require before deserializing the arguments,
            perl          => string or arrayref specifying how to invoke
                             perl on the remote node, defaults to
                             [ '/usr/bin/env', 'perl' ]
         }
  Ret  : a job object, same as run_cluster

=cut


sub _run_cluster_perl_test { print 'a string for use by the test suite ('.join(',',@_).')' }


# if the cluster head node is currently is running more than
# max_cluster_jobs jobs, don't overload it, block until the number
# of jobs goes down.  prints a warning the first time in the run
# that this happens
{ my $already_warned;
  sub _wait_for_overloaded_cluster {
      my $self = shift;
      if ( $self->_max_cluster_jobs && $self->_cluster_queue_jobs_count >= $self->_max_cluster_jobs ) {

	  # warn the first time the cluster-full condition is encountered
	  unless( $already_warned++ ) {
	      carp __PACKAGE__.": WARNING: cluster queue contains more than "
		  .$self->_max_cluster_jobs
		      ." (max_cluster_jobs) jobs, throttling job submissions\n";
	  }

	  sleep int rand 120 while $self->_cluster_queue_jobs_count >= $self->_max_cluster_jobs;
      }
  }
}


sub _qstat {
    my ($self) = @_;
    
    my $jobs = $self->_global_qstat;
    #print STDERR "_QSTAT JOB ID: ".($self->_jobid())."\n";
    my $status = $jobs->{$self->_jobid};
    print STDERR "_QSTAT STATUS: ".Dumper($status)."\n";
    return $status || {};
}

#keep a cached copy of the qstat results, updated at most every MIN_QSTAT_WAIT
#seconds, to avoid pestering the server too much

use constant MIN_QSTAT_WAIT => 3;
{
    my $jobstate;
    my $last_qstat_time;
    sub _flush_qstat_cache {
	$last_qstat_time = 0;
    }
    sub _global_qstat {
	my ($self,%opt) = @_;

	#return our cached job state if it has been updated recently
	unless( defined($last_qstat_time) && (time()-$last_qstat_time) <= MIN_QSTAT_WAIT ) {
	    #otherwise, update it and return it
	    $jobstate = {};
	    my $servername = $self->_jobdest_isset ? $self->_jobdest : '';
	    $servername =~ s/^[^@]+//;
	    #    warn "using server name $servername\n";

	    open my $qstat, "qstat -f $servername 2>&1 |";
	    my $current_jobid;
	    while (my $qs = <$qstat>) {
		#print STDERR "got qstat record:\n$qs";
		if ($qs =~ /\s*Job\s+Id\s*:\s*(\S+)/i) {
		    print STDERR "CURRENT JOB ID = $1\n";
		    $current_jobid = $1;
		} elsif ( my ($key,$val) = $qs =~ /^\s*([^=\s]+)\s*=\s*(\S+)/ ) {
		    next if $key =~ /[=:]/;
		    $jobstate->{$current_jobid}->{lc($key)} = lc $val;
		} elsif ( $qs =~ /qstat: (.+)/ ) { #< probably some kind of error
		    if( $opt{no_recurse} ) {
			warn $qs;
			warn $_ while <$qstat>;
			return {};
		    } else {
			sleep 3;	#< wait a bit and try a second time
			return $self->_global_qstat( no_recurse => 1 );
		    }
		}
	    }
	    $last_qstat_time = time();
	    #      use Data::Dumper;
	    #      warn "qstat hash is now: ".Dumper($jobstate);
	}

	#print STDERR "GLOBAL JOB STATE: ".Dumper($jobstate);

	return $jobstate;
    }
}

sub _die_if_error {
    print STDERR "Checking if it has to die...\n";
    my $self = shift;
    if($self->_diefile_exists) {
	my $error_string = $self->_file_contents( $self->_diefile_name );
	if( $self->is_cluster ) {
	    # if it's a cluster job, look for warnings from the resource
	    # manager in the error file and include those in the error output
	    my $pbs_warnings = '';
	    if( -f $self->err_file ) {
		eval {
		    open my $e, $self->err_file or die "WARNING: $! opening err file ".$self->err_file;
		    while( <$e> ) {
			next unless m|^\=\>\> PBS:|;
			$pbs_warnings .= $_;
		    }
		    $pbs_warnings = __PACKAGE__.": resource manager output:\n$pbs_warnings" if $pbs_warnings;
		};
		$pbs_warnings .= $@ if $@;
	    }
	    # and also prepend the cluster job ID to aid troubleshooting
	    my $jobid = $self->job_id;
	    $error_string =  __PACKAGE__.": cluster job id: $jobid\n"
		. $pbs_warnings
		. $error_string
		. '==== '.__PACKAGE__." running qstat -f on this job ===========\n"
		. `qstat -f '$jobid'`
		. '==== '.__PACKAGE__." end qstat output =======================\n"
	}
    #kill our child process's whole group if it's still running for some reason
	kill SIGKILL => -($self->pid) if $self->is_async;
	$self->_error_string($error_string);
	if($self->_raise_error && !($self->_told_to_die && $error_string =~ /Got signal SIG(INT|QUIT|TERM)/)) {
	    croak($error_string || 'subprocess died, but returned no error string');
	}
    }
    print STDERR "All seems good!\n";
}

sub _diefile_exists {
  my ($self) = @_;
    #have to do the opendir dance instead of caching, because NFS caches the stats
    opendir my $tempdir, $self->tempdir
        or return 0;
    while(my $f = readdir $tempdir) {
      #dbp "is '$f' my diefile?\n";
      return 1 if $f eq 'died';
    }
    return 0;
}

=head2 alive

  Usage: print "It's still there" if $runner->alive;
  Desc : check whether our background process is still alive
  Ret  : false if it's not still running or was synchronous,
         true if it's async or cluster and is still running.
         Additionally, if it's a cluster job, the true value
         returned will be either 'ending', 'running' or 'queued'.
  Args : none
  Side Effects: dies if our background process terminated abnormally

=cut

sub alive {
    my ($self) = @_;

    $self->_die_if_error; #if our child died, we should die too
    
    #use qstat to see if the job is still alive
    my %m = qw| e ending r running q queued u unknown c complete|;

    #print STDERR "qstat output: ".Dumper($self->_qstat);

    my $state = $m{ $self->_qstat->{job_state}} || '';

    print STDERR "Detected job ".$self->_jobid().", state $state... (from ".$self->_qstat->{job_state}.")\n";

    $self->_run_completion_hooks if ($state eq 'complete') || $self->_told_to_die;
    
    if ($state ne 'complete') { 
	print STDERR "JOB IN PROGRESS! ($state)\n";
	return $state; 
    }
    
    $self->_die_if_error; #if our child died, we should die too
    print STDERR "JOB COMPLETION DETECTED! ($state)\n";
    return;
}


sub _run_completion_hooks {
    my $self = shift;

    $self->_die_if_error; #if our child died, we should die too, not run the completion hooks

    print STDERR "running job completion hook\n";

    #skip if we have no completion hooks or we have already run them
    return unless $self->_on_completion && ! $self->_already_ran_completion_hooks;

    #run the hooks
    $_->($self,@_) for @{ $self->_on_completion };

    #set flag saying we have run them
    $self->_already_ran_completion_hooks(1);
}

sub out {
    my ($self) = @_;
	print STDERR "Outfile is ",$self->out_file,"\n";
    unless(ref($self->out_file)) {

	return read_file($self->out_file);
    }
#    return undef;
}

sub cancel { 
    my $self = shift;
    
    print STDERR "Cancelling cluster job using qdel ".$self->_jobid()."... ";
    system("qdel", $self->_jobid());
    print STDERR "Done. \n";

}
1;
