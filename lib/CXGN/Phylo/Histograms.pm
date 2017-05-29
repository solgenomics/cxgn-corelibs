package CXGN::Phylo::Histograms;
use strict;
use List::Util qw ( min max sum );
use Statistics::Descriptive;
use CXGN::Phylo::Cluster;
# for histogramming Mrbayes chain output
# Histograms can hold several histograms (1 per run)
# and provide some statistics on them, particularly
# how similar or different they are: avg L1 distance,
# Kolmogorov-Smirnov D statistic, etc.
sub new {
   my $class             = shift;
   my $arg               = shift;
   my $default_arguments = {
                            'title'          => 'untitled',
                            'min_gen'        => 0,
                            'n_bins'         => undef,
                            'binning_lo_val' => undef,
                            'bin_width'      => undef,
                            'n_histograms' => 1,
                            'set_size' => 1
                           };
   my $self = bless $default_arguments, $class;

   foreach my $option ( keys %$arg ) {
      warn "Unknown option: $option in Histograms constructor.\n"
        if ( !exists $self->{$option} );
      if ( defined $arg->{$option} ) { # if arg is undef, leaves default in effect
         $self->{$option} = $arg->{$option};
      }
   }

   my %histograms = ();

   $self->{histograms} = \%histograms;
   ; # keys are dataset ids; values are bin:count hashrefs representing histograms
   $self->{sum_histogram} = {};
   $self->{rearr_histograms} =
     {
     }; # same info as histograms, but hashref with keys: bins; values hash refs of setid:counts pairs. 
   return $self;
}

sub binning_info_string {
   my $self   = shift;
   my $string = '';
   return if ( !$self->{binned} );
   $string .=
     "Binning low value: "
       . $self->{binning_lo_val}
         . ". Bin width: "
           . $self->{bin_width} . " \n";
   return $string;
}

sub get_total_counts {
   my $self = shift;
   return $self->{total_in_histograms};
}

sub set_min_max_bins {
   my $self = shift;
   my ( $min_bin, $max_bin ) = @_;
   $self->{min_bin} = $min_bin;
   $self->{max_bin} = $max_bin;
}

sub adjust_cat_count {
   my $self        = shift;
   my $hist_id = shift;         # 0,1,2,...
   my $category    = shift;
   my $increment   = shift;
   $increment = 1 if ( !defined $increment );
   $self->{histograms}->{$hist_id} = {} if(!exists $self->{histograms}->{$hist_id});
   $self->{histograms}->{$hist_id}->{$category} += $increment;
   $self->{sum_histogram}->{$category}              += $increment;
   $self->{total_in_histograms}                     += $increment;
}

sub adjust_val_count {
   my $self = shift;
   $self->adjust_cat_count(@_);
}

sub n_histograms {
   my $self = shift;
   return scalar keys %{ $self->{histograms} };
}

sub title {
   my $self  = shift;
   my $title = shift;
   if ( defined $title ) {
      $self->{title} = $title;
   }
   return $self->{title};
}

sub histogram_string {

   # argument: hashref, keys: category labels; values: array ref holding weights for the histograms
   # (e.g. for different mcmc runs)
   # Output: 1st col: category labels, next n_histograms cols: weights, last col sum of weights over histograms.
   # supply ref to array of categories in desired order, or will sort bins by total weight.
   my $self = shift;
   my $sorting            = shift || 'by_bin_number';
   my $max_lines_to_print = shift || 1000000; #
   my $histogram_cat_weight = $self->{histograms};
   my $sum_cat_weight       = $self->{sum_histogram};
   my $min_count_to_show = 4;   #scalar @$histogram_cat_weight;

   my $extra_bit         = '';
   my @sorted_categories = keys %$sum_cat_weight;
   my $total_weight = sum( values %$sum_cat_weight );
   if ( $sorting eq 'by_bin_number' ) {
      @sorted_categories =
        sort { $a <=> $b } @sorted_categories; # keys %$sum_cat_weight;
   } else {                     # sort by avg bin count.
      @sorted_categories =
        sort { $sum_cat_weight->{$b} <=> $sum_cat_weight->{$a} }
          @sorted_categories;   # keys %$sum_cat_weight;
      while ( scalar @sorted_categories > 15 ) { # remove low-count categories, but leave min of 15 categories
         my $the_cat = $sorted_categories[-1];
         if ( exists $sum_cat_weight->{ $sorted_categories[-1] } ) {
            my $last_bin_count =
              $sum_cat_weight->{ $sorted_categories[-1] };
            if ( defined $last_bin_count ) {
            }

            last
              if ( $last_bin_count >= $min_count_to_show ); # get rid of categories with count of zero.
            pop @sorted_categories;
         } else {
            die "category not found: ", $sorted_categories[-1], "\n";
         }
      }
   }
   my $total_categories = scalar @sorted_categories;
   my $number_of_bins = ($self->{n_bins})? $self->{n_bins} : $total_categories;
   my $string = "# " . $self->title() . " histogram. ";
   if (defined $self->{n_bins}) {
      $string .= " n_bins: " . $number_of_bins. "  ";
      $string .= "binning_lo_val: " . $self->{binning_lo_val} . "  ";
      $string .= "bin_width: " . $self->{bin_width} . ".\n";
   } else {
      $string .= " categories: $total_categories.\n";
   }

   my ( $total, $shown_total ) = ( 0, 0 );
   my $count = 0;
   for my $cat (@sorted_categories) {
      my $sum_weight = $sum_cat_weight->{$cat};
      $total += $sum_weight;

      my $line_string = '';
      my $cat_string  = $self->category_string($cat);
      $line_string .= $cat_string;
      my $iii = 0;
      for my $c_w (values %$histogram_cat_weight) {
         my $the_weight = (exists $c_w->{$cat})? $c_w->{$cat} : 0; 
         $line_string .= sprintf( "%6i  ", $the_weight );
         $iii++;
      }
      $line_string .= sprintf( "%6i \n", $sum_weight );
      $count++;

      if ( $count > $max_lines_to_print ) {
         $extra_bit = "(Top $max_lines_to_print shown.)";
         last;
      } else {
         $string .= $line_string;
         $shown_total += $sum_weight;
      }
   }
   $string .= "#  total  $total ($shown_total shown).\n";
   $string .= "#  in " . $total_categories . " categories. $extra_bit \n";
   return $string;
}

sub category_string {
   my $self = shift;
   my $cat  = shift;
   return sprintf( "%6s  ", $cat );
}

sub rearrange_histograms
  { # go from an array of bin:count hashes to hash of bin:(count array).
     my $self = shift;
     my $histograms =
       $self->{histograms};     # hash ref of bin:count hashrefs.
     my $n_histograms     = scalar keys %$histograms;
     my $rearr_histograms = {};

     for my $i_hist ( keys %$histograms ) {
        while (my($bin, $count) = each %{$self->{sum_histogram}}) {
           $rearr_histograms->{$bin}->{$i_hist} = 0;
        }
        my $histogram = $histograms->{$i_hist};
        while ( my ( $bin, $count ) = each %$histogram ) {
           if ( !exists $rearr_histograms->{$bin} ) {
              $rearr_histograms->{$bin} = {};
           }
           $rearr_histograms->{$bin}->{$i_hist} = $histogram->{$bin};
        }
     }
     $self->{rearr_histograms} = $rearr_histograms;
  }

sub _total_variation_distance{
   my $self = shift;
   my $bins = shift;            # array ref to bins in sum_histograms
   my $histogram1 = shift;      # hashref. bin-count pairs
   my $histogram2 = shift;      # hashref. bin-count pairs

   my ($sum1, $sum2, $sum_abs_diff) = (0, 0, 0);
   for my $bin (@$bins) {
      my $count1 = $histogram1->{$bin} || 0;
      my $count2 = $histogram2->{$bin} || 0;
      $sum1 += $count1; $sum2 += $count2;
      $sum_abs_diff += abs($count1 - $count2);
   }
   warn "_total_variation_distance. sum1 sum2 should be same in _total_variation_distance: $sum1 $sum2 \n" if($sum1 != $sum2);
   return $sum_abs_diff/(2*$sum1);
}

sub _Ln_distance{
   my $self = shift;
   my $bins = shift;            # array ref to bins in sum_histograms
   my $histogram1 = shift;      # hashref. bin-count pairs
   my $histogram2 = shift;      # hashref. bin-count pairs

   my $n = shift || 2;
   my $n_set = $self->{set_size};
   my $n_histograms = scalar keys %{$self->{histograms}};
   my $n_sample = $self->get_total_counts() / ($n_set * $n_histograms);
   my ($sum1, $sum2, $sum_abs_freq_diff_to_n) = (0, 0, 0);
   for my $bin (@$bins) {
      my $count1 = $histogram1->{$bin} || 0;
      my $count2 = $histogram2->{$bin} || 0;
      $sum1 += $count1; $sum2 += $count2;
      $sum_abs_freq_diff_to_n += (abs($count1 - $count2) / $n_sample)**$n;
   }
   warn "_Ln_distance. sum1 sum2 should be same in Ln_distance: $sum1 $sum2 $n_sample \n" if($sum1 != $n_sample*$n_set  or $sum2 != $n_sample*$n_set);

   my $result = 0.5*(($sum_abs_freq_diff_to_n)/$n_set)**(1.0/$n);
   return $result;
}

sub _Linfinity_distance{
   my $self = shift;
   my $bins = shift;            # array ref to bins in sum_histograms
   my $histogram1 = shift;      # hashref. bin-count pairs
   my $histogram2 = shift;      # hashref. bin-count pairs
   my $n_set = $self->{set_size};
   my $n_histograms = scalar keys %{$self->{histograms}};
   my $n_sample = $self->get_total_counts() / ($n_set * $n_histograms);
   my ($sum1, $sum2, $max_abs_weight_diff) = (0, 0, 0);
   for my $bin (@$bins) {
      my $count1 = $histogram1->{$bin} || 0;
      my $count2 = $histogram2->{$bin} || 0;
      $sum1 += $count1; $sum2 += $count2;
      $max_abs_weight_diff = max( abs($count1 - $count2), $max_abs_weight_diff );
   }
   warn "_Linfinity_distance. sum1 sum2 should be same in Ln_distance: $sum1 $sum2 $n_sample \n" if($sum1 != $n_sample*$n_set  or $sum2 != $n_sample*$n_set);

   my $result = 0.5*$max_abs_weight_diff/$n_sample;
   return $result;
}

sub tv_distances{
   my $self = shift;
   my $histograms = $self->{histograms};
   my @setids = keys %{$self->{histograms}}; 
   my @labels = sort {$a <=> $b} keys %{$self->{sum_histogram}}; # bin labels
   my @tvds = ();
   my %ij_dist = ();
   my $n_histograms = scalar keys %$histograms;
   die "n_histograms: $n_histograms " . scalar @setids . " not equal.\n" if($n_histograms != scalar @setids);
   for (my $i = 0; $i < $n_histograms; $i++) {
      for (my $j = $i+1; $j < $n_histograms; $j++) {
         my ($setid1, $setid2) = ($setids[$i], $setids[$j]);
         #  print "ZZZ: $i  $j    $setid1  $setid2 \n";
         my $tv_dist = $self->_total_variation_distance(\@labels, $histograms->{$setid1}, $histograms->{$setid2});
         push @tvds, $tv_dist;
         $ij_dist{"$i,$j"} = $tv_dist;
      }
   }
   return (\@tvds, \%ij_dist);
}

sub quartiles{                  # get the 5 quartiles
   my $data = shift;            # ref to array of data values
   my $DStat_obj = Statistics::Descriptive::Full->new();
   $DStat_obj->add_data(@$data);
   my ($min, $q1, $median, $q3, $max) = map( $DStat_obj->quantile($_), (0..4));
   return ($min, $q1, $median, $q3, $max);
}

sub max_avg_intercluster_distance{
   my $self = shift;
   my $n_hists = scalar keys %{$self->{histograms}};
   my @labels = (0..$n_hists-1);
   my $ij_dist = shift;
   my $cluster_obj = CXGN::Phylo::Cluster->new(\@labels, $ij_dist);
   my ($max_avg_intercluster_dist, $str) = $cluster_obj->best_n_partition(); # default: bipartition, max avg inter-cluster dist
   return $max_avg_intercluster_dist;
}

sub dist_stats{
   my $self = shift;
   my $ij_dist = shift;
   my $n_histograms = scalar keys %{$self->{histograms}};
   my @dists = sort {$a <=> $b} values %$ij_dist;
   my @quartiles = quartiles(\@dists);

   my $max_avg_interclstr_dist =  $self->max_avg_intercluster_distance($ij_dist);

   return (@quartiles, $max_avg_interclstr_dist, $dists[-($n_histograms-1)]);
}

sub tvd_stats{ # statistics summarizing the pairwise total variation distances between chains
   my $self = shift;
   my ($tvds, $ij_dist) = $self->tv_distances();
   # for(keys %$ij_dist){
   #   print "i j tvd: $_  ", $ij_dist->{$_}, "\n";
   # }
   my @tvd_quartiles = quartiles($tvds);
   my $max_avg_interclstr_dist =  $self->max_avg_intercluster_distance($ij_dist);
   return (@tvd_quartiles, $max_avg_interclstr_dist); # min, q1, median, q3, max, intercluster_dist
}

sub maxbindiff_stats{
   my $self = shift;
   my $ij_diff = $self->max_bin_diffs();
   my @mbd_quartiles = quartiles([values %$ij_diff]);
   my $max_avg_interclstr_dist =  $self->max_avg_intercluster_distance($ij_diff);
   return (@mbd_quartiles, $max_avg_interclstr_dist);
}

sub nbadbin_stats{
   my $self = shift;
   my $stringency = shift || 8; # number of bad splits to allow is (N-3)/$stringency
   my $ij_diff = $self->n_bad_bin_diffs();
   my @nbbs = values %$ij_diff;
   my $max_allowed_badbins = $self->{set_size} / $stringency;
   my @nbb_quartiles = quartiles(\@nbbs);
   my $max_avg_interclstr_dist =  $self->max_avg_intercluster_distance($ij_diff);
   my $bad_pairs = 0;
   for (@nbbs) {
      $bad_pairs++ if($_ > $max_allowed_badbins);
   }
   return (@nbb_quartiles, $max_avg_interclstr_dist, $bad_pairs);
}

sub tvd_statsx{
   my $self = shift;
   my $sum_tvd = 0;
   my $sum_tvdsqrd = 0;
   my $max_tvd = -1;
   my $histograms = $self->{histograms};
   my @bins = sort {$a <=> $b} keys %{$self->{sum_histogram}};
   my @tvds = ();
   my @labels = ();
   my %ij_dist = ();
   my $n_histograms = scalar keys %$histograms;
   for (my $i = 0; $i < $n_histograms; $i++) {
      push @labels, $i;
      for (my $j = $i+1; $j < $n_histograms; $j++) {
         my $tv_dist = $self->_total_variation_distance(\@bins, $histograms->{$i}, $histograms->{$j});
         push @tvds, $tv_dist;
         $sum_tvd += $tv_dist;
         $sum_tvdsqrd += $tv_dist**2;
         $max_tvd = max($max_tvd, $tv_dist);
         $ij_dist{"$i,$j"} = $tv_dist;
      }
   }
   my $cluster_obj = CXGN::Phylo::Cluster->new(\@labels, \%ij_dist);

   my ($max_avg_intercluster_dist, $str) = $cluster_obj->best_n_partition(); # default: bipartition, max avg inter-cluster dist

   my $avg_tvd = $sum_tvd /( $n_histograms*($n_histograms-1)/2 );
   my $rms_tvd = $sum_tvdsqrd /( $n_histograms*($n_histograms-1)/2 )**0.5;
   @tvds = sort {$a <=> $b} @tvds;
   my $x = 3/4 * (scalar @tvds);
   my ($xlo, $xhi) = (int($x), int($x+1));
   my $upper_quartile = $tvds[int($xlo)] * ($xhi - $x) + $tvds[$xhi] * ($x - $xlo);
   my $DStat_obj = Statistics::Descriptive::Full->new() ; # @tvds);
   $DStat_obj->add_data(@tvds);
   return ($avg_tvd, $rms_tvd, $max_tvd, $upper_quartile, $max_avg_intercluster_dist);
}

sub _Ln_distance_old{
   my $self = shift;
   my $bins = shift;
   my $histogram1 = shift;      # hashref. bin-count pairs
   my $histogram2 = shift;      # hashref. bin-count pairs
   my $n = shift || 2;          # L2 distance by default
   my $sum = 0.0;
   #my @sbins = sort {$a <=> $b} @$bins;
   for my $bin (@$bins) {
      my $count1 = $histogram1->{$bin};
      $count1 = 0 if(! defined $count1);
      my $count2 = $histogram2->{$bin};
      $count2 = 0 if(! defined $count2);
      die "Histogram 2 has undefined counts for bin $bin. \n" if( ! defined $count2);
      my $abs_diff = abs($count1 - $count2);
      $sum += $abs_diff**$n;
   }
   return $sum**(1/$n);
}

sub Ln_distances{
   my $self = shift;
   my $n = shift || 2;
   my $avg = 0;
   my $max = -1;
   my $histograms = $self->{histograms};
   my @bins = sort {$a <=> $b} keys %{$self->{sum_histogram}};
   my @distances = ();
   my %ij_dist = ();
   my $n_histograms = scalar keys %$histograms;
   for (my $i = 0; $i < $n_histograms; $i++) {
      for (my $j = $i+1; $j < $n_histograms; $j++) {
         my $Ln_dist = ($n eq 'infinity')?
           $self->_Linfinity_distance(\@bins, $histograms->{$i}, $histograms->{$j}) :
             $self->_Ln_distance(\@bins, $histograms->{$i}, $histograms->{$j}, $n);
         push @distances, $Ln_dist;
         $ij_dist{"$i,$j"} = $Ln_dist;
         $avg += $Ln_dist;
         $max = max($max, $Ln_dist);
      }
   }
   return \%ij_dist;            # @distances;
}

sub max_bin_diffs{ # for each pair of chains, the max over bins of the abs diff in split frequencies
   my $self = shift;
   my $label_weightslist = shift;
   my $set_size = shift || $self->{set_size}; # e.g. if histogramming splits, set_size = N-3,
   if ( !defined $label_weightslist ) {
      $self->rearrange_histograms();
      $label_weightslist = $self
        ->{rearr_histograms}; # hashref. keys are category labels; values are refs to hashes of setid:weight pairs
   }

   # because each topology has N-3 non-terminal splits, all distinct.
   # in the case of histogramming splits, each topology gives N-3 distinct (non-terminal) splits 
   # so e.g. if there are n_chain mcmc chains and you get n_topo topologies from each chain
   # then total_counts = n_chain * n_topo * set_size, and the max possible counts in each bin
   # for the histogram of one chain is n_topo, or total_counts/( n_chain *set_size)

   my $n_histograms           = scalar keys %{$self->{histograms}};
   my $total_counts      = $self->get_total_counts();
   my $max_in_category = $total_counts / ( $n_histograms * $set_size );

   my %ij_maxbindiff = ();
   for (my $i=0; $i<$n_histograms; $i++) {
      for (my $j=$i+1; $j<$n_histograms; $j++) {
         my $ij = "$i,$j";
         $ij_maxbindiff{$ij} = 0;
      }
   }
   my @labels = keys %$label_weightslist; #
   foreach my $label (@labels) { # loop over categories (bins)
      my $setid_weight = $label_weightslist->{$label};
      next if(sum(values %$setid_weight) <= 0);
      my @setids = sort keys %{$setid_weight};
      die "n_histograms: $n_histograms and number of setids " . scalar @setids, " not equal.\n" if($n_histograms != scalar @setids);
      for (my $i=0; $i<$n_histograms; $i++) {
         for (my $j=$i+1; $j<$n_histograms; $j++) {
            my ($setid1, $setid2) = ($setids[$i], $setids[$j]);
            my $ij = "$setid1,$setid2";
            my $ijdiff = abs($setid_weight->{$setid1} - $setid_weight->{$setid2}) / $max_in_category;
            if ($ijdiff > $ij_maxbindiff{$ij}) {
               $ij_maxbindiff{$ij} = $ijdiff;
            }
            ;
         }
      }
   }
   return \%ij_maxbindiff;
}

sub n_bad_bin_diffs{ # for each pair of chains, the number of bins with frequency diff > threshold
   my $self = shift;
   my $threshold = shift || 0.2;
   my $label_weightslist = shift;
   my $set_size = shift || $self->{set_size}; # e.g. if histogramming splits, set_size = N-3,
   if ( !defined $label_weightslist ) {
      $self->rearrange_histograms();
      $label_weightslist = $self
        ->{rearr_histograms}; # hashref. keys are category labels; values are refs to arrays of weights
   }

   # because each topology has N-3 non-terminal splits, all distinct.
   # in the case of histogramming splits, each topology gives N-3 distinct (non-terminal) splits 
   # so e.g. if there are n_chain mcmc chains and you get n_topo topologies from each chain
   # then total_counts = n_chain * n_topo * set_size, and the max possible counts in each bin
   # for the histogram of one chain is n_topo, or total_counts/( n_chain *set_size)

   my $n_histograms           = scalar keys %{$self->{histograms}};
   my $total_counts      = $self->get_total_counts();
   my $max_in_category = $total_counts / ( $n_histograms * $set_size );

   my %ij_nbadbins = ();
   for (my $i=0; $i<$n_histograms; $i++) {
      for (my $j=$i+1; $j<$n_histograms; $j++) {
         my $ij = "$i,$j";
         $ij_nbadbins{$ij} = 0;
      }
   }
   my @labels = keys %$label_weightslist; #
   foreach my $label (@labels) {          # loop over categories
      #  my @weights = @{ $label_weightslist->{$label} };
      my $setid_weight = $label_weightslist->{$label};
      next if(sum(values %$setid_weight) <= 0);
      my @setids = sort keys %{$setid_weight};
      for (my $i=0; $i<$n_histograms; $i++) {
         for (my $j=$i+1; $j<$n_histograms; $j++) {
            my ($setid1, $setid2) = ($setids[$i], $setids[$j]);
            my $ij = "$setid1,$setid2";
            my $ijdiff = abs($setid_weight->{$setid1} - $setid_weight->{$setid2}) / $max_in_category;
            if ($ijdiff > $threshold) {
               $ij_nbadbins{$ij}++;
            }
         }
      }
   }
   return \%ij_nbadbins;
}

sub avg_L1_distance { # just find for histograms as given, no rebinning.
   my $self              = shift;
   my $label_weightslist = shift;
   if ( !defined $label_weightslist ) {
      $self->rearrange_histograms();
      $label_weightslist = $self
        ->{rearr_histograms}; # hashref. keys are category labels; values are refs to arrays of weights
   }
   my $set_size = shift || $self->{set_size}; # e.g. if histogramming splits, set_size = N-3,
   # because each topology has N-3 non-terminal splits, all distinct.
   # in the case of histogramming splits, each topology gives N-3 distinct (non-terminal) splits 
   # so e.g. if there are n_chain mcmc chains and you get a sample of size N from each chain
   # then total_counts = n_chain * N * set_size, and the max possible counts in each bin
   # for the histogram of one chain is N, or total_counts/( n_chain *set_size)

   my $n_histograms           = scalar keys %{$self->{histograms}};

   my $total_counts      = $self->get_total_counts();
   my ($above_threshold_string1, $above_threshold_string2, $above_threshold_string3) = ('', '', '');
   my $max_in_category = $total_counts / ( $n_histograms * $set_size );

   # one weight for each histogram being compared (e.g. 1 for each MCMC chain)
   my @thresholds = (0.1, 0.2, 0.4);
   my %threshold_count1 = (); my %threshold_count2 = (); my %threshold_count3 = ();
   for (@thresholds) {
      $threshold_count1{$_} = 0;
      $threshold_count2{$_} = 0;
      $threshold_count3{$_} = 0;
   }
   ;
   #counts categories with abs diff > the keys
   my ($avg_L1_distance, $max_range ) = ( 0, 0, -1 );
   my @labels = keys %$label_weightslist; #
   # my %sumw_bsos = ();
   my ($sum_ranges, $sumsq_ranges, $src) = (0, 0, 0);

   if ( $n_histograms > 1 ) {   #
      my $sum_absdiffs = 0;
      my $counts_each_run = $total_counts / $n_histograms;
      my %label_range   = ();
      foreach my $label (@labels) { # loop over categories
         my @weights = sort { $b <=> $a } values %{ $label_weightslist->{$label} };
         next if(sum(@weights) <= 0);

         my ($mean, $variance) = mean_variance(\@weights);
         my $binomial_bin_variance = $mean*(1 - $mean/$max_in_category); # variance of binomial distribution with mean $mean
         my $this_label_range = (max(@weights) - min(@weights)) / $max_in_category;
         $sum_ranges += $this_label_range;
         $sumsq_ranges += $this_label_range**2;
         $src++;
         $label_range{$label} = $this_label_range;

         my ($obs_bin_stddev, $binomial_bin_stddev) = (sqrt($variance)/$max_in_category, sqrt($binomial_bin_variance/$max_in_category));
         # $sumw_bsos{sum(@weights)} = [$binomial_bin_stddev, $obs_bin_stddev];
         for ( @thresholds ) {
            $threshold_count1{$_}++  if ($this_label_range > $_ );
         }
         for ( @thresholds ) {
            $threshold_count2{$_}++ if ($obs_bin_stddev > ($_ * $binomial_bin_stddev));  
         }
         for (my $i = 0; $i < $n_histograms; $i++) {
            for (my $j = 0; $j < $n_histograms; $j++) {
               my $absdiff = abs($weights[$i] - $weights[$j]) / $max_in_category;
               for (@thresholds) {
                  $threshold_count3{$_}++ if( $absdiff > $_);
               }
            }
         }
         $max_range = max( $max_range, $this_label_range );
         my $coeff = $n_histograms - 1;
         for my $histogram_weight (@weights) { # loop over runs
            $sum_absdiffs += $coeff * $histogram_weight;
            #	$histogram_weight;	# accumulating counts in all runs
            $coeff -= 2;
         }
      }
      $above_threshold_string1 =
        join( " ", map( $threshold_count1{$_}, @thresholds));
      $above_threshold_string2 =
        join( " ", map( $threshold_count2{$_}, @thresholds ) );
      $above_threshold_string3 =
        join( " ", map( $threshold_count3{$_}, @thresholds ) );
      $avg_L1_distance = $sum_absdiffs / ( $total_counts * ( $n_histograms - 1 ) );
   }                                        # loop over histograms
   my @tvd_sstats = $self->tvd_stats();     # 6 numbers
   my @mbd_sstats = $self->maxbindiff_stats(); # 6 numbers
   my @nbb_sstats = $self->nbadbin_stats();    # 7 numbers
   my ($xtvds, $xij_dist) = $self->tv_distances();
   my $ij_L1d = $self->Ln_distances(1);
   my $ij_L2d = $self->Ln_distances(2);
   my $ij_Linfd = $self->Ln_distances('infinity');
   my $ij_nbbd = $self->n_bad_bin_diffs();
   # my @L1_stats = $self->dist_stats($ij_L1d);
   # my @L2_stats = $self->dist_stats($ij_L2d);
   # my @Linf_stats = $self->dist_stats($ij_Linfd);
   # my @nbbd_stats = $self->dist_stats($ij_nbbd);
   # print "tvdstats:  ", join("; ", @tvd_sstats), "\n";
   # print "L1_stats:  ", join(": ", @L1_stats), "\n";
   # print "L2_stats:  ", join(": ", @L2_stats), "\n";
   # print "mbdstats:  ", join(": ", @mbd_sstats), "\n";
   # print "Linf_stats:  ", join(": ", @Linf_stats), "\n";
   # print "nbb_sstats :  ", join("; ", @nbb_sstats), "\n";
   # print "nbbd_stats:  ", join(": ", @nbbd_stats), "\n";
   #print join("; ", @$xtvds), "\n";
   #print join(": ", value), "\n";
   #print "nbbstats: ", join("; ", @nbb_sstats), "\n";
   my $n_bad_pairs = pop @nbb_sstats; 

   #print"nbbstats: ", join("; ", @nbb_sstats), "  xxx   ", $n_bad_pairs, "\n";
   my $above_threshold_string4 = join(" ", @nbb_sstats);
   #return (\@L1_stats, \@L2_stats, \@Linf_stats, \@nbbd_stats);
   return ( @tvd_sstats, @mbd_sstats, $above_threshold_string1, $above_threshold_string2, $above_threshold_string3, $above_threshold_string4, $n_bad_pairs );
}

sub four_distance_stats{
   my $self = shift;
   my $ij_L1d = $self->Ln_distances(1);
   my $ij_L2d = $self->Ln_distances(2);
   my $ij_Linfd = $self->Ln_distances('infinity');
   my $ij_nbbd = $self->n_bad_bin_diffs();
   my @L1_stats = $self->dist_stats($ij_L1d);
   my @L2_stats = $self->dist_stats($ij_L2d);
   my @Linf_stats = $self->dist_stats($ij_Linfd);
   my @nbbd_stats = $self->dist_stats($ij_nbbd);
   return (\@L1_stats, \@L2_stats, \@Linf_stats, \@nbbd_stats);
}

sub binned_max_ksd {
   my $self         = shift;
   my $n_histograms = scalar keys %{$self->{histograms}};
   my $max_ksd      = 0;
   my %cume_probs  = ();        #  = ( (0) x $n_histograms );

   my @setids = keys %{$self->{histograms}};
   for (@setids) {
      $cume_probs{$_} = 0;
   }
   my $total_counts = sum( values %{ $self->{histograms}->{$setids[0]}} ); # counts in one representative histogram

   for my $bin ( $self->{min_bin} .. $self->{max_bin} ) {
      my $histograms = $self->{histograms};

      for my $a_setid (keys %$histograms ) {
         my $b_c = $histograms->{$a_setid};
         $cume_probs{$a_setid} += $b_c->{$bin};
      }
      my $cdf_range = max(values %cume_probs) - min(values %cume_probs);
      if ( $cdf_range > $max_ksd ) {
         $max_ksd = $cdf_range;
      }
   }
   return ($total_counts > 0)? $max_ksd/$total_counts : '---';
}

sub mean_variance{
   my $x = shift;
   my ($count, $sum_x, $sum_xsqr) = (scalar @$x, 0, 0);
   return (undef, undef) if($count == 0);
   for (@$x) {
      $sum_x += $_;
      $sum_xsqr += $_*$_;
   }
   my $mean = $sum_x/$count;
   my $variance = $sum_xsqr/$count - $mean**2;
   return ($mean, $variance);
}

# sub minweight_L1 {
#     my $self = shift;
#     my $minweight = shift || 0.02;
#     return $self->avg_L1_distance( $self->minweight_rebin($minweight) )
#       ;    # $self->minweight_rebin($minweight));
# }

# sub minweight_rebin {

# # input here is already binned
# # the idea here is to make each bin have at least some fraction of total weight (1% is default)
# # by possibly lumping together some bins.
#     my $self = shift;
#     my $target_bin_weight = shift || 0.01;
#     $self->rearrange_histograms();
#     my $label_weightslist = $self->{rearr_histograms};

# #print "in minweight_rebin. labels: ", join(", ", keys %$label_weightslist), "\n";

#     my %label_sumweights = ();
#     while ( my ( $l, $ws ) = each %$label_weightslist ) {
#         $label_sumweights{$l} = sum(@$ws);
#     }
#     my @sorted_labels =
#       sort {
#         $label_sumweights{$a} <=> $label_sumweights{$b}
#       }    # sort by weight; small to large
#       keys %$label_weightslist;

#  #print "in minweight_rebin. sorted labels: ", join(", ", @sorted_labels), "\n";

#     my $total_hits =
#       sum( map( @{ $label_weightslist->{$_} }, @sorted_labels ) );
#     my $run0_hits = sum( map( $label_weightslist->{$_}->[0], @sorted_labels ) );
#     my $n_histograms = scalar @{ $label_weightslist->{ $sorted_labels[0] } };

#     my $result       = {};
#     my $cume_weight  = 0;
#     my @cume_weights = ( (0) x $n_histograms );
#     my $cume_label   = '';
#     foreach my $label (@sorted_labels) {    # loop over categories
#         my @weights = @{ $label_weightslist->{$label} };
#         @cume_weights = map { $cume_weights[$_] + $weights[$_] } 0 .. $#weights;
#         my $weight =
#           sum(@weights); # number of hits for this categories, summed over runs.
#         $cume_weight += $weight;
#         $cume_label .= $label . '_';
#         if ( $cume_weight >= $target_bin_weight * $total_hits ) {
#             my @copy = @cume_weights;
#             $cume_label =~ s/_$//;
#             $result->{$cume_label} = \@copy;
#             $cume_weight = 0;
#             @cume_weights = ( (0) x $n_histograms );
#             $cume_label = '';
#         }
#     }
#     return $result;
# }

# sub populate {
#     my $self                = shift;
#     my $histogram_gen_value = shift
#       ; # ref to array of gen/value hashrefs. $rgv->[0]->{120} is value for run 0, gen 120
#     my $min_gen = shift || 0;

# #  while (my ($run, $g_v) = each @$histogram_gen_value) { # can  use this if perl 5.12 or later.
#     for my $run ( 0 .. $#$histogram_gen_value ) {
#         my $g_v = $histogram_gen_value->{$run};
#         for my $g ( sort { $a <=> $b } keys %$g_v ) {
#             my $v = $g_v->{$g};
#             if ( $g >= $min_gen ) {
#                 $self->{histograms}->[$run]->{$v}++;
#                 $self->{sum_histogram}->{$v}++;
#             }
#         }
#     }
# }

# sub get_count{
#   my $self = shift;
#   my $hist_number = shift;
#   my $category = shift;
#   return $self->{histograms}->[$hist_number]->{$category};
# }


package CXGN::Phylo::BinnedHistograms;
use strict;
use List::Util qw ( min max sum );
use base qw/ CXGN::Phylo::Histograms /;

sub new {
   my $class = shift;
   my $self  = $class->SUPER::new(@_);

   # warn "BinnedHistogram constructed with undefined binning parameters.\n"
   #  if(!defined $self->{binning_lo_val} or !defined $self->{bin_width});
   return $self;
}

sub adjust_val_count {
   my $self        = shift;
   my $set_id = shift;          # 0,1,2,...
   my $value       = shift;
   my $increment   = shift;
   $increment = 1 if ( !defined $increment );
   my $category = $self->bin_the_point($value);

   $self->{histograms}->{$set_id}->{$category} += $increment;
   $self->{sum_histogram}->{$category}              += $increment;
   $self->{total_in_histograms}                     += $increment;
}

sub bin_the_point {
   my $self  = shift;
   my $value = shift;

   die "In bin_the_point. n_bins, binning_lo_val or bin_width not defined. \n"
     if ( !defined $self->{n_bins}
          or !defined $self->{binning_lo_val}
          or !defined $self->{bin_width} );
   my $bin = int( ( $value - $self->{binning_lo_val} ) / $self->{bin_width} );
   $bin = max( $bin, 0 );
   $bin = min( $bin, $self->{n_bins} - 1 );
   $self->{min_bin} = min( $bin, $self->{min_bin} );
   $self->{max_bin} = max( $bin, $self->{max_bin} );
   return $bin;
}

sub category_string {
   my $self    = shift;
   my $cat     = shift;
   my $lo_edge = $self->{binning_lo_val} + $cat * $self->{bin_width};
   return sprintf( "%10.5f ", $lo_edge );
}

# sub populate {
#     my $self                = shift;
#     my $histogram_gen_value = shift
#       ; # ref to array of gen/value hashrefs. $rgv->[0]->{120} is value for run 0, gen 120
#     my $min_gen = shift || 0;

# #  while (my ($run, $g_v) = each @$histogram_gen_value) { # can  use this if perl 5.12 or later
#     for my $run ( 0 .. $#$histogram_gen_value ) {
#         my $g_v = $histogram_gen_value->[$run];
#         for my $g ( sort { $a <=> $b } keys %$g_v ) {
#             my $v = $g_v->{$g};
#             if ( $g >= $min_gen ) {
#                 $v = $self->bin_the_point($v);
#                 $self->{histograms}->[$run]->{$v}++;
#                 $self->{sum_histogram}->{$v}++;
#             }
#         }
#     }
# }


1;
