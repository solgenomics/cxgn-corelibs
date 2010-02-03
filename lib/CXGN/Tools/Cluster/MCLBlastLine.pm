package CXGN::Tools::Cluster::MCLBlastLine;
use strict;
use base qw/CXGN::Tools::Cluster/;

use CXGN::Tools::Run;
use File::Temp qw/tempdir/;
use File::Basename;
use constant DEBUG=>$ENV{CLUSTER_DEBUG};

=head1 NOT WORKING RIGHT NOW

 Sorry, there are issues.  You can work on this if you want,
 but there's not much of a reason to cluster MCL Blastline anyway,
 so I won't fix it, probably.

=cut

sub new {
	my $class = shift;
	my $args = shift;
	my $self = $class->SUPER::new($args);

	die "\nSend input file to submit(), not constructor\n" if $self->infile();
	die "\nOutput files produced by finish(), specified automatically in submit(), not in constructor\n" if $self->outfile();

	my $tol = $args->{tolerance};
	if($tol >= 1.1 || $tol <= 5.0){
		$self->{tolerance} = $tol;
	}
	else {
		$self->{tolerance} = 1.1;
	}

	my $temp_dir = tempdir('tribemcl-XXXXXXXXX',
							DIR => $self->{tmp_base},
							CLEANUP => !DEBUG)
		or die "\nCould not produce temporary directory: $!\n";
	system "chmod a+rwx $temp_dir";

	print STDERR "\nTemporary Directory: $temp_dir" if DEBUG;
		
	$self->temp_dir($temp_dir);
	return $self;
}	

sub submit {
	my $self = shift;

	$self->chill();

	my $infile = shift;
	my $result_file = shift;

	#At some point we change the working directory to run clmformat in the
	#temporary folder, so we keep track of the full path to the result file,
	#unless an absolute path has been given
	my ($wd) = `pwd`;
	chomp $wd;
	unless($result_file =~ /^\//){
		$result_file = $wd . "/" . $result_file;
	}

	die "\nNeed valid input file as first argument\n" unless (-f $infile);
	die "\nNeed destination file as second argument\n" unless $result_file;

	print STDERR "\nFilepath: $infile" if DEBUG;

	system("cp $infile " . $self->temp_dir());
	die("Couldn't copy infile: $?") if $?;

	my $cluster_in = File::Basename::basename($infile);


	my $cmd = "/data/shared/bin/mclpipeline --parser=/data/shared/bin/mcxdeblast --parser-tag=blast --ass-r=max --blast-m9 --mcl-I=" . $self->{tolerance}; 

	my $job = CXGN::Tools::Run->run_cluster( 
				$cmd . " " . $cluster_in,
				{
					working_dir => $self->{temp_dir},
					temp_base => $self->{temp_dir},
					queue => 'batch@' . $self->cluster_host(),
				}
			);
#	print "\n" . $cmd . " " . $cluster_in;
#	print "\n" . $self->temp_dir;
	$job->property("result_file", $result_file);
	$job->property("cluster_in", $cluster_in);
	$job->property("final_written", 0);
	
	$self->push_job($job);
}

sub write_result {
	my $self = shift;
	my $job = shift;
	my $result_file = $job->property("result_file");
	my $cluster_in = $job->property("cluster_in");
	
	my $name_in = File::Basename::basename($cluster_in);

	chdir $self->{temp_dir};

	my ($out) = `ls out.$name_in*`;
	chomp $out;
	my $tab = $name_in . ".tab";
	
	my $dump = $name_in . ".dump"; 

	die "No tab file: $tab" unless (-f $tab);
	die "No out file: $out" unless (-f $out);

	system "/data/shared/bin/clmformat -icl $out -dump $dump -tab $tab";
	
	print STDERR "\nProblem with clmformat: $?" if ($?);
	
	system "cp $dump $result_file";
	print STDERR "Problem copying to result file: $?" if ($?);

	print STDERR "\nOutput written to file: $result_file";
	$job->property("final_written", 1);	
}

sub alive {
	
	#alive() works very differently here than in parent class.  
	#Result files are written as soon as the job is no longer alive,
	#since there is no need to wait before all the jobs are done to
	#start getting results
	
	my $self = shift;
	my $job_array = $self->jobs();
	my $running = 0;
	foreach my $job (@$job_array){
		#The job will die for a zoem-related reason, which doesn't matter,
		#we don't want the whole process to die just because of that
		my $alive = 0;
		eval {
			$alive = $job->alive();
		};
		$alive = 0 if $@;
		$running = 1 if $alive;
		if(!$alive){
			$self->write_result($job) unless $job->property("final_written");
		}
	}
	return $running;
}

1;
