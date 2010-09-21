package CXGN::BioTools::CapsDesigner2;


=head1 NAME

CXGN::BioTools::CapsDesigner2

=head1 DESCRIPTION

CAPS Designer 2: tool for multiple sequences


=cut

use strict;
use warnings;
use Bio::Seq;
use Bio::SeqIO;
use Bio::AlignIO;
use Getopt::Long;
use File::Temp;
use Bio::Restriction::Analysis;
use Bio::PrimarySeq;



=head2 check_fasta

  Desc: Checks formatting of fasta entry
  Args: none
  Ret : 1 if the fasta format was OK, an error message if not

=cut
sub check_fasta {
  my $file = shift or die "No File!";
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
      }else {
	return "Oops - your input sequences need to have different names.";
	last;
      }
    }      
  }
  close IN;
  return 1;
}

=head2 check_clustal

  Desc: Checks formatting of clustal entry
  Args: none
  Ret : 1 if the format was OK, an error message if not

=cut
sub check_clustal {
  my $file = shift or die "No File!";
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
	return 1;
      }
    }
  }
  close IN;
}

=head2 check_input_number

  Desc: Counts the number of sequences input by the user
  Args: 
  Ret : the number of sequences input

=cut
sub check_input_number {
  my $file = shift or die "No File!";
  open IN, $file;
  my $num = 0;
  while (<IN>) {
    /^>/ and $num++;
  }
  return $num;
}
close IN;


=head2 read_enzyme_file

  Desc: get the enzyme names, recognition sites & costs
  Args: 
  Ret : 

=cut
sub read_enzyme_file { 

  my $enzymelist = shift or die "No enzyme list!";
  open FH, $enzymelist or die "Couldn't open $enzymelist!";
  my %cut;
  my %cost;
  while (<FH>){
    chomp;
    my @array = split "\t", $_;
    $cut{$array[0]} = $array[1];
    $cost{$array[0]} = $array[2] unless $array[2]=~/N\/A/;
  }
  close FH;
  return \%cost, \%cut;
}

=head2 format_input_file

  Desc: If the input file is fasta, make alignment with clustalw
  Args: 
  Ret : 

=cut
sub format_input_file { 
  
  my $format = shift or die "Missing format parameter!";
  my $input = shift or die "Missing input parameter!";
  my $fasta;
  if ($format eq 'fasta'){

    open my $stdout, ">&STDOUT"  or die "Can't dup STDOUT: $!";
    open STDOUT, '>', "/dev/null" or die "Can't redirect STDOUT: $!";

    my $status = system (qw/clustalw -quiet/,"-INFILE=$input");
    return if $status;

    # replace STDOUT
    open STDOUT, '>&', $stdout or die "Can't replace STDOUT: $!";

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


=head2  get_seqs

  Desc: parse the alignment fasta and return the ids and sequences of the entries.
  Args: fasta formatted file
  Ret : the length of an aligned sequence, and a hashref for a hash containing the entry ids and corresponding sequences

=cut
sub get_seqs{
  my $fasta = shift;
  my $seq_len;
  my %parent_information;
  my $in = Bio::SeqIO -> new (-file => $fasta,
			      -format => 'fasta'
			     );
  while (my $seqobj = $in -> next_seq()) {
    my $id = $seqobj -> id();
    my $seq = $seqobj -> seq();
    $parent_information{$id} = $seq;
  }
  my @temp = values %parent_information;
  $seq_len = length $temp[0];

  return $seq_len, \%parent_information;
}


=head2  check_seqs

  Desc: checks to make sure DNA sequences only contain appropriate nucleotides
  Args: hash with DNA sequences for values
  Ret : 1 if OK, 0 otherwise

=cut
sub check_seqs{
     my $parent_info_ref = shift or die "Missing parameter(s)!";
     my %parent_info = %$parent_info_ref;
     my $string = "";
     for (values %parent_info){
	 my $temp = length $_;
	 m/^[actgnACTGN\-]*$/ or return 0;
     }
    return 1;
}


=head2 find_caps
 
  Desc: 
  Args: 
  Ret : 

=cut 
sub find_caps {
  
    my $inforef = shift or die "Missing parameter(s)!";
    my $seqlength = shift or die "Missing parameter(s)!";
    my $enzyme_cut_ref = shift or die "Missing parameter(s)!";
    my $exclusion = shift;
    my $cutno = shift or die "Missing parameter(s)!";
    my $cst_ref = shift or die "Missing parameter(s)!";
    my $chp_only = shift;
    
    unless (defined $exclusion) {$exclusion = 0;}
    unless (defined $chp_only) {$chp_only = 0;}

    my $cutstart = $exclusion; # start searching CAPs
    my $cutend = $seqlength - $exclusion; # end searching CAPs
    my %info = %$inforef;
    my %cut = %$enzyme_cut_ref;
    my %cost = %$cst_ref;

    my %pos;
    my %substrings;
    my %uniques;

    for my $current_enzyme (keys %cut){ 

	next if ( (!defined $cost{$current_enzyme}) && ($chp_only == 1));

	(my $site = $cut{$current_enzyme}) =~ s/\[\w\|\w\]/\./g;
	my $enzymelength = length $site;

	my $seq = Bio::PrimarySeq->new(-seq => "t", -id => 1);
	my $analyzer = Bio::Restriction::Analysis->new(-seq => $seq);

	for my $id (sort keys %info){
	    $seq->seq($info{$id});
	    $analyzer->seq($seq);
	    my @positions = $analyzer->positions($current_enzyme);
	    $pos{$current_enzyme}{$id} = \@positions;
	}

	my $too_many_sites = 1;
	for(values %{$pos{$current_enzyme}}) {
	    my @sites = @$_; 
	    my $num_of_sites = @sites;
	    if($num_of_sites < $cutno){
		$too_many_sites = 0;
		next;
	    }
	}
	next if $too_many_sites; # skip if enzyme cut sites are many
    
	my @cut_site_list;
	for my $id (keys %info){
	    push(@cut_site_list, @{$pos{$current_enzyme}{$id}});
	}

	@cut_site_list = sort @cut_site_list;
	my $previous = 0;
	for(@cut_site_list){
	    if($_ == $previous){
            undef $_;
	    }else{
            $previous = $_;
	    }
	}
	#cut site list now contains only undef values and one copy of each cut site
 
	for my $cut_site (@cut_site_list){
	    next unless defined $cut_site;
	    my @ids_with_site;
	    my @ids_without_site;
	    for my $id (keys %info){
		my $has_site = 0;
		for(@{$pos{$current_enzyme}{$id}}) {
		    if($_ == $cut_site) {$has_site = 1;}
		}
		if($has_site){
		    push(@ids_with_site, $id);
		}else{
		    push(@ids_without_site, $id);
		}
	    } 
	
	    my $unique;
	    if(@ids_with_site == 1){
		$unique = $ids_with_site[0];
	    }elsif (@ids_without_site == 1){
		$unique = $ids_without_site[0];
	    }else{
		next;
	    }
	    next if ($cut_site < $cutstart) or ($cut_site > $cutend);
	
	    my $has_n = 0;

	    if($cut_site < 15){
		my $ind = &_site_start(lc(substr($info{$ids_with_site[0]}, 0, 25)), $cut{$current_enzyme}, $cut_site);
		for my $id (keys %info) {
		    my $substr = lc (substr($info{$id}, 0, 25));
		    substr($substr, $ind, $enzymelength) =~ tr/actg/ACTG/;
            if (substr($substr, $ind, $enzymelength) =~/n|N/) {
                $has_n = 1;
                next;
            }
		    $substrings{$current_enzyme}{$cut_site}{$id} = $substr;
		}
	    }elsif ($cut_site > ((length $info{$ids_with_site[0]}) - 10) ) {
		my $ind = &_site_start(lc(substr($info{$ids_with_site[0]}, $cut_site-10)), $cut{$current_enzyme}, 10);
		for my $id (keys %info){
		    my $substr = lc (substr($info{$id}, $cut_site -10));
		    substr($substr, $ind, $enzymelength) =~ tr/actg/ACTG/;
            if (substr($substr, $ind, $enzymelength) =~/n|N/) {
                $has_n = 1;
                next;
            }
		    $substrings{$current_enzyme}{$cut_site}{$id} = $substr;
		}
	    }else{
		my $ind = &_site_start(lc(substr($info{$ids_with_site[0]}, $cut_site-10, 20)), $cut{$current_enzyme}, 10);
		for my $id (keys %info) {
		    my $substr = lc(substr($info{$id}, $cut_site - 10, 20));
		    substr($substr, $ind, $enzymelength) =~ tr/actg/ACTG/;
            if (substr($substr, $ind, $enzymelength) =~/n|N/) {
                $has_n = 1;
                next;
            }
		    $substrings{$current_enzyme}{$cut_site}{$id} = $substr;
		}
	    }
	    $uniques{$current_enzyme}{$cut_site} = $unique unless $has_n;
	}
    }
    return \%substrings, \%pos, \%uniques;
}

sub _site_start{

    my $substring = shift or die "Missing parameter(s)!";
    my $site = shift or die "Missing parameter(s)!";
    my $site_location = shift or die "Missing parameter(s)!";

    $site =~ s/\|//g;
    
    my $ind =$site_location;
    until (substr($substring,$ind) =~ /^($site).*/i) {
	$ind--;
    }
    return $ind;
}


=head2 predict_fragments

  Desc: predicts fragment sizes for each enzyme that will make unique cuts
  Args: 
  Ret : 

=cut

sub predict_fragments{

    my $pos_ref = shift or die "Missing parameter(s)!";
    my $align_len = shift or die "Missing parameter(s)!";
    my %cuts = %$pos_ref;
    my %size;

  for my $current_enzyme (keys %cuts) {
      for my $id (keys %{$cuts{$current_enzyme}}) {
	  my $pre_pos = 0;
	  my $last_pos = $align_len;
	  for (sort {$a<=>$b} @{$cuts{$current_enzyme}{$id}}) {
	      my $cur_pos = $_;
	      my $fragment = $cur_pos - $pre_pos;
	      push @{$size{$current_enzyme}{$id}}, $fragment;
	      $pre_pos = $cur_pos;
	  }
	  my $last_fragment = $last_pos - $pre_pos;
	  push @{$size{$current_enzyme}{$id}}, $last_fragment;
      }
  }
  return \%size;
}   

=head2 print_text

  Desc: 
  Args: 
  Ret : a file containing CAPS data

=cut
#The built-in plain text print function

sub print_text{
   my $cost_ref = shift or die "Missing parameter(s)!";
   my $cut_ref = shift or die "Missing parameter(s)!";
   my $len = shift or die "Missing parameter(s)!";
   my $pos_ref = shift or die "Missing parameter(s)!";
   my $caps_ref = shift or die "Missing parameter(s)!";
   my $info_ref = shift or die "Missing parameter(s)!";
   my $c_only = shift;
   my $sz_ref = shift or die "Missing parameter(s)!";
   my $uniques_ref = shift or die "Missing parameter(s)!";
   my $cut_n = shift;
   my $excl_seq = shift;
   my $out_path = shift or die "Missing parameter(s)!";

   my $out_fh = new File::Temp(
			 DIR => $out_path,
			 UNLINK => 0,
			);
   my $out_name = $out_fh -> filename;

   my %cost = %$cost_ref;
   my %rec_seq = %$cut_ref;
   my %position = %$pos_ref;
   my %caps = %$caps_ref;
   my %info = %$info_ref;
   my %size = %$sz_ref;
   my %uniques = %$uniques_ref;

   print $out_fh "Exclude Ends: $excl_seq bp\n";
   print $out_fh "Cutting Times: $cut_n\n";
   print $out_fh "Enzyme Selection: ";
   if ($c_only ==1) { print $out_fh "less than \$65/1000u only\n"}
   else {print $out_fh "all\n";}
   print $out_fh "Sequence Selection:".join(", ", sort keys %info)."\n";
   print $out_fh "Sequence length(w/gaps): $len bp\n";
   print $out_fh "CAPS Enzymes: ";
   print $out_fh "".join(", ", sort keys %caps);
   print $out_fh "\n";
   print $out_fh "#############################\n";
   for my $current_enzyme (sort keys %caps){

       next if ((!defined $cost{$current_enzyme} && ($c_only == 1)));
       my @array = split m/,/ , $cost{$current_enzyme};
       print $out_fh "ENZYME\t$current_enzyme $array[1]\n";
       print $out_fh "RECOGNITION SEQUENCES\t$rec_seq{$current_enzyme}\n";
       print $out_fh "CUTTING SITES\n";
       for my $id (sort keys %{$position{$current_enzyme}}) {
	   print $out_fh "$id\t";
	   if(@{$position{$current_enzyme}{$id}} == 0) {
	       print $out_fh "None";
	   }else{
	       for (sort {$a<=>$b} @{$position{$current_enzyme}{$id}}){
		   print $out_fh "$_ ";
	       }
	   }  
	   print $out_fh "\n";
       }
       print $out_fh "PREDICTED FRAGMENTS\n";
       for my $id (sort keys %{$size{$current_enzyme}}) {
	   print $out_fh "$id\t";
	   my @fragments;
	   for (@{$size{$current_enzyme}{$id}}){
	       push (@fragments, "$_ bp");
	   }
	   print $out_fh join(", ",@fragments)."\n";
       }

       print $out_fh "CAPS CANDIDATES\n";
       for my $cap_pos (sort keys %{$caps{$current_enzyme}}) {
	   print $out_fh "Position\t$cap_pos \n";
	   for my $id (keys %{$caps{$current_enzyme}{$cap_pos}}) {
	       print $out_fh "$id\t$caps{$current_enzyme}{$cap_pos}{$id}\n";
	   }
       }
       print $out_fh "#############################\n";
   }
   close $out_fh;
   return $out_name;
 }
  
1;
