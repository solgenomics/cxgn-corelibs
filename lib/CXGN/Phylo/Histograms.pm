package CXGN::Phylo::Histograms;
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
#			   'binned' => 1, # by default, will define bins, but data into them.
			   'n_bins' => undef,
			   'binning_lo_val' => undef,
			   'bin_width' => undef
			  };
  my $self = bless $default_arguments, $class;

  foreach my $option (keys %$arg) {
    warn "Unknown option: $option in Histograms constructor.\n" if(!exists $self->{$option});
    if (defined $arg->{$option}) { # if arg is undef, leaves default in effect
# print STDERR "In Histograms constructor, setting option $option to ", $arg->{$option}, "\n";
      $self->{$option} = $arg->{$option};
    }
  }
  #  my $n_hist = $self->{chain_data_obj}->{n_runs};

  #$self->{generations} = [];
  #$self->{run_gen_value} = []; # array of gen:value hashrefs
  $self->{histograms} = []; # indices 0,1,2...; values are bin:count hashrefs representing histograms
  $self->{sum_histogram} = {};
  $self->{rearr_histograms} = {}; # same info as histograms, but hashref with keys: bins; values array refs of counts for runs.
  return $self;
}

sub binning_info_string{
  my $self = shift;
  my $string = '';
  return if(! $self->{binned});
  $string .= "Binning low value: ", $self->{binning_lo_val}, ". Bin width: ", $self->{bin_width}, " \n";
  return $string;
}

sub populate{
  my $self = shift;
  my $run_gen_value = shift; # ref to array of gen/value hashrefs. $rgv->[0]->{120} is value for run 0, gen 120
  my $min_gen = shift || 0;
  while (my ($run, $g_v) = each @$run_gen_value) {
    for my $g (sort {$a <=> $b} keys %$g_v) {
      my $v = $g_v->{$g};
      if ($g >= $min_gen) {
#	$v = $self->bin_the_point($v);
	$self->{histograms}->[$run]->{$v}++;
	$self->{sum_histogram}->{$v}++;
      }
    }
  }
}

sub set_min_max_bins{
  my $self  = shift;
  my ($min_bin, $max_bin) = @_;
  $self->{min_bin} = $min_bin;
  $self->{max_bin} = $max_bin;
}

sub adjust_cat_count{
  my $self = shift;
  my $hist_number = shift;	# 0,1,2,...
  my $category = shift;
  my $increment = shift;
  $increment = 1 if(!defined $increment);
  #my $category = $self->bin_the_point($value);
  #print "in adjust count $category, $value \n";
  # print STDERR "in adjust_count, run, cat, inc: $hist_number, $category, $increment \n";
  $self->{histograms}->[$hist_number]->{$category} += $increment;
  $self->{sum_histogram}->{$category} += $increment;
}

sub adjust_val_count{
my $self = shift;
 $self->adjust_cat_count(@_);
}



# sub get_count{
#   my $self = shift;
#   my $hist_number = shift;
#   my $category = shift;
#   return $self->{histograms}->[$hist_number]->{$category};
# }

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
  #  my $s_categories = shift || undef;
  my $sorting = shift || 'by_bin_number';
  my $run_cat_weight = $self->{histograms};
  my $sum_cat_weight = $self->{sum_histogram};
  my @sorted_categories;
  my @cats = keys %$sum_cat_weight;
  if ($sorting eq 'by_bin_number') {
    @sorted_categories = sort {$a <=> $b} keys %$sum_cat_weight;
  } else {
#    print "sort by bin weight\n";
    @sorted_categories = sort {$sum_cat_weight->{$b} <=> $sum_cat_weight->{$a} } keys %$sum_cat_weight;
    while($sum_cat_weight->{$sorted_categories[-1]} == 0){ # get rid of categories with count of zero.
      pop @sorted_categories;
    }
  }
  my $string = "# " . $self->title() . " histogram. n_bins: " . $self->{n_bins} . "  ";
  $string .= "binning_lo_val: " . $self->{binning_lo_val} . "  ";
  $string .= "bin_width: " . $self->{bin_width} . ".\n";

  my $total = 0;
  for my $cat (@sorted_categories) {
    my $cat_string = $self->category_string($cat);
    $string .= $cat_string;
    for my $c_w (@$run_cat_weight) {
      $string .=  sprintf("%6i  ", $c_w->{$cat});
    }
    my $sum_weight =  $sum_cat_weight->{$cat};
    $string .= sprintf("%6i \n", $sum_weight);
    $total += $sum_weight;
  }
  $string .= "#  total  $total \n";
  return $string;
}

sub category_string{
  my $self = shift;
  my $cat = shift;
  return sprintf("%6s  ", $cat);
}

sub rearrange_histograms{ # go from an array of bin:count hashes to hash of bin:(count array).
  my $self = shift;
  my @histograms = @{$self->{histograms}}; # array ref of bin:count hashrefs. 
  my $n_runs = scalar @histograms;
  my $rearr_histograms = {};
# print "in rearrange_histograms. n histograms: ", scalar @histograms, "\n";
  while (my ($i_run, $histogram) = each @histograms) {
    while (my ($bin, $count) = each %$histogram) {
      if (!exists $rearr_histograms->{$bin}) {
	$rearr_histograms->{$bin} = [(0) x $n_runs];
      }
      $rearr_histograms->{$bin}->[$i_run] = $histogram->{$bin};
    }
  }
  $self->{rearr_histograms} = $rearr_histograms;
}
sub minweight_L1{
  my $self = shift;
  my $minweight = shift || 0.02;
  return $self->avg_L1_distance($self->minweight_rebin($minweight));  # $self->minweight_rebin($minweight));
}

sub minweight_rebin {
  # input here is already binned
  # the idea here is to make each bin have at least some fraction of total weight (2% is default)
  # by possibly lumping together some bins.
  my $self = shift;
  my $target_bin_weight = shift || 0.02;
$self->rearrange_histograms();
  my $label_weightslist = $self->{rearr_histograms};
#print "in minweight_rebin. labels: ", join(", ", keys %$label_weightslist), "\n";

  my %label_sumweights = ();
  while ( my ( $l, $ws ) = each %$label_weightslist ) {
    $label_sumweights{$l} = sum(@$ws);
  }
  my @sorted_labels =
    sort { $label_sumweights{$a} <=> $label_sumweights{$b} } # sort by weight; small to large
      keys %$label_weightslist;
#print "in minweight_rebin. sorted labels: ", join(", ", @sorted_labels), "\n";

  my $total_hits = sum( map( @{ $label_weightslist->{$_} }, @sorted_labels ) );
  my $run0_hits  = sum( map( $label_weightslist->{$_}->[0], @sorted_labels ) );
  my $n_runs     = scalar @{ $label_weightslist->{ $sorted_labels[0] } };

  my $result       = {};
  my $cume_weight  = 0;
  my @cume_weights = ( (0) x $n_runs );
  my $cume_label = '';
  foreach my $label (@sorted_labels) { # loop over categories
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

sub binned_max_ksd{
  my $self = shift;
  my $n_runs = $self->{n_runs};
  my $max_ksd = 0;
  my @cume_probs = ((0) x $n_runs);
  my $total_counts = sum(values %{$self->{histograms}->[0]});

  # print "In binned_max_ksd. total counts: $total_counts. ", $self->{min_bin}, "  ", $self->{max_bin},  "\n";

  for my $bin ($self->{min_bin} .. $self->{max_bin}) {
    while (my ($i_run, $b_c) = each @{$self->{histograms}}) {
      $cume_probs[$i_run] += $b_c->{$bin};
    }
    my $cdf_range = max(@cume_probs) - min(@cume_probs);
    if ($cdf_range > $max_ksd) {
      $max_ksd = $cdf_range;
    }

  }
  $max_ksd /= $total_counts;
  return $max_ksd;
}




package CXGN::Phylo::BinnedHistograms;
use strict;
use List::Util qw ( min max sum );
use base qw/ CXGN::Phylo::Histograms /;
sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);
#  print STDERR "in BinnedHistograms constructor. \n";
warn "BinnedHistogram constructed with undefined binning parameters.\n" 
  if(!defined $self->{binning_lo_val} or !defined $self->{bin_width});

  return $self;
}

sub adjust_val_count{
  my $self = shift;
  my $hist_number = shift;	# 0,1,2,...
  my $value = shift;
  my $increment = shift;
  $increment = 1 if(!defined $increment);
  my $category = $self->bin_the_point($value);
  #print "in adjust count $category, $value \n";
  # print STDERR "in adjust_count, run, cat, inc: $hist_number, $category, $increment \n";
  $self->{histograms}->[$hist_number]->{$category} += $increment;
  $self->{sum_histogram}->{$category} += $increment;
}


sub bin_the_point{
  my $self = shift;
  my $value = shift;
  # return $value;
  # if (! $self->{binned}) {
  #   warn "Calling bin_the_point on non-binned histogram. Returning argument unmodified.\n";
  #   return $value;
  # } else {
  die "In bin_the_point. n_bins, binning_lo_val or bin_width not defined. \n" 
    if (!defined $self->{n_bins}  or  !defined $self->{binning_lo_val}  or  !defined $self->{bin_width});
  my $bin = int(($value - $self->{binning_lo_val})/$self->{bin_width});
  $bin = max($bin, 0);
  $bin = min($bin, $self->{n_bins}-1);
  $self->{min_bin} = min($bin, $self->{min_bin});
  $self->{max_bin} = max($bin, $self->{max_bin});
  return $bin;
  #  }
}


sub populate{
  my $self = shift;
  my $run_gen_value = shift; # ref to array of gen/value hashrefs. $rgv->[0]->{120} is value for run 0, gen 120
  my $min_gen = shift || 0;
  while (my ($run, $g_v) = each @$run_gen_value) {
    for my $g (sort {$a <=> $b} keys %$g_v) {
      my $v = $g_v->{$g};
      if ($g >= $min_gen) {
	$v = $self->bin_the_point($v);
	$self->{histograms}->[$run]->{$v}++;
	$self->{sum_histogram}->{$v}++;
      }
    }
  }
}

sub category_string{
  my $self = shift;
  my $cat = shift;
  my $lo_edge = $self->{binning_lo_val} + $cat*$self->{bin_width};
  return sprintf("%10.5f ", $lo_edge);
}

1;
