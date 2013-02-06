package CXGN::Phylo::ChainData;
use strict;
use List::Util qw ( min max sum );
use CXGN::Phylo::Histograms;

# for handling Mrbayes parameter output

# param name (topology, logL, treelength, etc.
# generations list, and pre-burn-in gen range and post-burn-in range
# array of gen/value hashrefs, one for each run

sub  new {
  my $class = shift;
  my $arg = shift;
  my $default_arguments = {
			   'parameter_name' => 'unnamed parameter',
			   'n_runs' => undef,
			   'burn_in_fraction' => 0.1,
			   'gen_spacing' => undef,
			  };
  my $self = bless $default_arguments, $class;

  foreach my $option (keys %$arg) {
    warn "Unknown option: $option in ParamData constructor.\n" if(!exists $self->{$option});
    if (defined $arg->{$option}) { # if arg is undef, leaves default in effect
      $self->{$option} = $arg->{$option};
    }
  }
$self->{max_gen} = 0;
  $self->{generations} = [ ];	# ref to array of n_runs arrayrefs
  for (1..$self->{n_runs}) {
    push @{$self->{generations}}, [];
    push @{$self->{run_gen_value}}, {};
  }
  $self->{gen_array} = []; # just generations
$self->{gen_count} = {}; # keys generations, counts: number of data points at that generation (should be == number of runs)
  $self->{histograms} = CXGN::Phylo::Histograms->new({title => $self->{parameter_name}});
  return $self;
}

sub store_data_chunk{
  my $self = shift;
  my $gen_val_hashrefs = shift;
  my @generations = keys %{$gen_val_hashrefs->[0]};

  $self->{max_gen} = max(max(@generations), $self->{max_gen});

  #print "ref(generations): ", ref($generations), "\n"; exit;
  for my $i_run (0..$self->{n_runs}-1) { # 0-based
    my $g_v = $gen_val_hashrefs->[$i_run];
    for my $gen (@generations) {
      my $val = $g_v->{$gen};
      $self->store_data_point($i_run, $gen, $val);
    }
  }
  if (defined $self->{histograms}) {
    $self->{histograms}->populate($gen_val_hashrefs);
  } else {
    die "**************************\n";
  }
}

sub update{
my $self = shift;
my $gen_val_hashrefs = shift;
$self->store_data_chunk($gen_val_hashrefs);
$self->delete_pre_burn_in();
}

sub store_data_point{		# store a new data point
  my $self = shift;
  my ($run, $gen, $val) = @_;
 # if (!exists $self->{run_gen_value}->[$run-1]->{$gen}) {
    $self->{run_gen_value}->[$run]->{$gen} = $val;
$self->{gen_counts}->{$gen}++;
 #   push @{$self->{generations}->[$run-1]}, $gen;
 # }
}

sub delete_data_point{
 my $self = shift;
  my ($run, $gen) = @_;
 my $value = $self->{run_gen_value}->[$run]->{$gen}; # $run zero-based
# print STDERR "in delete_data_point. run, gen, value $run $gen $value \n";
  delete $self->{run_gen_value}->[$run]->{$gen};
 $self->{gen_counts}->{$gen}--;
# print STDERR "in delete_data_point. value $value \n";
 if($value < 1){
warn "in delete_data_point value is [$value]\n";
sleep(5);
}
$self->{histograms}->adjust_count($run, $value, -1);
# $self->{histograms}->{histograms}->[$run]->{$value}--;
#$self->{histograms}->{sum_histogram}->{$value}--;
}

sub delete_pre_burn_in{
my $self = shift;
my $max_pre_burn_in_gen = int($self->{max_gen}*$self->{burn_in_fraction}); 
$max_pre_burn_in_gen = $self->{gen_spacing}*int($max_pre_burn_in_gen/$self->{gen_spacing});
#print STDERR "in delete_pre_burn_in: $max_pre_burn_in_gen \n"; 
$self->delete_low_gens($max_pre_burn_in_gen);
}

sub delete_low_gens{
  my $self = shift;
  my $max_pre_burn_in_gen = shift;
  my $delta_gen = $self->{gen_spacing};
#print "in delete_low_gens. [", join('][', sort {$a <=> $b} keys %{$self->{run_gen_value}->[0]}), "]\n";
  for (my $i_run=0; $i_run<$self->{n_runs}; $i_run++) {
  for(my $g = $max_pre_burn_in_gen; 1; $g -= $delta_gen){
 #   print STDERR "in delete_low_gens, $max_pre_burn_in_gen, $g, $i_run, ", $self->{run_gen_value}->[$i_run]->{$g}, "\n";
    if(exists $self->{run_gen_value}->[$i_run]->{$g}){
      my $value =  $self->{run_gen_value}->[$i_run]->{$g};
#print STDERR "deleting point: run, gen, value: $i_run, $g, [$value] \n";
	$self->delete_data_point($i_run, $g); # $i_run zero-based
      } else {
	last;
      }
    }
  }
}

sub get_run_data{ # returns hashref with generation/parameter value pairs
  my $self = shift;
  my $run = shift; # 0-based
  return $self->{run_gen_value}->[$run];
}

sub get_run_gen_value{ # returns array ref holding hashrefs with generation/parameter value pairs
  my $self = shift;
  return $self->{run_gen_value};
}

sub get_param_name{
  my $self = shift;
  return $self->{parameter_name};
}

sub get_post_burn_in_param_data_arrays{ # return array ref holding an array ref for each run, which holds param values
  my $self = shift;
  my @gens_big_to_small = reverse @{$self->{generations}->[0]};
  my @runs_param_data = @{$self->{run_gen_value}}; # 
  my @y = ();
my $max_gen = $gens_big_to_small[0];
my $end_burn_in = int($self->{burn_in_fraction} * $max_gen);
#print "max gen end burnin: $max_gen,  $end_burn_in \n";
  for my $run_data (@runs_param_data) { # one element for each param
#print "ref(run_data): ", ref($run_data), "\n";
#print "run_data values: ", join(";", values %$run_data), "\n";
# while(my ($k, $v) = each %$run_data){
#   print "key, value: $k  $v  \n";
# }
    my @data_array = ();
    for my $gen (@gens_big_to_small){
    #  print "GENERATION: $gen  $end_burn_in.\n";
      last if($gen <= $end_burn_in);
    my $datum = $run_data->{$gen};
    #  print "datum: $datum\n";
   push @data_array, $datum;
    }
#print "Data array: ", join(";", @data_array), "\n";
    push @y, \@data_array;
  }
  return \@y;
}

sub bin_the_data{
  my $self = shift;
  my $n_bins = shift || 60;
  my $tail_p = shift || 0.05;
  my $tail_d = shift || 0.25;

 my $the_histograms =  $self->{histograms} = CXGN::Phylo::Histograms->new({title => $self->{parameter_name}});
  my @rgv = @{$self->{run_gen_value}};

  my @values = ();
  for my $g_v (@rgv) {
    @values = (@values, values %$g_v);
  }
  @values = sort {$a <=> $b} @values;
  my $size = scalar @values;
  my ($lo_val, $hi_val) = ($values[int($tail_p*$size)], $values[int((1 - $tail_p)*$size)]);

  my $lo = $lo_val - $tail_d*($hi_val - $lo_val);
  my $hi = $hi_val + $tail_d*($hi_val - $lo_val);
  my $bin_width = ($hi_val - $lo_val + 2*$tail_d)/$n_bins;

  while( my ($i_run, $g_v) = each @rgv) {
    for my $val (values @$g_v) {
      my $bin = inf(($val - $lo)/$bin_width);
      if ($bin < 0) {
	$bin = 0;
      }
      if ($bin >= $n_bins) {
	$bin = $n_bins-1;
      }
      $the_histograms->adjust_count($i_run, $bin, +1);
    }
  }
$self->{histograms} = $the_histograms;
}

1;
