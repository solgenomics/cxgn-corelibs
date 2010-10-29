
=head1 NAME

CXGN::Tools::GetGaps - a script to obtain information about gaps (indicated as N's) in a fasta file (such as the tomato genome)

=head1 DESCRIPTION

Implemented as a MooseX::Runnable script to be run as follows:

mx-run CXGN::Tools::GetGaps --fasta_file sequences.fasta --min_gap_size 20 > output.txt

=head1 AUTHOR

Lukas Mueller


=cut



package CXGN::Tools::GetGaps;
use Moose;

with 'MooseX::Runnable';
with 'MooseX::Getopt';

use Bio::SeqIO;

has 'min_gap_size' => (is => 'rw',
		       isa => 'Int',
		       traits=> ['Getopt'],
		       default=>10,
    );


has 'fasta_file' => (is => 'rw',
		     isa => 'Str',
		     traits=>['Getopt'],
    );



sub run { 
    my $self = shift;

    my $io = Bio::SeqIO->new(-format=>'largefasta', -file=>$self->fasta_file());

    my $gap_no = 1;
    my $old_id = "";

    while (my $s = $io->next_seq()) { 
	my $seq = $s->seq();
	my $id = $s->id();

	if ($id ne $old_id) { 
	    $gap_no =1;
	}

	warn "Processing sequence $id (".$s->length()." nucleotides)...\n";
	
	my $n_region_start = 0;
	my $n_region_end = 0;
	foreach my $i (1..$s->length()) { 
	    my $nuc = $s->subseq($i, $i);
	    
	    if ($nuc=~/n/i) { 
		if (!$n_region_start) { $n_region_start=$i; }
	    }

	    else { 
		if ($n_region_start) { $n_region_end = $i; }

		my $gap_size = $n_region_end - $n_region_start + 1;
		if ($gap_size >= $self->min_gap_size()) { 

		    print "$id\_"; printf "%06d", "$gap_no"; print "\t$id\t$n_region_start\t$n_region_end\t$gap_size\n";
		    $gap_no++;

		}

		$n_region_start = 0;
		$n_region_end = 0;

	    }
		
	    
	}
    }
}



1;
