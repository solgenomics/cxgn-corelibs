#!/usr/bin/perl

use strict;
use warnings;
use Bio::Seq;
use Bio::SeqIO;
use Bio::AlignIO;
use Getopt::Long;
use File::Temp;

package CXGN::BioTools::CapsDesigner;
sub check_fasta {
  my $file = shift;
  my %seq = ();
  open IN, $file;
  my $firstline;
  while (<IN>){
    /^\s+$/ and next;
    if (!defined $firstline) {
      $firstline = $_;
      if (!($firstline =~ /^>/)){
	return "Your sequences do not appear to be in FASTA format.";
	last;
      }
    }
    if (/^>/) {
      if (!defined $seq{$_}){
	$seq{$_} = 1;
      }
      else {
	return "Oops - your input sequences need to have different names.";
	last;
      }
    }      
  }
  close IN;
}

# function by Beth to match check_fasta. 
# This is probably a terrible way to check, but it's 
# exactly what bioperl does. 
sub check_clustal {
  my $file = shift;
  my %seq = ();
  open IN, $file;
  my $firstline;
  while (<IN>){
    /^\s+$/ and next;
    if (!defined $firstline) {
      $firstline = $_;
      if (!($firstline =~ /CLUSTAL/)){
	return "Your sequences do not appear to be in CLUSTAL format.";
      } else {
	# everything ok
	return 1;
      }
    }
  }
  close IN;
}

sub check_input_number {
  my $file = shift;
  open IN, $file;
  my $num = 0;
  while (<IN>) {
    /^>/ and $num++;
  }
  return $num;
}
close IN;


sub read_enzyme_file { 
  # get the enzyme name, recognition site & cost

  my $enzymelist = shift;
  open FH, $enzymelist or die "Couldn't open $enzymelist!";
  my @allenzyme;
  my %cut;
  my %cost;
  while (<FH>){
    chomp;
    my @array = split "\t", $_;
    $cut{$array[0]} = $array[1];
    push @allenzyme,$array[0];
    $cost{$array[0]} = $array[2] unless $array[2]=~/N\/A/;
  }
  close FH;
  return \%cut, \%cost;
}

sub format_input_file { 
  # If the input file is fasta, make alignment with clustalw
  
  my $format = shift;
  my $input = shift;
  my $fasta;
  if ($format eq 'fasta'){
    my $status = system ('clustalw', "-INFILE=$input", "-OUTPUT=CLUSTAL");
    if ( $status != 0) {
      return;
    }
    $format = 'clustalw';
    $input .= '.aln';
  }
  if ($format eq 'clustalw') {
    #clustalw file
    my $in = Bio::AlignIO -> new (-file => $input,
				  -format => 'clustalw'
				 );
    $fasta = $input . ".fasta";
    my $out = Bio::AlignIO -> new (-file => ">$fasta",
				   -format => 'fasta'
				  );
    while (my $aln = $in -> next_aln()){
      $aln -> set_displayname_flat();
      $out -> write_aln($aln);
    }
  } 
  return $input, $fasta;
}

sub get_seqs{
#parse the alignment fasta and return the id and sequence of the first two entries.
  my $fasta = shift;
  my $select = shift;
  my @ids = ();
  my @seqs= ();
  my $seq_len;
  my $in = Bio::SeqIO -> new (-file => $fasta,
			      -format => 'fasta'
			     );
  while (my $seqobj = $in -> next_seq()) {
    my $id = $seqobj -> id();
    my $seq = $seqobj -> seq();
    push @ids, $id;
    push @seqs, $seq;
  }
  $seq_len = length $seqs[0];
  if ($select == 1){
    return $ids[0], $seqs[0], $ids[1], $seqs[1], $seq_len;
  }
  elsif ($select == 2){
    return $ids[0], $seqs[0], $ids[2], $seqs[2], $seq_len;
  }
  else {
    return $ids[1], $seqs[1], $ids[2], $seqs[2], $seq_len;
  }
}
  


sub find_caps {
  my $id1 = shift;
  my $seq1 = shift;
  my $id2 = shift;
  my $seq2 = shift;
  my $seqlength = shift;
  my $enzymeref = shift;
  my $start = shift;
  my $end = shift;
  my $cutno = shift;
  my $c_ref = shift;
  my $ch_only = shift;

  my $cutstart=$start; # start searching CAPs
  my $cutend=$seqlength-$end; # end searching CAPs
  my %enzyme = %$enzymeref;
  my %cost = %$c_ref;

  my %pos;
  my %pos1;
  my %pos2;
  my %pos_seq1;
  my %pos_seq2;

  foreach (keys %enzyme){
    my $current_enzyme = $_;
    if ( (!defined $cost{$current_enzyme}) && ($ch_only == 1)){
      next;
    }
   
    (my $temp = $enzyme{$current_enzyme}) =~ s/\[\w\|\w\]/\./g;
    my $enzymelength = length $temp;
    
    #### cutting site of the enzyme in parent1
    my $new1 = $seq1;
    my $index1 = 'no';
    my $cutno1 = 0;
    while ($new1 =~ /$enzyme{$current_enzyme}/cgi){ 
      $cutno1 ++;
      $index1 = 'yes';
      my $pos = pos $new1;
      $pos1{$current_enzyme}{$pos} = 1; 
      $pos{$current_enzyme}{$pos}=1;
    }  
    
    #### cutting site of the enzyme in parent2
    my $new2 = $seq2;
    my $index2 = 'no';
    my $cutno2 = 0;
    while ($new2 =~ /$enzyme{$current_enzyme}/cgi){ 
      $cutno2 ++;
      $index2 = 'yes';
      my $pos = pos $new2;
      $pos2{$current_enzyme}{$pos} = 1;
      $pos{$current_enzyme}{$pos}=1;
    }  
    next if $cutno1 > $cutno and $cutno2 > $cutno; # skip if enzyme cut sites are many
    
    #### compare the cutting site of the two parents
    
    foreach (sort {$a<=>$b} keys %{$pos{$current_enzyme}}){
      if ($pos1{$current_enzyme}{$_} && $pos2{$current_enzyme}{$_}){  # common cut sites in both parents
	next;
      }elsif ($pos1{$current_enzyme}{$_}){ # unique cut sites in parent1
	next if $_ < $cutstart or $_ > $cutend;
	my $sub1;
	my $sub2;
	if ($_<20){
	  $sub1 = lc (substr($seq1,0,$_));
	  substr($sub1,$_-$enzymelength,$enzymelength)=~tr/actg/ACTG/;
	  $sub2 = lc (substr($seq2,0,$_));
	  substr($sub2,$_-$enzymelength,$enzymelength)=~tr/actg/ACTG/;
	  #skip if CAPs are caused by n or N in parent2
	  next if substr($sub2,$_-$enzymelength,$enzymelength)=~/n|N/;
	}elsif ($_ > $seqlength-10){
	  $sub1 = lc (substr($seq1,$_-20));
	  substr($sub1,20-$enzymelength,$enzymelength)=~tr/actg/ACTG/;
	  $sub2 = lc (substr($seq2,$_-20));
	  substr($sub2,20-$enzymelength,$enzymelength)=~tr/actg/ACTG/;
	  #skip if CAPs are caused by n or N in parent2
	  next if substr($sub2,20-$enzymelength,$enzymelength)=~/n|N/;
	}else{
	  $sub1 = lc (substr($seq1,$_-20,30));
	  substr($sub1,20-$enzymelength,$enzymelength)=~tr/actg/ACTG/;
	  $sub2 = lc (substr($seq2,$_-20,30));
	  substr($sub2,20-$enzymelength,$enzymelength)=~tr/actg/ACTG/;
	  #skip if CAPs are caused by n or N in parent2
	  next if substr($sub2,20-$enzymelength,$enzymelength)=~/n|N/;
	}
	$pos_seq1{$current_enzyme}{$_} = $sub1;
	$pos_seq2{$current_enzyme}{$_} = $sub2;
      }elsif ($pos2{$current_enzyme}{$_}){ # unique cut sites in parents
	next if $_ < $cutstart or $_ > $cutend;
	my $sub1;
	my $sub2;
	if ($_<20){
	  $sub1 = lc (substr($seq1,0,$_));
	  substr($sub1,$_-$enzymelength,$enzymelength)=~tr/actg/ACTG/;
	  $sub2 = lc (substr($seq2,0,$_));
	  substr($sub2,$_-$enzymelength,$enzymelength)=~tr/actg/ACTG/;
	  #skip if CAPs are caused by n or N in parent1
	  next if substr($sub1,$_-$enzymelength,$enzymelength)=~/n|N/;
	}elsif ($_ > $seqlength-10){
	  $sub1 = lc (substr($seq1,$_-20));
	  substr($sub1,20-$enzymelength,$enzymelength)=~tr/actg/ACTG/;
	  $sub2 = lc (substr($seq2,$_-20));
	  substr($sub2,20-$enzymelength,$enzymelength)=~tr/actg/ACTG/;
	  #skip if CAPs are caused by n or N in parent1
	  next if substr($sub1,20-$enzymelength,$enzymelength)=~/n|N/;
	}else{
	  $sub1 = lc (substr($seq1,$_-20,30));
	  substr($sub1,20-$enzymelength,$enzymelength)=~tr/actg/ACTG/;
	  $sub2 = lc (substr($seq2,$_-20,30));
	  substr($sub2,20-$enzymelength,$enzymelength)=~tr/actg/ACTG/;
	  #skip if CAPs are caused by n or N in parent1
	  next if substr($sub1,20-$enzymelength,$enzymelength)=~/n|N/;
	}
	$pos_seq1{$current_enzyme}{$_} = $sub1;
	$pos_seq2{$current_enzyme}{$_} = $sub2;
      }
    }
  }
  return \%pos1, \%pos2, \%pos_seq1, \%pos_seq2;
}

sub predict_size{
  my $pos1_ref = shift;
  my $pos2_ref = shift;
  my $align_len = shift;
  my %pos1 = %$pos1_ref;
  my %pos2 = %$pos2_ref;
  my %size1;
  my %size2;

  foreach (keys %pos1){
    my $current_enzyme = $_;
    my $pre_pos = 0;
    my $last_pos = $align_len;
    foreach (sort {$a<=>$b} keys %{$pos1{$current_enzyme}}){
      my $cur_pos = $_;
      my $fragment = $cur_pos - $pre_pos;
      push @{$size1{$current_enzyme}}, $fragment;
      $pre_pos = $cur_pos;
    }
    my $last_fragment = $last_pos - $pre_pos;
    push @{$size1{$current_enzyme}}, $last_fragment;
  }

  foreach (keys %pos2){
    my $current_enzyme = $_;
    my $pre_pos = 0;
    my $last_pos = $align_len;
    foreach (sort {$a<=>$b} keys %{$pos2{$current_enzyme}}){
      my $cur_pos = $_;
      my $fragment = $cur_pos - $pre_pos;
      push @{$size2{$current_enzyme}}, $fragment;
      $pre_pos = $cur_pos;
    }
    my $last_fragment = $last_pos - $pre_pos;
    push @{$size2{$current_enzyme}}, $last_fragment;
  }
  return \%size1, \%size2;
}    

#The built-in plain text print function
sub print_text{
  my $ct_ref = shift;
  my $rc_ref = shift;
  my $len = shift;
  my $pos1_ref = shift;
  my $pos2_ref = shift;
  my $c1_seq_ref = shift;
  my $c2_seq_ref = shift;
  my $id1 = shift;
  my $id2 = shift;
  my $c_only = shift;
  my $sz1_ref = shift;
  my $sz2_ref = shift;
  my $cut_n = shift;
  my $excl_seq = shift;
  my $out_path = shift;

  my $out_fh = new File::Temp(
			 DIR => $out_path,
			 UNLINK => 0,
			);
  my $out_name = $out_fh -> filename;

  my %cost = %$ct_ref;
  my %rec_seq = %$rc_ref;
  my %pos1 = %$pos1_ref;
  my %pos2 = %$pos2_ref;
  my %pos1_seq = %$c1_seq_ref;
  my %pos2_seq = %$c2_seq_ref;
  my %size1 = %$sz1_ref;
  my %size2 = %$sz2_ref;
  
  print $out_fh "Exclude Ends: $excl_seq bp\n";
  print $out_fh "Cutting Times: $cut_n\n";
  print $out_fh "Enzyme Selection: ";
  if ($c_only ==1) { print $out_fh "less than \$65/1000u only\n"}
  else {print $out_fh "all\n";}
  print $out_fh "Sequence Selection: $id1, $id2\n";
  print $out_fh "Sequence length(w/gaps): $len bp\n";
  print $out_fh "CAPS Enzymes: ";
  foreach (keys %pos1_seq){
    print $out_fh "$_, ";
  }
  print $out_fh "\n";
  print $out_fh "#############################\n";
  foreach (keys %pos1_seq){
    my $current_enzyme = $_;
    if ((!defined $cost{$current_enzyme} && ($c_only == 1))){
      next;
    }
    my @array = split /,/, $cost{$current_enzyme};
    print $out_fh "ENZYME\t$current_enzyme $array[1]\n";
    print $out_fh "RECOGNITION SEQUENCES\t$rec_seq{$current_enzyme}\n";
    print $out_fh "CUTTING SITES\n";
    print $out_fh "$id1\t";
    if (keys %{$pos1{$current_enzyme}} == 0){
      print $out_fh "None";
    }
    else {
      foreach (sort {$a<=>$b} keys %{$pos1{$current_enzyme}}){     
	print $out_fh "$_  ";
      }
    }
    print $out_fh "\n";
    print $out_fh "$id2\t";   
    if (keys %{$pos2{$current_enzyme}} == 0){
      print $out_fh "None";
    }
    else {
      foreach (sort {$a<=>$b} keys %{$pos2{$current_enzyme}}){     
	print $out_fh "$_  ";
      }
    }   
    print $out_fh "\n";
    print $out_fh "PREDICTED FRAGMENTS\n";
    print $out_fh "$id1\t";
    foreach (@{$size1{$current_enzyme}}){
      print $out_fh "$_ bp, ";
    }
    print $out_fh "\n";
    print $out_fh "$id2\t ";
   foreach (@{$size2{$current_enzyme}}){
      print $out_fh "$_ bp,";
    }
    print $out_fh "\n";
    
    print $out_fh "CAPS CANDIDATES\n";
    foreach (sort keys %{$pos1_seq{$current_enzyme}}){
      my $cap_pos = $_;
      print $out_fh "Position\t$cap_pos \n";
      print $out_fh "$id1\t$pos1_seq{$current_enzyme}{$cap_pos}\n";
      print $out_fh "$id2\t$pos2_seq{$current_enzyme}{$cap_pos}\n";
    }
  print $out_fh "#############################\n";
  }
  close $out_fh;
  return $out_name;
}
  
1;
