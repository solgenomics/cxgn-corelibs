package CXGN::Phylo::Histograms;
use strict;
use List::Util qw ( min max sum );

# for histogramming Mrbayes chain output
# Histograms can hold several histograms (1 per run)
# and provide some statistics on how them, particularly
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
	'set_size' => 1
    };
    my $self = bless $default_arguments, $class;

    foreach my $option ( keys %$arg ) {
        warn "Unknown option: $option in Histograms constructor.\n"
          if ( !exists $self->{$option} );
        if ( defined $arg->{$option} )
        {    # if arg is undef, leaves default in effect
            $self->{$option} = $arg->{$option};
        }
    }

    $self->{histograms} = []
      ; # indices 0,1,2...; values are bin:count hashrefs representing histograms
    $self->{sum_histogram} = {};
    $self->{rearr_histograms} =
      {}; # same info as histograms, but hashref with keys: bins; values array refs of counts for the various histograms.
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
    my $hist_number = shift;    # 0,1,2,...
    my $category    = shift;
    my $increment   = shift;
    $increment = 1 if ( !defined $increment );
    $self->{histograms}->[$hist_number]->{$category} += $increment;
    $self->{sum_histogram}->{$category}              += $increment;
    $self->{total_in_histograms}                     += $increment;
}

sub adjust_val_count {
    my $self = shift;
    $self->adjust_cat_count(@_);
}

sub n_histograms {
    my $self = shift;
    return scalar @{ $self->{histograms} };
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
    my $max_lines_to_print = shift || 1000000;           #
    my $histogram_cat_weight = $self->{histograms};
    my $sum_cat_weight       = $self->{sum_histogram};
    my $min_count_to_show = 4;    #scalar @$histogram_cat_weight;

    my $extra_bit         = '';
    my @sorted_categories = keys %$sum_cat_weight;

    #  my @cats = keys %$sum_cat_weight;
    my $total_weight = sum( values %$sum_cat_weight );
    if ( $sorting eq 'by_bin_number' ) {
        @sorted_categories =
          sort { $a <=> $b } @sorted_categories;    # keys %$sum_cat_weight;
    }
    else {                                          # sort by avg bin count.
        @sorted_categories =
          sort { $sum_cat_weight->{$b} <=> $sum_cat_weight->{$a} }
          @sorted_categories;                       # keys %$sum_cat_weight;
        while ( scalar @sorted_categories > 10 )
        {    # remove low-count categories, but leave min of 10 categories
            my $the_cat = $sorted_categories[-1];
            if ( exists $sum_cat_weight->{ $sorted_categories[-1] } ) {
                my $last_bin_count =
                  $sum_cat_weight->{ $sorted_categories[-1] };
                if ( defined $last_bin_count ) {
                }

                last
                  if ( $last_bin_count >= $min_count_to_show ); # get rid of categories with count of zero.
                pop @sorted_categories;
            }
            else {
                die "category not found: ", $sorted_categories[-1], "\n";
            }
        }
    }
    my $total_categories = scalar @sorted_categories;
    my $string =
      "# " . $self->title() . " histogram. n_bins: " . $self->{n_bins} . "  ";
    $string .= "binning_lo_val: " . $self->{binning_lo_val} . "  ";
    $string .= "bin_width: " . $self->{bin_width} . ".\n";

    my ( $total, $shown_total ) = ( 0, 0 );
    my $count = 0;
    for my $cat (@sorted_categories) {
        my $sum_weight = $sum_cat_weight->{$cat};
        $total += $sum_weight;

        my $line_string = '';
        my $cat_string  = $self->category_string($cat);
        $line_string .= $cat_string;
        for my $c_w (@$histogram_cat_weight) {
            $line_string .= sprintf( "%6i  ", $c_w->{$cat} );
        }
        $line_string .= sprintf( "%6i \n", $sum_weight );
        $count++;

        if ( $count > $max_lines_to_print ) {
            $extra_bit = "(Top $max_lines_to_print shown.)";
            last;
        }
        else {
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
{    # go from an array of bin:count hashes to hash of bin:(count array).
    my $self = shift;
    my @histograms =
      @{ $self->{histograms} };    # array ref of bin:count hashrefs.
    my $n_histograms     = scalar @histograms;
    my $rearr_histograms = {};

# while (my ($i_hist, $histogram) = each @histograms) { # can use if per 5.12 or later
    for my $i_hist ( 0 .. $#histograms ) {
        my $histogram = $histograms[$i_hist];
        while ( my ( $bin, $count ) = each %$histogram ) {
            if ( !exists $rearr_histograms->{$bin} ) {
                $rearr_histograms->{$bin} = [ (0) x $n_histograms ];
            }
            $rearr_histograms->{$bin}->[$i_hist] = $histogram->{$bin};
        }
    }
    $self->{rearr_histograms} = $rearr_histograms;
}



sub avg_L1_distance {    # just find for histograms as given, no rebinning.
    my $self              = shift;
    my $label_weightslist = shift;
    if ( !defined $label_weightslist ) {
        $self->rearrange_histograms();
        $label_weightslist = $self
          ->{rearr_histograms}; # hashref. keys are category labels; values are refs to arrays of weights
    }
    my $set_size = shift || $self->{set_size};   # e.g. if histogramming splits, set_size = N-3,

    # because each topology has N-3 non-terminal splits, all distinct.

    my $n_histograms           = scalar @{ $self->{histograms} };
    my $total_counts      = $self->get_total_counts();
    my $above_threshold_string = '';
    my $max_in_category = $total_counts / ( $n_histograms * $set_size );

    # one weight for each histogram being compared (e.g. 1 for each MCMC chain)
    my %threshold_count = ( 0.1 => 0, 0.2 => 0, 0.4 => 0 )
      ;                          #counts categories with abs diff > the keys
    my ($avg_L1_distance, $L1x, $max_abs_diff ) = ( 0, 0, -1 );
    my @labels = keys %$label_weightslist;    #
    if ( $n_histograms > 1 ) {                #
        my $sum_abs_diffs = 0;
        my $counts_each_run = $total_counts / $n_histograms;
        my %label_absdiff   = ();
        foreach my $label (@labels) {         # loop over topologies
            my @weights = sort { $b <=> $a } @{ $label_weightslist->{$label} };
 #           $total += sum(@weights);
            my $this_label_abs_diff = max(@weights) - min(@weights);
            $label_absdiff{$label} = $this_label_abs_diff / $max_in_category;
            $L1x += $this_label_abs_diff;
            for ( keys %threshold_count ) {
                if ( $this_label_abs_diff > $_ * $max_in_category ) {
                    $threshold_count{$_}++;
                }
            }
            $max_abs_diff = max( $max_abs_diff, $this_label_abs_diff );
            my $coeff = $n_histograms - 1;
            for my $histogram_weight (@weights) {    # loop over runs
                $sum_abs_diffs += $coeff * $histogram_weight;
 #               $total_counts +=
                  $histogram_weight;    # accumulating counts in all runs
                $coeff -= 2;
            }
        }
        my @sorted_keys = sort { $a <=> $b } keys %threshold_count;
        $above_threshold_string =
          join( " ", map( $threshold_count{$_}, @sorted_keys ) );

	# @sorted_keys = sort { $label_absdiff{$b} <=> $label_absdiff{$a} } keys %label_absdiff;

	# normalize L1, L1x, and max_abs_diffs such that they can be no greater than 1.
        $L1x /= $total_counts; # Will be 1 for non-overlapping distributions.
	# avg_L1_distance is average of all chain-chain comparisons, each normalized to be <= 1
      $avg_L1_distance = $sum_abs_diffs / ( $total_counts * ( $n_histograms - 1 ) );
        $max_abs_diff /= $max_in_category; 
    }
    return ( $avg_L1_distance, $L1x, $max_abs_diff, $above_threshold_string );
}

sub binned_max_ksd {
    my $self         = shift;
    my $n_histograms = scalar @{ $self->{histograms} };
    my $max_ksd      = 0;
    my @cume_probs   = ( (0) x $n_histograms );
    my $total_counts = sum( values %{ $self->{histograms}->[0] } ); # counts in each histogram

    for my $bin ( $self->{min_bin} .. $self->{max_bin} ) {
        my @histograms = @{ $self->{histograms} };

#    while (my ($i_hist, $b_c) = each @{$self->{histograms}}) { # can use this if perl 5.12 or later
        for my $i_hist ( 0 .. $#histograms ) {
            my $b_c = $histograms[$i_hist];
            $cume_probs[$i_hist] += $b_c->{$bin};
        }
        my $cdf_range = max(@cume_probs) - min(@cume_probs);
        if ( $cdf_range > $max_ksd ) {
            $max_ksd = $cdf_range;
        }
    }
    $max_ksd /= $total_counts;
    return $max_ksd;
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
    my $hist_number = shift;    # 0,1,2,...
    my $value       = shift;
    my $increment   = shift;
    $increment = 1 if ( !defined $increment );
    my $category = $self->bin_the_point($value);

    $self->{histograms}->[$hist_number]->{$category} += $increment;
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
