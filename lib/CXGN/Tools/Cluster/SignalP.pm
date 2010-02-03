package CXGN::Tools::Cluster::SignalP;
use strict;
use base qw/CXGN::Tools::Cluster/;

use CXGN::Tools::Run;
use Bio::SeqIO;
use File::Temp qw/tempdir/;
use constant DEBUG=>$ENV{CLUSTER_DEBUG};
$| = 1;

=head1 NAME

 CXGN::Tools::Cluster::SignalP

=head1 SYNOPSIS

 Break up a large Fasta protein file into bite-size chunks, run
 SignalP on the chunks, glue results together

=head1 USAGE

 my $proc = CXGN::Tools::Cluster::SignalP->new({
               in => $fp_to_fasta
               out => $fp_result
             });  
 $proc->submit();
 $proc->spin();
 $proc->concat();
 #Yay!

=head1 Subclass Notes

 new() requires hash_ref with "in" and "out" arguments, otherwise fails
 
 submit() will break up the file into little chunks and submit the jobs
 
 spin() is standard, just pauses the program till all jobs are done
 
 concat() will take all the result pieces and glue them back together,
          without the comment lines on all but the first piece

=cut

sub new {
	my $class = shift;
	my $args = shift;
	my $self = $class->SUPER::new($args);

	die "No valid filepath provided for input" 
		unless (-f $self->infile );

	my $outfile = $self->outfile();
	my $out_default = "SignalPCluster.job.out";
	unless($outfile){
		print STDERR "\nWARNING: No outfile provided, using default: $out_default";
		print STDERR "\nPress any key to confirm or <ctrl-c> to cancel";
		<STDIN>;
	}	
	$outfile ||= $out_default;
	$self->outfile($outfile);

	#Create Temporary Directory for job files and stuff
	my $tempdir = tempdir('signalp-XXXXXXXX',
							DIR => $self->{tmp_base},
							CLEANUP => !DEBUG)
		or die "\nCould not create temporary directory: $!\n";
	system "chmod a+rwx $tempdir";

	print STDERR "\nTemporary Directory: $tempdir" if DEBUG;
	$self->temp_dir($tempdir);

	return $self;
}

sub submit {
	my $self = shift;
	my $filepath = $self->infile();
	print STDERR "\nFilepath: $filepath" if DEBUG;
	my ($linecount) = `grep '^\\s*>' $filepath | wc -l`;
	my ($total_size) = $linecount =~ /(\d+)/;

 	die "\nThere appear to be no sequences in the provided FASTA file\n"
 		unless $total_size;

	print STDERR "\n$total_size sequences found in total" if DEBUG;

	my @seqsizes = $self->job_sizes($total_size, 20, 1000); #Min pieces: 20, Max Piece Size: 1000

	my @in_files = ();
	my @out_files = ();
	my @jobs = ();
	
	print STDERR "\nSplitting file into even pieces and submitting jobs";
	my $in = Bio::SeqIO->new(-file => $filepath, -format => 'fasta');

	foreach my $piece_size (@seqsizes){
		my $in_file = File::Temp->new(
						TEMPLATE => "signalp-in-XXXXXX", 
						DIR => $self->temp_dir(), 
						UNLINK => 0 )
			or die "\nCould not create infile: $!\n";
		my $out_file = File::Temp->new(
						TEMPLATE => "signalp-out-XXXXXX", 
						DIR => $self->temp_dir(),
						UNLINK => 0 )
			or die "\nCould not create outfile: $!\n";

		push(@out_files, $out_file->filename);
		push(@in_files, $in_file->filename);
			
		my $i = 1;
		while($i <= $piece_size){
			my $seq = $in->next_seq();
			my ($id, $seq) = ($seq->id(), $seq->seq());
			$seq = substr($seq, 0, 60);
			print $in_file ">$id\n$seq\n";
			$i++;
		}
		
		$self->chill();

		my $job = CXGN::Tools::Run->run_cluster( 
				"/data/shared/bin/signalp",
				-t => "euk",
				-f => "short",
				$in_file->filename,
				{	
					out_file => $out_file->filename,
					working_dir => $self->{temp_dir},
					temp_base => $self->{temp_dir},
					queue => 'batch@' . $self->cluster_host(),
				}
		);
		print STDERR ".";
		push(@jobs, $job);
	}

	$self->jobs(\@jobs);
	$self->cluster_outs(\@out_files);
}

sub concat {
	#Want my own concat function for this module so that we 
	#don't have pesky repeated comment lines
	
	my $self = shift;
	my $outfiles = $self->cluster_outs();
	open(WF, ">" . $self->outfile())
		or die "\nCan't open final write file: $!";
	my $firstfile = 1;
	print STDERR "\nConcatenating cluster outputs to final file";
	foreach(@$outfiles){
		open(RF, $_);
		while(<RF>){
			print WF $_ unless(/^\s*#/ && !$firstfile);
		}
		$firstfile = 0;
		close(RF);
		print STDERR ".";
	}
	print STDERR "\n";
	close(WF);
}

1;
