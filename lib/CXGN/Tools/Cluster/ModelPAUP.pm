package CXGN::Tools::Cluster::ModelPAUP;
use strict;
use base qw/CXGN::Tools::Cluster/;

use CXGN::Tools::Run;
use File::Temp qw/tempdir/;
use File::Basename;
use constant DEBUG=>$ENV{CLUSTER_DEBUG};

=head1 NAME

 CXGN::Tools::Cluster::ModelPAUP

=head1 SYNOPSIS

 Run Modeltest and PAUP* on one or many CDS-overlap .nex files,
 and get a tree in .nex format.  Very intense stuff, error-prone,
 be warned.

=head1 USAGE

 my $proc = CXGN::Tools::Cluster::ModelPAUP->new();
 while(yadda){
      .....
      $proc->submit($nex_in, $result_tree_out);
 }
 $proc->spin();
 #Yay!

=head1 Subclass Notes
 
 submit() requires two arguments, input .nex specifying cds overlap,
          and output file to hold tree.
 alive() calls write_result() when job no longer alive, which writes
         the tree file to a result file, and also a log file to 
         <result_file_name>.log

=cut

sub new {
	my $class = shift;
	my $args = shift;
	my $self = $class->SUPER::new($args);

	die "\nSend input file to submit(), not constructor\n" if $self->infile();
	die "\nOutput files produced by finish(), specified automatically in submit(), not in constructor\n" if $self->outfile();

	my $temp_dir = tempdir('modelpaup-XXXXXXX',
							DIR => $self->{tmp_base},
							CLEANUP => !DEBUG)
		or die "\nCould not produce temporary directory: $!\n";
	system "chmod a+rwx $temp_dir";

	print STDERR "\nTemporary Directory: $temp_dir\n" if DEBUG;
		
	$self->temp_dir($temp_dir);
	return $self;
}	

sub submit {
	my $self = shift;

	$self->chill(); #don't submit jobs too quickly

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

	#print STDERR "\nFilepath: $infile" if DEBUG;

	system("cp $infile " . $self->temp_dir());
	die("Couldn't copy infile: $?") if $?;

	my $cluster_in = File::Basename::basename($infile);


	my $job = CXGN::Tools::Run->run_cluster( 
				"/data/shared/bin/modelpaup_unrooted.pl",
				$cluster_in,
				{
					out_file => $self->temp_dir() . "/" . $cluster_in . ".out",
					err_file => $self->temp_dir() . "/" . $cluster_in . ".err",
					working_dir => $self->temp_dir(),
					temp_base => $self->temp_dir(),
					queue => 'batch@' . $self->cluster_host(),
				}
			);

	print STDERR "JobId: " . $job->job_id();
	print STDERR "  Already Dead!" unless $job->alive();
	print STDERR "\n";
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

	my $wd = `pwd`;
	chomp $wd;
	print STDERR "\nWorking directory: $wd";
	my ($base) = $name_in =~ /(.*)\.nex/;
	my $tree_file = $self->{temp_dir} . "/paup/$base.ml.tre";
	my $log_file = $self->{temp_dir} . "/paup/$base.log";
	print STDERR "\nFilename: " . $name_in ."\n" if DEBUG;
	system "cp $log_file $result_file.log";
	print STDERR "Problem copying to log file: $?\n" if ($?);
	system "cp $tree_file $result_file";
	print STDERR "Problem copying to result file: $?\n" if ($?);
	print STDERR "Output written to file: $result_file\n" unless ($?);
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
		print STDERR "JOB DIED: $@\n" if $@;
		$running = 1 if $alive;
		if(!$alive){
			$self->write_result($job) unless $job->property("final_written");
		}
	}
	return $running;
}

sub number_of_jobs_alive {
	my $self = shift;
	my $jobs_array = $self->jobs();
	my $living = 0;
	foreach(@$jobs_array){
		my $alive = 0;
		eval { $alive = $_->alive() };
		$living++ if $alive;
	}
	return $living;
}


1;
