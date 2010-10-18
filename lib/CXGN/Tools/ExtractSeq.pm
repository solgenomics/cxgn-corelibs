
use Moose;

use MooseX::Declare;

class CXGN::Tools::ExtractSeq { 
    
    with 'MooseX::Runnable';
    with 'MooseX::Getopt';
    
    use Bio::Tools::GFF;
    use Bio::SeqIO;
    use Data::Dumper;
    
    has fasta_file => (is => 'rw',
		       isa => 'Str',
		       required => 1,
		       traits => [ 'Getopt' ],
		       cmd_aliases => 'i',
		       documentation => 'Input file in fasta format',
		       default => 'largefasta',
		       
	);

    has format     => (is =>'rw',
                       isa => 'Str',
		       required=>0,
		       traits => ['Getopt' ],
		       documentation => 'the format of the fasta file to use. Either fasta or largefasta',
	);
    
    has gff_file   => (is => 'rw', 
		       traits => ['Getopt'],
		       cmd_aliases => 'g',
		       isa => 'Str',
		       required => 1,
		       documentation => 'gff3 file containing gene models',
	);
    
    
    has length      => (is=>'rw',
			traits=> ['Getopt'],
			cmd_aliases => 'l',
			isa => 'Int',
			required => 0,
			default => 5000,
			documentation => 'the length of the sequence to be extracted',
			
	);
    
    has seq_objects  => (is => 'rw',
			 isa => 'HashRef',
    );

    has upstream     => (is => 'rw',
			 traits=>['Getopt'],
	);

    has downstream   => (is => 'rw',
			 traits=>['Getopt'],
	);

    has intron       => (is => 'rw',
			 traits=>['Getopt'],
			 default => 0,
	);
			
        
    method read_sequences { 
	
	print STDERR "Reading the sequence data... :-) \n";
	
	my %seqs = ();
	my $seqio = Bio::SeqIO->new(-format=>$self->format(), -file=>$self->fasta_file());
	while (my $s = $seqio->next_seq()) { 
	    $seqs{$s->id()} = $s;
	}
	
	$self->seq_objects(\%seqs);
	
	$seqio->close();
    }
    
=head2 extract_upstream

 Usage:        $e->extract_upstream(Str $parent, Str $id, Int $start, Int $end, Int $strand)
 Desc:         extracts the upstream sequence of sequence $id with 
               $coord $start and $end on sequence $parent (which must
               occur in fasta_file(). If $strand is negative, the upstream
               sequence is cut out from the end and reverse complemented.
 Ret:          a Bio::Seq object with the upstream sequence
 Args:
 Side Effects:
 Example:

=cut

    method extract_upstream(Str $parent, Str $id, Int $start, Int $end, Int $strand) { 
	#my $self = shift;
	
	my %seqs = %{$self->seq_objects()};
	my $promoter = "";
	my $length = $self->length();
	if (!exists($seqs{$parent})) { 
	    print STDERR "Don't know about $parent\n";
	}
	else { 
	    if ($strand > 0) { 
		# forward  
		
		if ($length>$start) { $length = $start; }
		my $upstream_start = $start - $length;
		my $upstream_end = $start -1;
		
		if ($upstream_start < 1) { $upstream_start = 1; }
		if ($upstream_end < 1) { $upstream_end =1; }
		
		print STDERR "Subseq $upstream_start - $upstream_end          \r";
		$promoter = $seqs{$parent}->subseq($upstream_start, $upstream_end);
	    }
	    
	    elsif ($strand < 0) { 
		my $upstream_start = $end +1;
		
		my $upstream_end = $end + $self->length();
		if ($upstream_end  > $seqs{$parent}->length()) { 
		    $upstream_end  = $seqs{$parent}->length();
		}

		print STDERR "Subseq $upstream_start - $upstream_end            \r";
		my $forward = $seqs{$parent}->subseq($upstream_start, $upstream_end);
		my $revseq = Bio::Seq->new(-seq=>$forward);
		$promoter = $revseq->revcom()->seq();
	    }
	}		  
	my $seq = Bio::Seq->new(-seq=>$promoter, -id=>$id."_promoter_".$length);
	return $seq;
    }

    method extract_downstream(Str $parent, Str $id, Int $start, Int $end, Int $strand) { 
	my $downstream = $self->extract_upstream($parent, $id, $start, $end, $strand * (-1));
	$downstream->seq($downstream->revcom()->seq());
	$downstream->id($id."_downstream_".$self->length());
	return $downstream;
    }

=head2 extract_introns

 Usage:        $e->extract_introns(Str $parent, Str $id, ArrayRef $exons, Int $strand)
 Desc:         extracts the introns from the sequence $parent, which
               must be in fasta_file(). The exons are easily parsed out of 
               a gff3 file and can be given as an arrayref of [start, end] 
               coords. Strand is either +1 or -1, in the latter case all intron
               sequences are reverse complemented and listed in reverse order.
 Ret:          A list of Bio::Seq object containing the introns.
 Args:
 Side Effects:
 Example:

=cut

    method extract_introns(Str $parent, Str $id, ArrayRef $exons, Int $strand) { 

	#print "PROCESSED EXON HASH: ".Dumper($exons);

	my @introns = ();
	
	for (my $i=0; $i<@{$exons}-1; $i++) {
	    my $intron_start = $exons->[$i]->[1];
	    my $intron_end = $exons->[$i+1]->[0];
	    my $intron_seq = $self->seq_objects()->{$parent}->subseq($intron_start+1, $intron_end-1);
	    
	    my $intron_obj = Bio::Seq->new(-seq=>$intron_seq, -id=>$id."_intron");
	    if ($strand<0) { $intron_obj = $intron_obj->revcom(); }
	    
	    push @introns, $intron_obj
	}
	
	if ($strand < 0) { 
	    @introns = reverse(@introns);
	}
	
	for (my $i = 0; $i< @introns; $i++) {
	    $introns[$i]->id( $introns[$i]->id()."_".($i+1));
	}
	
	return @introns;
	
    }


    sub run  { 
	my $self = shift;
	my $opt = shift;
	my $args = shift;
	
	$self->read_sequences();
		print STDERR "Processing the GFF3 file...\n";
	
	my $gffio = Bio::Tools::GFF->new(
	    -file=>$self->gff_file(), 
	    -gff_version=>3
	    );
	
	my $upstream_out = Bio::SeqIO->new(
	    -file=>">".$self->fasta_file().".upstream_".$self->length(),
	    -format=>"fasta"
	    );
	my $downstream_out = Bio::SeqIO->new(
	    -file=>">".$self->fasta_file().".downstream_".$self->length(), 
	    -format=>"fasta"
	    );
	my $introns_out = Bio::SeqIO->new(
	    -file=>">".$self->fasta_file().".introns", 
	    -format=>'fasta'
	    );

	my %exons = ();
	my $gene_id = "";
	my $previous_id = "";
	my $previous_strand = "";
	my $previous_parent = "";
	my $gene_parent = "";
	my $parent = "";
	my $strand = 0;
	my $start = 0;
	my $end = 0;
	my $id = "";
	while (my $f = $gffio->next_feature())  { 
	    $start = $f->start();
	    $end   = $f->end();
            $strand = $f->strand();
	    
	    $parent = $f->seq_id();
	    my $primary =$f->primary_tag();
	    my $source_tag = $f->source_tag();
	    $id = $f->primary_id();
	    
	    if ($primary eq 'gene') { 
		$previous_id=$gene_id;
		$previous_parent = $gene_parent;
		$gene_parent = $parent;
		$gene_id = $id;


		print STDERR "Processing gene $gene_id [ $start, $end ]             \r";

		if ($self->upstream()) { 
		    if (!$end) { print STDERR "skipping $id (end is 0)...\n"; next; }
		    my $seq = $self->extract_upstream($gene_parent, $id, $start, $end, $strand);
		    $upstream_out->write_seq($seq);
		}

		if ($self->downstream()) { 
		    my $seq = $self->extract_downstream($gene_parent, $id, $start, $end, $strand);
		    $downstream_out->write_seq($seq);
		}
	    }

	    if ($self->intron() && $primary eq 'exon') { 
		
		#print STDERR "Processing exon $id. Parent = $parent Source = $source_tag primary $primary [ $start, $end ]\n";		    
		push @{$exons{$gene_id}}, [$start, $end];
		
		#print "EXON HASH: ".Dumper(%exons);
	    }
	    if ($self->intron() && $primary eq 'exon' && $previous_id && ($previous_id ne $gene_id)) { 
		print STDERR "Outputting introns...($previous_id, $id)\n";
		if (exists($exons{$previous_id})) { 

		    
		    my @introns = $self->extract_introns($previous_parent, $previous_id, [ map { $_ } @{$exons{$previous_id}} ], $strand);
		    for (my $i = 0; $i< @introns; $i++) {
			$introns_out->write_seq($introns[$i]);
		    }
		}
		
		
	    }
		
	    
	    $previous_strand = $strand;

	}
	
	if ($self->intron()) { 
	    #print STDERR "Processing last entry... $gene_id, $strand\n";
 	    my @introns = $self->extract_introns($parent, $gene_id, [ map { $_ } @{$exons{$gene_id}} ], $strand);
 	    foreach my $i (@introns) {
		$introns_out->write_seq($i);
	    }
	} 
	
	$introns_out->close();
	$upstream_out->close();
	$downstream_out->close();

	print STDERR "\nDone\n";
	    
	return 0; # means success here.
    }    
}

1;
