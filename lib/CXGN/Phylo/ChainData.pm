package CXGN::Phylo::ChainData;
use strict;
use List::Util qw ( min max sum );
use lib '/home/tomfy/Orthologger/lib';
use Histograms;

# for handling Mrbayes parameter output

# param name (topology, logL, treelength, etc.
# generations list, and pre-burn-in gen range and post-burn-in range
# array of gen/value hashrefs, one for each run

sub  new {
  my $class = shift;
  my $arg = shift;
  my $default_arguments = {
			   'parameter_name' => 'unnamed parameter',
			   'n_runs' => 3,
			   'burn_in_fraction' => 0.1,
			  };
  my $self = bless $default_arguments, $class;

  foreach my $option (keys %$arg) {
    warn "Unknown option: $option in ParamData constructor.\n" if(!exists $self->{$option});
    if (defined $arg->{$option}) { # if arg is undef, leaves default in effect
      $self->{$option} = $arg->{$option};
    }
  }
  $self->{generations} = [ ];	# ref to array of n_runs arrayrefs
  for (1..$self->{n_runs}) {
    push @{$self->{generations}}, [];
    push @{$self->{run_gen_value}}, {};
  }
  $self->{gen_array} = []; # just generations
$self->{gen_count} = {}; # keys generations, counts: number of data points at that generation (should be == number of runs)
  $self->{histograms} = Histograms->new();
# $self->{category_run_weight} = {}; # hashref. keys: categories (e.g. topologies or bin numbers)
# values array refs with weights in each run. This represents a set of n_run histograms.
  return $self;
}

sub store_data_point{ # store a new data point
  my $self = shift;
  my ($run, $gen, $val) = @_;
  push @{$self->{generations}->[$run-1]}, $gen;
  $self->{run_gen_value}->[$run-1]->{$gen} = $val;
}

sub delete_data_point{
 my $self = shift;
  my ($run, $gen) = @_;
  delete $self->{run_gen_value}->[$run-1]->{$gen};
}

sub delete_low_gens{
  my $self = shift;
  my $min_gen = shift;
  for (my $i_run=0; $i_run<$self->{n_runs}; $i_run++) {
    my @array = @{$self->{generations}->[$i_run]};
    while (1) {
      if ($array[0] < $min_gen) {
	my $gen_to_delete = shift @array;
	$self->delete_data_point($i_run, $gen_to_delete);
      } else {
	last;
      }
    }
  }
}

sub get_run_data{ # returns hashref with generation/parameter value pairs
  my $self = shift;
  my $run = shift;
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

1;
