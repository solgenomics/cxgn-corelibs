package Overlap;
use strict;
use List::Util qw ( min max sum );

my $NO_ID = 'NOT_AN_ACTUAL_ID';

sub  new {
  my $class = shift;
  my $arg = shift; # either filename or string with contents of fasta file
  my $fraction = shift || 0.8;
  my $seed = shift || undef;
  my $args= {};
  my $self = bless $args, $class;

  if (defined $seed) {
    srand($seed);
  } else {
    srand();
  }
  my @ids = ();
  my %id_overlapseq = ();
  my %id_sequence = ();
  my @lines = ();
#  print "arg: $arg\n";
#  print "arg is file? ", -f $arg, "\n";
#  print "XXX: ",  $arg =~ /\n/, "\n";
  #  if ((! $arg =~ /\n/) and 
  if (!($arg =~ /\n/) and -f $arg) {		# $arg is filename
    open my $fhin, "<$arg";
    @lines = <$fhin>;
#    print "XXXXXXXlines: ", join("\n", @lines), "\n";
    close $fhin;
	
  } else {			# treat arg as string
    @lines = split("\n", $arg);
  }
  my $id = $NO_ID;
  my $sequence = '';
  while (@lines) {
    my $line = shift @lines;
 #   print $line;
    if ($line =~ /^>/) {
      if ($id ne $NO_ID) {
	$id_sequence{$id} = $sequence;
	push @ids, $id;
      }
      $id = $line;
      $id =~ s/^>\s*//;
      $id =~ s/\s+$//;
      $sequence = '';
    } else {
      $line =~ s/^\s+//;
      $line =~ s/\s+$//;
      $sequence .= $line;
    }
  }
  if (! exists $id_sequence{$id}  and  $sequence ne '') { # take care of the last id-sequence pair.
    $id_sequence{$id} = $sequence;
    push @ids, $id;
  }
  $self->{id_seq} = \%id_sequence;
  $self->{ids} = \@ids;

  my $n_sequences = scalar @ids;
  my $seq_length = length $id_sequence{$ids[0]};
  $self->{align_length} = $seq_length;
  $self->{n_sequences} = $n_sequences;
  my @position_counts = ((0) x $seq_length);
  my @position_aas = (('') x $seq_length);
  foreach my $id (@ids) {
    my $sequence = $id_sequence{$id};
    my $seql = length $sequence;
    die "Non-equal sequence lengths in alignment: $seq_length, $seql. id: $id \nsequence: $sequence\n" if($seql ne $seq_length);

    for (my $i = 0; $i < $seq_length; $i++) {
      my $aa = substr($sequence, $i, 1);
      if ($aa ne '-') {
	$position_counts[$i]++;
	if(!($position_aas[$i] =~ /$aa/)){
	  $position_aas[$i] .= $aa; # not invariant
	}
      }
    }
  }
  my $n_invariant = 0;
  foreach (@position_aas){
   # print "[$_]\n";
    $n_invariant++ if(length $_ == 1);
  }
#  print "n_invariant: $n_invariant  align length: ", scalar @position_aas, "\n"; 
#  print "pinv: ", $n_invariant/$seq_length, "\n";
  $self->{position_counts} = \@position_counts;
  my $n_required = ($fraction >= 1)? $n_sequences: int ($fraction * $n_sequences) + 1;
  $self->{n_required} = $n_required;
  my $overlap_length = 0;
  my %id_overlapnongapcount = ();
my $overlap_n_invariant = 0;
  foreach my $position (0..@position_counts-1) {
    my $count = $position_counts[$position];
    if ($count >= $n_required) {
      $overlap_length++;
      foreach my $id (@ids) {
	my $char = substr($id_sequence{$id}, $position, 1);
	$id_overlapseq{$id} .= $char;
	$id_overlapnongapcount{$id}++ if($char ne '-');	
      }
      $overlap_n_invariant++ if(length $position_aas[$position] == 1);
    }
  }
#  print "overlap n_invariant: $overlap_n_invariant,  length: $overlap_length\n";
#  print "overlap pinv: ", $overlap_n_invariant/$overlap_length, "\n";

  $self->{id_overlapseq} = \%id_overlapseq;
  $self->{id_overlapnongapcount} = \%id_overlapnongapcount;
  die "overlap length inconsistency??? $overlap_length \n" if($overlap_length != length $id_overlapseq{$ids[0]});
  $self->{overlap_length} = $overlap_length;
  #	$self->{ids} = \@ids;

  return $self;
}


sub  weed_sequences{
  # weed out sequences which have poor overlap with others
  my $self = shift;
  my $fraction = shift || 0.3;
  my $min_nongapcount = int($fraction * $self->{overlap_length});
  #my %id_overlap_count = (); # 
  my @ids = $self->{id_overlapnongapcount};
  foreach (@ids) {
    if ($self->{id_overlapnongapcount}->{$_} < $min_nongapcount) {
      # delete this sequence
      delete $self->{id_overlapseq}->{$_};
      delete $self->{id_overlapnongapcount}
    }
  }
}


sub align_fasta_string{
  my $self = shift;
  my $spacer = shift || '';
  my $align_fasta = '';
  foreach my $id (@{$self->{ids}}) {
    my $sequence = $self->{id_seq}->{$id};
    $align_fasta .= ">$spacer$id\n$sequence\n";
  }
  chomp $align_fasta;
  return $align_fasta;
}

sub overlap_fasta_string{
  my $self = shift;
  my $spacer = shift || '';
  my $overlap_fasta = '';
  foreach my $id (@{$self->{ids}}) {
    my $sequence = $self->{id_overlapseq}->{$id};
    $overlap_fasta .= ">$spacer$id\n$sequence\n";
  }
  chomp $overlap_fasta;
  return $overlap_fasta;
}

sub overlap_nexus_string{ # basic nexus format string for use by MrBayes.
  my $self = shift;
  my $n_leaves = scalar @{$self->{ids}}; 
  my $overlap_length = length ($self->{id_overlapseq}->{$self->{ids}->[0]});
  my $nexus_string = "#NEXUS\n" . "begin data;\n";
  $nexus_string .= "dimensions ntax=$n_leaves nchar=$overlap_length;\n";
  $nexus_string .= "format datatype=protein interleave=no gap=-;\n";
  $nexus_string .= "matrix\n";

  foreach my $id (@{$self->{ids}}) {
    my $sequence = $self->{id_overlapseq}->{$id};
    $id =~ s/[|].*//;
#print "id, nexid: $id  $nexid  \n";

    my $id50 = $id . "                                                  ";
    $id50 = substr($id50, 0, 50);
    $nexus_string .= "$id50$sequence\n";
  }
  $nexus_string .= "\n;\n\n" . "end;\n";
  return $nexus_string;
}

sub bootstrap_overlap_fasta_string{
  my $self = shift;
  my $spacer = shift || '';
  my %id_bootstrapoverlapseq = ();
  my $overlap_length = $self->{overlap_length};

  my @indices = ();
  for (1..$overlap_length) {
    my $index = int( rand($overlap_length) );
    push @indices, $index;
    #	$index_count{$index}++;
  }

  for my $id (@{$self->{ids}}) {
    my $std_overlap = $self->{id_overlapseq}->{$id};
    my $string = '';
    foreach my $index (@indices) {
      $string .=  substr($std_overlap, $index, 1);
    }
    $id_bootstrapoverlapseq{$id} = $string;
  }

  my $bofstring = '';
  foreach my $id (@{$self->{ids}}) {
    #	print "id, seq: $id; $sequence\n";
    my $sequence = $id_bootstrapoverlapseq{$id};
    $bofstring .= ">$spacer$id\n$sequence\n";
  }
  chomp $bofstring;
  return $bofstring;
}

sub get_overlap_length{
  my $self = shift;
  return $self->{overlap_length};
}
sub set_overlap_length{
  my $self = shift;
  $self->{overlap_length} = shift;
}


1;
