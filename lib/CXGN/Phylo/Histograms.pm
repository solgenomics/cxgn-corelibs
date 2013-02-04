package Histograms;
use strict;
use List::Util qw ( min max sum );

# for histogramming Mrbayes chain output

sub  new {
  my $class = shift;
  my $arg = shift;
  my $default_arguments = {
			   'title' => 'untitled',
			   'min_gen' => 0,
#			   'chain_data_obj' => undef,
			  };
  my $self = bless $default_arguments, $class;

  foreach my $option (keys %$arg) {
    warn "Unknown option: $option in Histograms constructor.\n" if(!exists $self->{$option});
    if (defined $arg->{$option}) { # if arg is undef, leaves default in effect
      $self->{$option} = $arg->{$option};
    }
  }
#  my $n_hist = $self->{chain_data_obj}->{n_runs};

$self->{generations} = [];
$self->{run_gen_value} = []; # array of gen:value hashrefs
  $self->{histograms} = []; # indices 0,1,2...; values are bin:count hashrefs representing histograms
  $self->{sum_histogram} = {};
$self->{rearr_histograms} = {}; # same info as histograms, but hashref with keys: bins; values array refs of counts for runs.
return $self;
}

sub populate{
  my $self = shift;
  my $run_gen_value = shift; # ref to array of gen/value hashrefs. $rgv->[0]->{120} is value for run 0, gen 120
  my $min_gen = shift || 0;
#  print "TOP of populate.\n", join(',', @{$self->{generations}}), "\n";
  while (my ($run, $g_v) = each @$run_gen_value) {
    #  while (my ($g, $v) = each %$g_v) {
    $self->{run_gen_value}->[$run] = {} if(!defined $self->{run_gen_value}->[$run]);
    for my $g (sort {$a <=> $b} keys %$g_v) {
      my $v = $g_v->{$g};
      #  print "gen mingen: $g  $min_gen   run $run ;\n";
      if ($g >= $min_gen) {
	# my $min_g = min(@{$self->{generations}});
	# my $max_g = max(@{$self->{generations}});
	# if (1 or ($min_g < 50 and $max_g > 500)) {
	#   print "IN Populate. pushing gen $g. ", "min/max gen in generations: ", $min_g, "  ", $max_g, "\n";
	#   #sleep(1);
	# }

	push @{$self->{generations}}, $g if($run == 0);
	# my @unsort = @{$self->{generations}};
	# my @sort = sort { $a <=> $b } @unsort;
	# my $u = join(',', @unsort);
	# my $s = join(',', @sort);
	# if ($u ne $s) {
	#   print " $u \n $s \n"; exit;
	# }
	$self->{run_gen_value}->[$run]->{$g} = $v;
	$self->{histograms}->[$run]->{$v}++;
	$self->{sum_histogram}->{$v}++;
#	print " run $run ; gen: $g, value $v  count: ", $self->{histograms}->[$run]->{$v},
#	  " total in bin: ", $self->{sum_histogram}->{$v}, "\n";
      }
    }
  }
}

sub remove{
  my $self = shift;
  #  my $run_gen_value = shift;
  my $max_gen_to_remove = shift || 0;
 
#  print "SSSSSSSSSS: $max_gen_to_remove \n";
   while ($self->{generations}->[0] <= $max_gen_to_remove) {
      my $g = shift @{$self->{generations}};
#      print "000000000000000: gen removed: $g. zeroeth elem of generations: ", $self->{generations}->[0], "\n";
  while (my ($run, $g_v) = each @{$self->{run_gen_value}}) {
#    print "in remove, run: $run. gen: $g \n";
 #   print join("; ", sort {$a <=> $b} keys %$g_v), "\n";
#print "IN REMOVE. min/max gens: ", min(keys %$g_v), "  ", max(keys %$g_v), "\n";
    # for my $gg (sort {$a <=> $b} keys %$g_v) {
    #   my $vv = $g_v->{$gg};
    #   #   print "g,v: $gg, $vv \n";
    # }

my $v = $g_v->{$g};
      delete $g_v->{$g};
#     printf ("in remove. run, gen, category: %i  %i  %i \n\n",$run,  $g,  $v);
#      print STDERR "in remove. run, g, v: $run, $g, $v \n\n";
#sleep(1) if($v == 0);
      $self->{histograms}->[$run]->{$v}--;
      $self->{sum_histogram}->{$v}--;
      #  }
      #    for my $g (@$gens_to_remove) {
    }
  }
 
}

sub adjust_weight{
  my $self = shift;
  my $hist_number = shift;	# 0,1,2,...
  my $category = shift;
  my $increment = shift || 1;
  $self->{histograms}->[$hist_number]->{category} += $increment;
  $self->{sum_histogram}->{category} += $increment;
}

sub n_histograms{
  my $self = shift;
  my $n_hist = shift;
  if (defined $n_hist) {
    $self->{n_histograms} = $n_hist;
  }
  return $self->{n_histograms};
}

sub title{
  my $self = shift;
  my $title = shift;
  if (defined $title) {
    $self->{title} = $title;
  }
  return $self->{title};
}

 sub histogram_string{
    # argument: hashref, keys: category labels; values: array ref holding weights for the histograms 
    # (e.g. for different runs)
    # Output: 1st col: category labels, next n_runs cols: weights, last col sum of weights over runs.
    # supply ref to array of categories in desired order, or will sort bins by total weight.
my $self = shift;
    my $run_cat_weight = $self->{histograms};
my $sum_cat_weight = $self->{sum_histogram};
    my $s_categories = shift || undef;
    my @sorted_categories = (defined $s_categories)?
      @{$s_categories} :
	sort {$sum_cat_weight->{$b} <=> $sum_cat_weight->{$a} } keys %$sum_cat_weight;
    my $string = "";
    my $total = 0;
    for my $cat (@sorted_categories) {
      $string .= sprintf("%6s  ", $cat);
      for my $c_w (@$run_cat_weight) {
	$string .=  sprintf("%6i  ", $c_w->{$cat});
      }
      my $sum_weight =  $sum_cat_weight->{$cat};
      $string .= sprintf("%6i \n", $sum_weight);
      $total += $sum_weight;
    }
    $string .= "total  $total \n";
    return $string;
  }

 sub rearrange_histograms{ # go from an array of bin:count hashes to hash of bin:(count array).
   my $self = shift;
   my @histograms = @{$self->{histograms}}; # array ref of bin:count hashrefs. 
   my $n_runs = scalar @histograms;
   my $rearr_histograms = {};
   while (my ($i_run, $histogram) = each @histograms) {
     while (my ($bin, $count) = each %$histogram) {
       if (!exists $rearr_histograms->{$bin}) {
	 $rearr_histograms->{$bin} = [(0) x $n_runs];
       }
       $rearr_histograms->{$bin}->[$i_run] = $histogram->{$bin};
#       print "K:            $i_run, $bin, ",  $rearr_histograms->{$bin}->[$i_run], "\n";
     }
   }
   $self->{rearr_histograms} = $rearr_histograms;
 }

 sub minweight_rebin {
   # input here is already binned
   # the idea here is to make each bin have at least some fraction of total weight (2% is default)
   # by possibly lumping together some bins.
   my $self = shift;
   my $target_bin_weight = shift || 0.02;
   my $label_weightslist = $self->{rearr_histograms};

   my %label_sumweights = ();
   while ( my ( $l, $ws ) = each %$label_weightslist ) {
     $label_sumweights{$l} = sum(@$ws);
   }
   my @sorted_labels =
     sort { $label_sumweights{$a} <=> $label_sumweights{$b} } # sort by weight; small to large
       keys %$label_weightslist;			      #

   my $total_hits = sum( map( @{ $label_weightslist->{$_} }, @sorted_labels ) );
   my $run0_hits  = sum( map( $label_weightslist->{$_}->[0], @sorted_labels ) );
   my $n_runs     = scalar @{ $label_weightslist->{ $sorted_labels[0] } };

   my $result       = {};
   my $cume_weight  = 0;
   my @cume_weights = ( (0) x $n_runs );
   my $cume_label = '';
   foreach my $label (@sorted_labels) {	# loop over categories
     my @weights = @{ $label_weightslist->{$label} };
     @cume_weights = map { $cume_weights[$_] + $weights[$_] } 0 .. $#weights;
     my $weight = sum(@weights); # number of hits for this categories, summed over runs.
     $cume_weight += $weight;
     $cume_label .= $label . '_';
     if ( $cume_weight >= $target_bin_weight * $total_hits ) {
       my @copy = @cume_weights;
       $cume_label =~ s/_$//;
       $result->{$cume_label} = \@copy;
       $cume_weight = 0;
       @cume_weights = ( (0) x $n_runs );
       $cume_label = '';
     }
   }
   return $result;
 }

 sub avg_L1_distance { # just find for histograms as given, no rebinning.
   my $self = shift;
   my $label_weightslist = shift || $self->{rearr_histograms}; # hashref. keys are category labels; values are refs to arrays of weights
   # one weight for each histogram being compared (e.g. 1 for each MCMC chain)
   my $L1 = 0;
   my @labels = keys %$label_weightslist; #
   my $n_runs = scalar @{ $label_weightslist->{ $labels[0] } };
   if ( $n_runs > 0) {
     my ( $numerator, $denominator ) = ( 0, 0 );
     foreach my $label (@labels) { # loop over topologies
       my @weights = sort { $b <=> $a } @{ $label_weightslist->{$label} };

 #      print "XXX bin, weights: $label (", join(",",  @{ $label_weightslist->{$label} }), ")\n";
       my $coeff = $n_runs - 1;
       for my $run_weight (@weights) { # loop over runs
	 my $sum_abs_diffs = $coeff * $run_weight;
	 $numerator   += $sum_abs_diffs;
	 $denominator += $run_weight;
	 $coeff -= 2;
       }
     }
     $denominator *= ( $n_runs - 1 );
     $L1 = $numerator / $denominator;
   }
   return $L1;
 }



1;
