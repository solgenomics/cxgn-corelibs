package CXGN::Tools::Cluster::Muscle;
use strict;
use base qw/CXGN::Tools::Cluster/;

use CXGN::Tools::Run;
use File::Temp qw/tempdir/;
use File::Basename;
use constant DEBUG => $ENV{CLUSTER_DEBUG};

=head1 NAME

 CXGN::Tools::Cluster::Muscle

=head1 SYNOPSIS

 Submit Muscle (Sequence Alignment) jobs to the cluster like nobody's business

=head1 USAGE

 my $proc = CXGN::Tools::Cluster::Muscle->new({ maxiters => 1000 });
 
 while(yadda) { 
    .....
    $proc->submit($fasta_in_fp, $result_out_fp) 
 }
 
 $proc->spin();
 #Yay!


=head1 Subclass Notes

 new() takes one optional hashref param: maxiters, the maximum iterations to run on an alignment

 submit() needs two filepath arguments, the input fasta, and the result file

 alive() is subclassed [called within spin()], writes result when job is no longer alive

=cut

sub new {
    my $class = shift;
    my $args  = shift;
    my $self  = $class->SUPER::new($args);

    die "\nSend input file to submit(), not constructor\n" if $self->infile();
    die
"\nOutput files produced by finish(), specified automatically in submit(), not in constructor\n"
      if $self->outfile();

    $self->{maxiters} = 10000;
    $self->{maxiters} = $args->{maxiters} if $args->{maxiters};

    my $temp_dir = tempdir(
        'muscle-XXXXXXXXX',
        DIR     => $self->{tmp_base},
        CLEANUP => !DEBUG
    ) or die "\nCould not produce temporary directory: $!\n";
    system "chmod a+rwx $temp_dir";

    print STDERR "\nTemporary Directory: $temp_dir" if DEBUG;

    $self->temp_dir($temp_dir);
    return $self;
}

sub submit {
    my $self        = shift;
    my $infile      = shift;
    my $result_file = shift;

    die "\nNeed valid input file as first argument\n"  unless ( -f $infile );
    die "\nNeed destination file as second argument\n" unless $result_file;

    $self->chill();

    print STDERR "\nInput filepath: $infile" if DEBUG;

    my $temp_in = File::Temp->new(
        TEMPLATE => "muscle-in-XXXXXXXX",
        DIR      => $self->temp_dir(),
        UNLINK   => 0
    );
    system( "cp $infile " . $temp_in->filename );
    die "\nProblem copying file: $?" if ($?);

    my $outfile = File::Temp->new(
        TEMPLATE => "muscle-out-XXXXXXXX",
        DIR      => $self->temp_dir(),
        UNLINK   => 0
    );

    my $job = CXGN::Tools::Run->run_cluster(
        "muscle",
        -in       => $temp_in->filename(),
        -out      => $outfile->filename(),
        -maxiters => $self->{maxiters},
        {
            working_dir => $self->{temp_dir},
            temp_base   => $self->{temp_dir},
            queue       => 'batch@' . $self->cluster_host(),
        }
    );

    $job->property( "result_file",   $result_file );
    $job->property( "out_file",      $outfile->filename );
    $job->property( "final_written", 0 );

    $self->push_job($job);
}

sub write_result {
    my $self        = shift;
    my $job         = shift;
    my $result_file = $job->property("result_file");
    my $cluster_out = $job->property("out_file");
    system "cp $cluster_out $result_file";
    print STDERR "Problem copying to result file: $?" if ($?);

    #	print STDERR "\nOutput written to file: $result_file";
    print "+" if DEBUG;
    $job->property( "final_written", 1 );
}

sub alive {

    #alive() works very differently here than in parent class.
    #Result files are written as soon as the job is no longer alive,
    #since there is no need to wait before all the jobs are done to
    #start getting results

    my $self      = shift;
    my $job_array = $self->jobs();
    my $running   = 0;
    foreach my $job (@$job_array) {
        $running = 1 if $job->alive();
        if ( !$job->alive() ) {
            $self->write_result($job) unless $job->property("final_written");
        }
    }
    return $running;
}

1;
