package Mrbayes;
use strict;
use List::Util qw ( min max sum );
#use TlyUtil qw ( Kolmogorov_Smirnov_D );

# this is an object to facilitate running MrBayes (Bayesian phylogeny
# inference program). The main functionality it adds is a relatively
# easy way to control the criteria for deciding when to end a run.

my $default_chunk_size = 2000;

sub  new {
  my $class = shift;
  my $arg = shift;	       # a hashref for setting various options
  my $default_arguments = {'alignment_nex_filename' => undef,
			   'file_basename' => undef,
			   'seed' => undef,
			   'swapseed' => undef,
			   'n_runs' => 2,
			   'n_temperatures' => 4,
			   'temperature_gap' => 0.25,
			   'chunk_size' => $default_chunk_size,
			   'print_freq' => undef,
			   'sample_freq' => 20,
			   'burnin_frac' => 0.1,
			   'diag_freq' => undef,
			   'converged_chunks_required' => 10,

			   'fixed_pinvar' => undef, # undef -> leaves default of uniform(0,1) in effect
			   # convergence criteria
			   'splits_min_hits' => 25,
			   'splits_max_ok_stddev' => 0.03,
			   'splits_max_ok_avg_stddev' => 0.01,
			   'modelparam_min_ok_ESS' => 250,
			   'modelparam_max_ok_PSRF' => 1.02,
			   'modelparam_max_ok_KSD' => 0.2,
			   'ngens_run' => 0,
			   'id_species_map' => {}
			  };
  my $self = bless $default_arguments, $class;

  foreach my $option (keys %$arg) {
    warn "Unknown option: $option in Mrbayes constructor.\n" if(!exists $self->{$option});
    $self->{$option} = $arg->{$option};
  }
  $self->{print_freq} = $self->{chunk_size} if(!defined $self->{print_freq});
  $self->{diag_freq} = $self->{chunk_size} if(!defined $self->{diag_freq});
  # print "print, diag freq: ", $self->{print_freq}, "  ", $self->{diag_freq}, "\n";

  my $alignment_nex_filename = $self->{alignment_nex_filename};
  #  if(defined $self->{file_basename}){
  #  my  $file_basename;
  if (!defined $self->{file_basename}) {
    my $file_basename = $alignment_nex_filename;
    $file_basename =~ s/[.]nex$//; # delete .nex ending
    $self->{file_basename} = $file_basename;
  }
  my $n_runs = $self->{n_runs};
  my $burnin_frac = $self->{burnin_frac};
  my $n_temperatures = $self->{n_temperatures};
  my $temperature_gap = $self->{temperature_gap};
  my $sample_freq = $self->{sample_freq};
  my $print_freq = $self->{print_freq};
  my $chunk_size = $self->{chunk_size};
  my $fixed_pinvar = $self->{fixed_pinvar};
  my $prset_pinvarpr = (defined $fixed_pinvar)? "prset pinvarpr=fixed($fixed_pinvar);\n" : '';

  my $begin_piece =
    "begin mrbayes;\n" .
      "set autoclose=yes nowarn=yes;\n";
  my $seed_piece = '';
  if (defined $self->{seed}) {
    my $seed = $self->{seed}; $seed_piece .=  "set seed=$seed;\n";
  } 
  if (defined $self->{swapseed}) {
    my $swapseed = $self->{swapseed}; $seed_piece .= "set swapseed=$swapseed;\n";
  }
  my $middle_piece =  "execute $alignment_nex_filename;\n" .
    "set precision=6;\n" .
      "lset rates=invgamma;\n" .
	"prset aamodelpr=fixed(wag);\n" .
	  "$prset_pinvarpr" . 
	    # "prset pinvarpr=fixed(0.15);\n" .
	    "mcmcp minpartfreq=0.02;\n" . # bipartitions with freq. less than this are not used in the  diagnostics (default is 0.10)
	      "mcmcp allchains=yes;\n" .
		"mcmcp burninfrac=$burnin_frac;\n" .
		  "mcmcp nchains=$n_temperatures;\n" .
		    "mcmcp nruns=$n_runs;\n" .
		      "mcmcp temp=$temperature_gap;\n" .
			"mcmcp samplefreq=$sample_freq;\n" .
			  "mcmcp printfreq=$print_freq;\n" .
			    #  "mcmcp filename=$file_basename;\n" .
			    "mcmcp checkpoint=yes checkfreq=$chunk_size;\n";
  my $end_piece = "sump;\n" . "sumt;\n" . "end;\n";

  $self->{mrbayes_block1} = 
    $begin_piece . $seed_piece .
      $middle_piece . "mcmc ngen=$chunk_size;\n" .
	$end_piece;

  $self->{mrbayes_block2} = 
    $begin_piece . $middle_piece .
      "mcmc append=yes ngen=$chunk_size;\n" .
	$end_piece;

  $self->setup_id_species_map();

  return $self;
}

sub run{
  my $self = shift;

  my $chunk_size = $self->{chunk_size};
  my $ngen = $chunk_size;
  my $mrbayes_block1 = $self->{mrbayes_block1};

  open my $fh, ">tmp_mrb1.nex";
  print $fh "$mrbayes_block1";
  close $fh;

  my $mb_output_string = `mb tmp_mrb1.nex`;
  $self->{ngens_run} = $ngen;

  my $mc3swap_filename = $self->{file_basename} . ".mc3swap";
  open my $fhmc3, ">$mc3swap_filename";
  print $fhmc3 "$ngen ", $self->extract_swap_info($mb_output_string), "\n";

  open $fh, ">mb1.stdout";
  print $fh "$mb_output_string \n";
  close $fh;

  my ($converged, $conv_string) = $self->test_convergence($self->{file_basename});
  my $converge_count += $converged;
  open my $fhc, ">MB.converge";
  print $fhc "$ngen $converge_count  $conv_string\n";

  foreach (my $i=1; $i>0; $i++) { # infinite loop
    $ngen += $chunk_size;
    my $mrbayes_block2 = $self->{mrbayes_block2};
    $mrbayes_block2 =~ s/ngen=\d+;/ngen=$ngen;/; # subst in the new ngen

    open $fh, ">tmp_mrb2.nex";
    print $fh "$mrbayes_block2";
    close $fh;

    $mb_output_string =  `mb tmp_mrb2.nex`;

    $self->{ngens_run} = $ngen;

    print $fhmc3 "$ngen ", $self->extract_swap_info($mb_output_string), "\n";
    open $fh, ">mb2.stdout";
    print $fh "$mb_output_string \n";
    close $fh;

    ($converged, $conv_string) = $self->test_convergence($self->{file_basename});
    $converge_count += $converged;
    print $fhc "$ngen $converge_count  $conv_string\n";
    last if($converge_count >= $self->{converged_chunks_required});
  }
  close $fhmc3; close $fhc;
  return;
}


sub splits_convergence{
  my $self = shift;
  my $file_basename = shift;	# e.g. fam9877
  my $min_hits = $self->{splits_min_hits}; # ignore splits with fewer hits than this.
  my $max_ok_stddev = $self->{splits_max_ok_stddev}; # convergence is 'ok' for a split if stddev < this.
  my $max_ok_avg_stddev = $self->{splits_max_ok_avg_stddev}; # convergence is 'ok' for a split if stddev < this.
  #print "in splits convergence file basename: ", $file_basename, "\n"; #exit;

  my $filename = $file_basename . ".nex.tstat";
  # print "filename: $filename\n";
  open my $fh, "<$filename";
  my @lines = <$fh>;

  my ($avg_stddev, $count, $bad_count) = (0, 0, 0);
  foreach (@lines) {
    #   print;
    next unless(/^\s*\d/); # skip if first non-whitespace is not numeral.
    my @cols = split(" ", $_);
    my $hits = $cols[1]; my $stddev = $cols[3];
    #  print "$hits, $min_hits, $stddev\n";
    last if($hits < $min_hits);
    $count++;
    $avg_stddev += $stddev;
    if ($stddev > $max_ok_stddev) {
      $bad_count++;
      next;
    }
  }
  $avg_stddev = ($count == 0)? 100 : $avg_stddev/$count;
  my $splits_converged = ($bad_count == 0  and  $avg_stddev < $max_ok_avg_stddev);
  return ($splits_converged, $count, $bad_count, $avg_stddev);
}


sub modelparam_convergence{	# look at numbers in *.pstat file
  # to test convergence
  my $self = shift;
  my $file_basename = shift;
  my $min_ok_ESS = $self->{modelparam_min_ok_ESS};
  my $max_ok_PSRF = $self->{modelparam_max_ok_PSRF};
  my $max_ok_KSD = $self->{modelparam_max_ok_KSD};
  my $string = '';
  my $ngens_skip = int($self->{burnin_frac} * $self->{ngens_run});

  open my $fh, "<$file_basename.nex.pstat";
  my @lines = <$fh>;
  close $fh;
  my $discard = shift @lines;
  my $count_param_lines = 0;
  my $KSD_datacol = 1;
  my $LL_KSD = $self->KSDmax($ngens_skip, 1);
  my $n_bad = ($LL_KSD <= $max_ok_KSD)? 0 : 1;
  my @KSDmaxes = ($LL_KSD);
  #  $n_bad++ if($LL_KSD > $self->{modelparam_max_ok_KSD}); # require LogL just to pass KSD test
  foreach (@lines) {
    my @cols = split(" ", $_);
    my ($avgESS, $PSRF) = @cols[7, 8]; # col 6 is the min ESS among the runs, col 7 is avg.
    next unless($avgESS =~ /^\d*[.]?\d+/ and $PSRF =~ /^\d*[.]?\d+/);
    $KSD_datacol++; # 2,3,4,... the params in pstat file are in cols 2,3,4,... in *.run?.p
    my $KSDmax = $self->KSDmax($ngens_skip, $KSD_datacol);
    push @KSDmaxes, $KSDmax;
    $string .= "$avgESS $PSRF ";
    if ($avgESS < $min_ok_ESS
	or $PSRF > $max_ok_PSRF
	or  $KSDmax > $max_ok_KSD) {
      $n_bad++;
    }
  }
  $string .=  join(" ", map sprintf("%5.3f", $_), @KSDmaxes); #    join(" ", @KSDmaxes);
  return ($n_bad, $string);
}

sub test_convergence{
  my $self = shift;
  my $file_basename = shift;	# e.g. fam9877.nex

  my ($splits_converged, $splits_count, $splits_bad_count, $splits_avg_stddev) =
    $self->splits_convergence($file_basename);
  my ($modelparam_n_bad, $modelparam_string) =
    $self->modelparam_convergence($file_basename);
  my $ngens_skip = int($self->{burnin_frac} * $self->{ngens_run});
 
  my $conv_string = "$splits_count $splits_bad_count $splits_avg_stddev " .
    " $modelparam_string  $modelparam_n_bad  ";
 
  my $converged = ($splits_converged  and  $modelparam_n_bad == 0);
 
  return ($converged? 1 : 0, $conv_string);
}


sub extract_swap_info{
  my $self = shift;
  my $mb_stdout_string = shift;
  my @mb_stdout_lines = split("\n", $mb_stdout_string);
  my $n_lines_to_extract = 0;
  my $extract_next_n = 0;
  my $n_runs = undef;
  my $n_chains = undef;
  my $out_string = '';
  foreach (@mb_stdout_lines) {
    if (/number of chains to (\d+)/) {
      $n_chains = $1;
      $n_lines_to_extract = $n_chains + 4;
      last if(defined $n_runs);
    } elsif (/number of runs to (\d+)/) {
      $n_runs = $1;
      last if(defined $n_chains);
    }

  }
  my $run;
  my %run_string = ();
  foreach (@mb_stdout_lines) {
    if (/Chain swap information for run (\d+)/) {
      $run = $1;
      $extract_next_n = $n_lines_to_extract;
    }
    $out_string .= "$_\n" if($extract_next_n > 0);
    $extract_next_n--;
    if ($extract_next_n == 0) {
      $run_string{$run} = $out_string;
      $out_string = '';
      last if($run == $n_runs);
    }
  }
  $out_string = '';

  foreach (keys %run_string) {
    #print "$_  ", $run_string{$_}, "\n";
    my @lines = split("\n", $run_string{$_});
    splice @lines, 0, 4;
    #  print join("\n", @lines);

    my %ij_swap_pA = ();
    my %ij_swap_tries = ();
    foreach my $i (1..$n_chains) {
      my $l = $lines[$i-1];
      $l =~ s/^\s*\d+\s+[|]\s+//;
      my @xs = split(" ", $l);
      my $n_ntry = $i-1;
      my $n_pA = $n_chains-$i;
      foreach my $j (1..$n_ntry) {
	#	print "swap_tries key: [$i $j]\n";
	$ij_swap_tries{"$i $j"} = shift @xs;
      }
      foreach (1..$n_pA) {
	my $j = $_ + $i;
	#	print "swap_pA key: [$j $i]\n";
	$ij_swap_pA{"$j $i"} = shift @xs;
      }
    }				# loop over chains
    my %ij_swap_accepts = ();
    # my @sijs = sort {$a cmp $b} keys %ij_swap_tries;
    # foreach (@sijs) {

    foreach my $diff (1..$n_chains-1) {
      foreach my $i (1..$n_chains-1) {
	my $j = $i + $diff;

	last if($j > $n_chains);
	my $key = "$j $i";
	#	print "i,j: $i, $j, key: [$key] \n";
	if (exists $ij_swap_pA{$key} and exists $ij_swap_tries{$key}) {
	  $ij_swap_accepts{$key} = $ij_swap_tries{$key} * $ij_swap_pA{$key};
	  $out_string .= int($ij_swap_accepts{$key}+0.5) . " " . $ij_swap_tries{$key} . "  ";
	} else {
	  warn "key $key present in neither ij_swap_tries nor ij_swap_pA.\n";
	}
      }
      $out_string .= ' ';
    }
    $out_string .= ' ';
  }				# loop over runs
  return $out_string;
}


sub KSDmax{	     # This does all pairwise comparisons between runs
  # for one of the params in the *.run?.p files
  # and returns the largest Kolmogorov-Smirnov D
  my $self = shift;

  my $ngen_skip = shift || 0;
  my $datacol = shift;		# data column to use.
  $datacol = 1 if(!defined $datacol);

  my $bigneg = -1e300;

  my $file_basename = $self->{alignment_nex_filename}; # e.g. fam9877
  # store data in hashes
  my @val_count_hrefs = ({}, {}); #
  my @counts = (0, 0);
  my @files = `ls $file_basename.run?.p`;
  my $runs_to_analyze = scalar @files;
  warn "in KSDmax. n_runs: ", $self->{n_runs}, " *.p files found: ", $runs_to_analyze, " should agree, using min of the two.\n" if($self->{n_runs} != $runs_to_analyze);
  $runs_to_analyze = min($runs_to_analyze, $self->{n_runs});

  foreach my $irun (1..$runs_to_analyze) {
    my $i = $irun - 1;
    my $filename = "$file_basename.run" . $irun . ".p"; 
    open my $fh, "<$filename";
    while (<$fh>) {
      my @cols = split(" ", $_);
      # skip non-numerical stuff.
      next unless($cols[0] =~ /^\d+$/); 
      my ($ngens, $x) = @cols[0,$datacol];
      next if($ngens < $ngen_skip);
      $val_count_hrefs[$i]->{$x}++;
      $counts[$i]++;
    }
    close $fh;
  }

  # get cumulative distributions:
  my @val_cumeprob_hrefs = ();
  foreach my $i (0..$runs_to_analyze-1) {
    push @val_cumeprob_hrefs, cumulative_prob($val_count_hrefs[$i], $counts[$i]);
  }

  my @KSDs = (); # Kolmogorov-Smirnov D for each pairwise comparison between runs
  foreach my $i (0..scalar @files - 2) {
    foreach my $j ($i+1..scalar @files - 1) {
      push @KSDs, Kolmogorov_Smirnov_D(@val_cumeprob_hrefs[$i,$j]);
    }
  }
  return max(@KSDs);
}



sub retrieve_param_samples{
  # read data from  run?.p files
  # store in 
  my $self = shift;
  my $pattern = shift || $self->{alignment_nex_filename}; # e.g. fam9877.nex
  my $p_files = `ls $pattern.run?.p`;
  my @p_infiles = split(" ", $p_files);
  my $n_runs_p = scalar @p_infiles;

  # the following has one elem for each run, and it is
  # a hash ref, with generation numbers as keys, 
  # parameter strings (logL, TL, alpha ...) as values
  my @gen_param_hashes = ();
  foreach (1..$n_runs_p) {
    push @gen_param_hashes, {};
  }
  #my $p_run = 1;
  foreach my $i_run_p (1..$n_runs_p) {
    my $p_file = "$pattern.run$i_run_p.p";
    open  my $fhp, "<$p_file";

    while (my $line = <$fhp>) {
      chomp $line;
      next unless($line =~ /^\s*(\d+)/);
      #  print "$line \n";
      my @cols = split(" ", $line);
      my $generations = shift @cols;
      my $param_string = join("  ", @cols);
      $gen_param_hashes[$i_run_p-1]->{$generations} = $param_string;
    }
    $i_run_p++;
  }
  return \@gen_param_hashes;
}
# end of reading in parameter values

sub retrieve_topology_samples{
  my $self = shift;
my $pattern = shift || $self->{alignment_nex_filename}; # e.g. fam987?.nex

 my $t_files = `ls $pattern.run?.t`;
  my @t_infiles = split(" ", $t_files);
  my $n_runs = scalar @t_infiles;
  my @gen_ntopo_hashes = ();
  foreach (1..$n_runs) {
    push @gen_ntopo_hashes, {};
  }
my %newick_number_map = ();
my %number_newick_map = ();
  my $topology_count = 0;
  foreach my $i_run (1..$n_runs) {
    my $t_infile = "$pattern.run$i_run.t";
    open my $fh, "<$t_infile";

    # read trees in, remove branch lengths, store in array

    while (my $line = <$fh>) {
      chomp $line;
      if ($line =~ s/tree gen[.](\d+) = .{4}\s+//) {
	my $newick = $line;
	my $generation = $1;
	$newick =~ s/:[0-9e\-.]*(,|[)])/$1/g; # remove branch lengths
	#print "[$newick]\n";
	$newick =~ s/^\s+//; 
	$newick =~ s/;\s*//;
	$newick = order_newick($newick);
	#	print $newick, "\n";
	#		exit;
	if (!exists $newick_number_map{$newick}) {
	  $topology_count++;
	  $newick_number_map{$newick} = $topology_count; # 1,2,3,...
	  $number_newick_map{$topology_count} = $newick;
	}
	$gen_ntopo_hashes[$i_run-1]->{$generation} = $newick_number_map{$newick};
      }
    } # now $gen_ntopo_hashes[$i_run] is hash ref with generations as keys, and topology numbers as values.
  }
return (\@gen_ntopo_hashes, \%newick_number_map, \%number_newick_map);
}


sub retrieve_number_id_map{
  my $self = shift;
  my $pattern = shift || $self->{alignment_nex_filename}; # e.g. fam9877.nex

  my $trprobs_file = "$pattern.trprobs";
  open my $fh, "<$trprobs_file";

  my %number_id_map = ();
  while (my $line = <$fh>) {
    last if($line =~ /^\s*tree\s+tree_/);
    if ($line =~ /^\s*(\d+)\s+(\S+)/) {
      my $number = $1;
      my $id = $2;
      $id =~ s/[,;]$//;		# delete final comma
      $number_id_map{$number} = $id;
    }
  }
  return \%number_id_map;
}


sub count_topologies{
my $self = shift;
my $gen_ntopo_hrefs = shift;
my %topo_count = (); # key: topology number, value: arrayref with counts in each run
# e.g. $topo_count{13} = [3,5] means that topo 13 occurred 3 times in run1, 5 times in run 2.
my $total_trees = 0;
foreach my $i_run (1..scalar @$gen_ntopo_hrefs) {
  my $gen_ntopo = $gen_ntopo_hrefs->[$i_run-1];
  my $trees_read_in = scalar keys %{$gen_ntopo};
  print "Run: $i_run. Trees read in: $trees_read_in\n";
  # store trees from array in hash, skipping burn-in
  my $n_burnin = int($self->{burnin_frac} * $trees_read_in);
#  print "trees read in: $trees_read_in. Post burn-in: ", $trees_read_in - $n_burnin, "\n";
  my @sorted_generations = sort {$a <=> $b} keys %{$gen_ntopo};
  foreach my $i_gen (@sorted_generations[$n_burnin..$trees_read_in-1]) {
    my $topo_number = $gen_ntopo->{$i_gen};
    if (!exists $topo_count{$topo_number}) {
      my @zeroes = ((0) x scalar @$gen_ntopo_hrefs);
      $topo_count{$topo_number} = \@zeroes;
    }
    $topo_count{$topo_number}->[$i_run-1]++;
    $total_trees++;
  }
  $i_run++;
}
return (\%topo_count, $total_trees);
}

sub restore_ids_to_newick{
  my $self = shift;
  my $newick = shift;
  my $number_id_map = shift;

  foreach my $number (keys %$number_id_map) {
    my $id = $number_id_map->{$number};
$id .= '[species=' . $self->{id_species_map}->{$id} . ']';
    $newick =~ s/([(,])$number([,)])/$1$id$2/;
  }
  return $newick;
}

sub setup_id_species_map{
my $self = shift;
my $file = $self->{alignment_nex_filename};
#$file =~ s/[.]nex/.fasta/;
open my $fh, "<$file";
while (my $line = <$fh>){
 # print $line;
  next unless($line =~ /^(\S+)\[species=(\S+)\]/);
  my $id = $1;
my $species = $2;
#print $line;
  $self->{id_species_map}->{$id} = $species;
  print "$id  $species \n";
}
#exit;
return;
}

my $bigneg = -1e300;

# given a set of numbers (some of which may occur more than once), which
# are stored as keys in a hash, with the values being how many times they occur
# or more generally whatever weights you want, sort the keys and get the
# cumulative distribution.
sub cumulative_prob{
  my $val_weight_href = shift; # hashref, key: numbers, values: weights.
  my $sum_weights = shift;
  my $val_cumeprob_href = { $bigneg => 0};
  my $cume_prob = 0;
  foreach (sort {$a <=> $b} keys %{$val_weight_href}) {
    $cume_prob += $val_weight_href->{$_}/$sum_weights;
    $val_cumeprob_href->{$_} = $cume_prob;
    #		print "$i $_ $cume_prob ", $val_count_hashes[$i]->{$_}, "\n";	
  }
  #	print "\n";
  return $val_cumeprob_href;
}


sub Kolmogorov_Smirnov_D{
# get the maximum difference between two empirical cumulative distributions.
# Arguments are two hashrefs, each representing an empirical cumulative distribution.
# Each key is a data point (a real number), and the corresponding hash value is
# the proportion of data pts <= to it. So the largest value should be 1.
	my $val_cumeprob1 = shift; 
	my $val_cumeprob2 = shift;
	my @sorted_vals1 = sort {$a <=> $b} keys %{$val_cumeprob1};
	my @sorted_vals2 = sort {$a <=> $b} keys %{$val_cumeprob2};

	my ($i1, $i2) = (0, 0);

	my $size1 = scalar @sorted_vals1;
	my $size2 = scalar @sorted_vals2;

	my $D = 0;
	while(1){
		my ($xlo1, $xhi1) = ($sorted_vals1[$i1], $sorted_vals1[$i1+1]);
		my ($xlo2, $xhi2) = ($sorted_vals2[$i2], $sorted_vals2[$i2+1]);
		die "$xlo1 > $xhi2 ??\n" if($xlo1 > $xhi2);
		die "$xlo2 > $xhi1 ??\n" if($xlo2 > $xhi1);

		my ($cume_prob1, $cume_prob2) = ($val_cumeprob1->{$xlo1}, $val_cumeprob2->{$xlo2});
		my $abs_diff = abs($cume_prob1 - $cume_prob2);
		$D = $abs_diff if($abs_diff > $D);
		if($xhi1 <= $xhi2){
			$i1++;
		}elsif($xhi2 <= $xhi1){
			$i2++;
		}else{
			die "$xhi1 xhi2 should be numerical.\n";
		}
		last if($i1 == $size1-1);
		last if($i2 == $size2-1);
	}
	return $D;
}

# operates on a newick of form (3,(6,4))
# i.e. no whitespace, no branch lengths, ids must be numbers.
# so just parens, commas and numbers
# puts the leaves in order, such that at each node the
# subtree with smaller value is on left. The value of an
# internal node is the min of the values of the two child
# nodes, and the value of a leave is its id, which must be a number.
sub order_newick{
  my $newick = shift;
  if ($newick =~ /^(\d+)$/) {	# subtree is leaf!
    return ($1, $newick);
  } else {			# subtree has > 1 leaf.
    my %label_newick = ();
    $newick =~ /^[(](.*)[)]$/;
    my @newick_chars = split('',$1); # without surrounding ()
    my $lmr_paren_count = 0;
    my ($il, $ir) = (0, 0);
    my $n_chars = scalar @newick_chars;
    my $min_label = 10000000;
    foreach (@newick_chars) {
      die "$_ ", $newick_chars[$ir], " not same!\n" if($_ ne $newick_chars[$ir]);
      if ($_ eq '(') {
	$lmr_paren_count++;
      }
      if ($_ eq ')') {
	$lmr_paren_count--;
      }

      if (($ir == $n_chars-1) or ($_ eq ',' and $lmr_paren_count == 0)) { #split
	my $ilast = ($ir == $n_chars-1)? $ir : $ir-1;
	my $sub_newick = join('', @newick_chars[$il..$ilast]);
	#       print "subnewick $sub_newick\n";
	my ($label, $ordered_subnewick) = order_newick($sub_newick);
	$label_newick{$label} = $ordered_subnewick;
	$min_label = min($min_label, $label);
	$il = $ir+1; $ir = $il; # skip the ','
      } else {
	$ir++;
      }
    }				# loop over chars in @newick_chars
    my $ordered_newick = '';
    foreach (sort {$a <=> $b} keys %label_newick) {
      $ordered_newick .= $label_newick{$_} . ",";
    }
    $ordered_newick =~ s/,$//;
    $ordered_newick = '(' . $ordered_newick . ')';
    return ($min_label, $ordered_newick);
  }
  die "shouldnt get here, in order_newick\n";
}


1;


