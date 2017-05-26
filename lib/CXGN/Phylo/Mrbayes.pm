package CXGN::Phylo::Mrbayes;
use strict;
use List::Util qw ( min max sum );

#use List::MoreUtils qw ( pairwise );
use CXGN::Phylo::ChainData;
use CXGN::Phylo::Histograms;
use lib '/usr/share/perl/5.14.2/';

my $MAX_TREE_DEPTH = 400;

# this is an object to facilitate running MrBayes (Bayesian phylogeny
# inference program). The main functionality it adds is a relatively
# easy way to control the criteria for deciding when to end a run.

sub new {
    my $class             = shift;
    my $arg               = shift;    # a hashref for setting various options
    my $default_arguments = {
        'alignment_nex_filename'    => undef, # e.g. fam4436.nex ??
        'file_basename'             => undef,
        'seed'                      => undef,
        'swapseed'                  => undef,
        'n_runs'                    => 2,
        'n_temperatures'            => 3,
        'n_temperatures_out'        => 3,
        'delta_temperature'         => 0.1,
        'n_swaps'                   => 1,
        'chunk_size'                => 2000,     # $default_chunk_size,
        'print_freq'                => undef,
        'sample_freq'               => 20,
        'burnin_fraction'           => 0.1,
        'diag_freq'                 => undef,
        'converged_chunks_required' => 10,
        'fixed_pinvar'              => undef,    # undef -> leaves default of uniform(0,1) in effect
                                                 # convergence criteria
        'splits_min_hits'           => 10,
        'splits_max_ok_stddev'      => 0.05,
        'splits_max_ok_avg_stddev'  => 0.025,
        'splits_max_ok_L1dist'      => 0.1,
        'splits_max_ok_L1distx'     => 0.15,
        'splits_max_ok_max_diff'    => 0.2,
        'param_names'               => [],
        'modelparam_min_ok_ESS'     => 200,

        #		   'modelparam_max_ok_PSRF'    => 1.02,
        'modelparam_max_ok_KSD' => 0.2,
        'max_ok_L1'             => 0.1,
        'ngens_run'             => 0,
        'id_species_map'        => {},
        'append'                => 'yes',
        'max_gens'              => '1000000000',
        'min_binweight'         => 0.01,
        'reproducible'   => 0,       # gives incorrect results when set to 1; use only for testing
        'use_mpi'        => 1,       # will by default use mpi
                                     #(if mpi installed and parallel version of mrbayes installed)
        'max_processors' => undef,
	'verbosity' => 'quiet',

			     'n_taxa' => undef,
			     'n_alignment_columns' => undef,
#	'newick_order' => 'low_to_high', # e.g. (1,((2,5),(3,4)))  of two children, the one with the least leaf id is put on left
    };

    my $self = bless $default_arguments, $class;
    my $min_chunk_size = 100;

    foreach my $option ( keys %$arg ) {
        warn "Unknown option: $option in Mrbayes constructor.\n"
          if ( !exists $self->{$option} );
        if ( defined $arg->{$option} ) {    # if arg is undef, leaves default in effect
            $self->{$option} = $arg->{$option};
        }
    }
    $self->{print_freq} = $self->{chunk_size}
      if ( !defined $self->{print_freq} );
    $self->{diag_freq} = $self->{chunk_size} if ( !defined $self->{diag_freq} );
    print "# print, diag freq: ", $self->{print_freq}, "  ", $self->{diag_freq}, "\n";
    print "# max gens: ", $self->{max_gens}, "\n";
    my $alignment_nex_filename = $self->{alignment_nex_filename};

    #  if(defined $self->{file_basename}){
    #  my  $file_basename;
    if ( !defined $self->{file_basename} ) {
        my $file_basename = $alignment_nex_filename;
        $file_basename =~ s/[.]nex$//;    # delete .nex ending
        $self->{file_basename} = $file_basename;
    }

    if(-f $alignment_nex_filename){
    open my $fh_align, "<", "$alignment_nex_filename";

    #   dimensions ntax=21 nchar=251;
    while (<$fh_align>) {
        if (/^\s*dimensions ntax=(\d+) nchar=(\d+);/) {
            $self->{n_taxa}              = $1;
            $self->{n_alignment_columns} = $2;
            last;
        }
        elsif (/^\s*matrix/) {
            die "In nex file, ntax and nchar not found!\n";
        }
    }
    close $fh_align;
  }else{ # n_taxa, n_alignment_cols must be supplied as arguments
die if(!defined $self->{n_taxa} or !defined $self->{n_alignment_columns});
  }

    my %split_count = ();
    my %topo_count = ();
    $self->{split_count} = \%split_count;
$self->{topology_count} = \%topo_count;

    my $n_runs            = $self->{n_runs};
    my $burnin_fraction   = $self->{burnin_fraction};
    my $n_temperatures    = $self->{n_temperatures};
    my $n_temperatures_out = $self->{n_temperatures_out};
    my $delta_temperature = $self->{delta_temperature};
    my $n_swaps           = $self->{n_swaps};
    my $sample_freq       = $self->{sample_freq};
    my $print_freq        = $self->{print_freq};
    my $chunk_size        = $self->{chunk_size};
    $chunk_size = max( $chunk_size, $min_chunk_size );
    $self->{chunk_size} = $chunk_size;
    my $fixed_pinvar = $self->{fixed_pinvar};
    my $prset_pinvarpr = ( defined $fixed_pinvar ) ? "prset pinvarpr=fixed($fixed_pinvar);\n" : '';

    $self->{splits_min_hits} *= $n_runs;

    my $begin_piece = "begin mrbayes;\n" . "set autoclose=yes nowarn=yes;\n";
    my $seed_piece  = '';
    my $seed_piece2 = '';
    my $seed2;
    if ( defined $self->{seed} ) {
        my $seed = $self->{seed};
        $seed_piece .= "set seed=$seed;\n";
        $seed2 = $seed + 10000;
        $seed_piece2 .= "set seed=$seed2;\n";
    }
    if ( defined $self->{swapseed} ) {
        my $swapseed = $self->{swapseed};
        $seed_piece .= "set swapseed=$swapseed;\n";
        my $swapseed2 = $seed2 + 1000;
        $seed_piece2 .= "set swapseed=$swapseed2;\n";
    }

#print "reproducible: ", "  ", $default_arguments->{reproducible}, "  ", $self->{reproducible}, "\n";
    $seed_piece2 = '' if ( !$self->{reproducible} );

    # print "seed piece2: [$seed_piece2] \n";
    # exit;

    $self->{max_stored_gen} = undef;
    my @generation_toponumber_hashrefs = ();
    foreach ( 1 .. $n_runs ) {
        push @generation_toponumber_hashrefs, {};
    }
    $self->{n_distinct_topologies}          = 0;
    $self->{generation_toponumber_hashrefs} = \@generation_toponumber_hashrefs;    # post burn-in

    $self->{newick_number_map} = {};
    $self->{number_newick_map} = {};
    $self->{topology_count}  = {};    # total counts (i.e. summed over runs) of topologies
$self->{chain_data} = {}; # keys are param names, values ChainData objects

    print "# Delta temperature: $delta_temperature.\n";
    my $middle_piece =
        "execute $alignment_nex_filename;\n"
      . "set precision=6;\n"
      . "lset rates=invgamma;\n"
      . "prset aamodelpr=fixed(wag);\n"
      . "$prset_pinvarpr"
      .

      # "prset pinvarpr=fixed(0.15);\n" .
      "mcmcp minpartfreq=0.02;\n"
      .  # bipartitions with freq. less than this are not used in the  diagnostics (default is 0.10)
      "mcmcp allchains=yes;\n"
      . "mcmcp burninfrac=$burnin_fraction;\n"
      . "mcmcp nchains=$n_temperatures;\n"
      . "mcmcp nchainsout=$n_temperatures_out;\n"
      . "mcmcp nswaps=$n_swaps;\n"
      . "mcmcp nruns=$n_runs;\n"
      . "mcmcp temp=$delta_temperature;\n"
      . "mcmcp samplefreq=$sample_freq;\n"
      . "mcmcp printfreq=$print_freq;\n"
      . "mcmcp checkpoint=yes checkfreq=$chunk_size;\n";

    #  "mcmcp filename=$file_basename;\n" .

    my $end_piece = "sump;\n" . "sumt;\n" . "end;\n";
    $self->{mrbayes_block1} =
      $begin_piece . $seed_piece . $middle_piece . "mcmc ngen=$chunk_size;\n" . $end_piece;
    $self->{mrbayes_block2} = $begin_piece . $seed_piece2 .    
      $middle_piece . "mcmc append=" . $self->{append} . " ngen=$chunk_size;\n" . $end_piece;
    $self->setup_id_species_map();


# no mpi for now ...
    if (0 or $self->{use_mpi} ) {    # check whether can actually use mpi as requested
        my $which_mpirun = `which mpirun`;

        #    print "which mpi: [$which_mpirun] \n";
        if (`which mpirun`) {    # mpirun is present
                                 # check for parallel version of Mr Bayes (mb)
            my $mb_test_output = ` mb nonexistent_file `;    # this should exit after error, but
                 # output will tell whether parallel version or not
            my $mb_parallel_version = 0;
            for ( split( "\n", $mb_test_output ) ) {
                $mb_parallel_version = 1 if (/(Parallel version)/);
                last if (/Distributed under the GNU General Public License/);
            }
            $self->{use_mpi} = $mb_parallel_version;
        }
        else {
            $self->{use_mpi} = 0;
        }
    }
    else {

        # leave use_mpi false.
    }
    print "# use mpi: [", $self->{use_mpi}, "]\n";

    return $self;
}

sub run {
    my $self = shift;

    my $chunk_size              = $self->{chunk_size};
    my $ngen                    = $chunk_size;
    my $file_basename           = $self->{file_basename};
    my $stdout_newline_interval = 10 * $self->{chunk_size};

    my $n_chains = $self->{n_runs} * $self->{n_temperatures};
    my $np =
      ( defined $self->{max_processors} )
      ? min( $n_chains, $self->{max_processors} )
      : $n_chains;

    #print("top of run_chunk. mb_block: $mb_block \n");

    my $command = $self->{mb_name} . ' mb_chunk_control.nex';

    if ( $self->{use_mpi} ) {
        $command = "mpirun -np $np " . $command;
    }
  print "mb command: $command \n"; # exit;

###### First chunk. ######
    # Run:

    my $mb_output_string = $self->run_chunk( $self->{mrbayes_block1}, $command );
    open my $fh, ">", "first_chunk.stdout";
    print $fh "$mb_output_string \n";
    close $fh;

    # Analyze:
    $self->mc3swap($mb_output_string);

    my ( $converged, $conv_string ) = ( 0, '' );
    my $converge_count += $converged;
    my $converge_filename = $file_basename . ".converge";
    open my $fhc, ">", "$converge_filename";
    print $fhc "$ngen    $conv_string   $converge_count \n";

  #  print "$ngen    $conv_string   $converge_count \n";

###### Later chunks: ######
    for(
        my $prev_chunk_ngen = $ngen, $ngen += $chunk_size ;
        $ngen <= $self->{max_gens} ;
        $prev_chunk_ngen = $ngen, $ngen += $chunk_size
      )
    {    # loop over later chunks.
        my $mrbayes_block2 = $self->{mrbayes_block2};

        # Run the chunk:
        $mrbayes_block2 =~ s/ngen=\d+;/ngen=$ngen;/;    # subst in the new ngen

        $mb_output_string = $self->run_chunk( $mrbayes_block2, $command );
        open $fh, ">", "later_chunk.stdout";
        print $fh "$mb_output_string \n";
        close $fh;

	# print "Analyze the chunk: \n";
        # Analyze the chunk:
        $self->mc3swap($mb_output_string);              # mcmcmc swap

        $self->topo_analyze($prev_chunk_ngen);          # topologies

        $self->param_analyze($prev_chunk_ngen);
        #****************************************************************

        ( $converged, $conv_string ) = $self->test_convergence($file_basename);
        $converge_count += $converged;
        print $fhc "$ngen  $conv_string  $converge_count\n";
        printf( "%5i  %3i\n", $ngen, 
              #  $conv_string, 
                $converge_count );

        #    print "\n" if ( ( $ngen % $stdout_newline_interval ) == 0 );
#	print "converge count: $converge_count \n";
        last if ( ( $self->{n_runs} > 1) and ($converge_count >= $self->{converged_chunks_required} ) );
    }    # end of loop over chunks
    close $fhc;
    return;
}

sub run_chunk {
    my $self     = shift;
    my $mb_block = shift;
    my $command  = shift;
    open my $fh, ">", "mb_chunk_control.nex";    # run params for first chunk
    print $fh "$mb_block";
    close $fh;
#exit;
    #print "In run_chunk. before mb.\n";
    my $mb_output_string = `$command`;           # run the chunk
                                                 #print "In run_chunk. after mb.\n";
    $mb_block =~ /ngen=(\d+);/;
    $self->{ngens_run} = $1;
    return $mb_output_string;
}

sub mc3swap {
    my $self             = shift;
    my $mb_output_string = shift;
    my $mc3swap_filename = $self->{file_basename} . ".mc3swap";

    my $mode = ">>";
    if ( defined $self->{mc3_swap_info} ) {
        my @this_chunk_mc3_swap_info =
          split( " ", $self->extract_swap_info($mb_output_string) );
        my @cumulative_mc3_swap_info = split( " ", $self->{mc3_swap_info} );

        #    while (my ($i, $v) = each @this_chunk_mc3_swap_info) {
        for my $i ( 0 .. $#this_chunk_mc3_swap_info ) {
            my $v = $this_chunk_mc3_swap_info[$i];
            $cumulative_mc3_swap_info[$i] += $v;
        }

        $self->{mc3_swap_info} = join( " ", @cumulative_mc3_swap_info );

    }
    else {
        $mode = ">";
        $self->{mc3_swap_info} =
          $self->extract_swap_info($mb_output_string);    # $this_chunk_mc3_swap_info;
    }
    open my $fhmc3, "$mode", "$mc3swap_filename";
    print $fhmc3 $self->{ngens_run}, "  ", $self->{mc3_swap_info}, "\n";
}

sub topo_analyze {
    my $self            = shift;
    my $prev_chunk_ngen = shift || $self->{ngens_run} - $self->{chunk_size};    #
    my $ngen            = $self->{ngens_run};
#print "before retrieve topology samples $ngen \n";
    $self->retrieve_topology_samples( undef, $prev_chunk_ngen );    #read in from * .run?.t file
#print "after retrieve topology samples $ngen \n";
#        print "N generations so far: $ngen \n";
    my $histogram_filename = $self->{file_basename} . "." . "topology_histograms";
    open my $fhhist, ">", "$histogram_filename";
    print $fhhist "# After $ngen generations. \n",
      $self->{topo_chain_data}->{histograms}->histogram_string('by_bin_weight');
    my @topo_L1_distances = $self->{topo_chain_data}->{histograms}->avg_L1_distance();
 printf $fhhist ( "# L1:   %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f \n# Linf: %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f  \n\n", @topo_L1_distances[ 0 .. 11 ] );
    my $number_newick = $self->{number_newick_map};
    for my $topo_number (1..10000){
      if(exists $number_newick->{$topo_number}){
	my $newick = $number_newick->{$topo_number};
	printf $fhhist ("# %4i  %s \n", $topo_number, $newick);
      }else{
	last;
      }
    }
  
 close $fhhist;

    $histogram_filename = $self->{file_basename} . "." . "splits_histograms";
    open $fhhist, ">", "$histogram_filename";
    print $fhhist "# After $ngen generations. \n",
      $self->{splits_chain_data}->{histograms}->histogram_string('by_bin_weight');
    my @splits_L1_distances = $self->{splits_chain_data}->{histograms}->avg_L1_distance();

# $max_diff /=  ($self->{splits_chain_data}->{histograms}->get_total_counts() / ($self->{n_runs} * ($self->{n_taxa} -3)));
    printf $fhhist ( "# L1:   %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f \n# Linf: %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f  \n\n", @splits_L1_distances[ 0 .. 11 ] );


    # $avg_L1, $avg_L1x, $max_diff); #$self->{min_binweight}));
    close $fhhist;
    return (\@topo_L1_distances, \@splits_L1_distances);
}

sub param_analyze {
    my $self = shift;
    my $prev_chunk_ngen = shift || $self->{ngens_run} - $self->{chunk_size};    #
#print "before retrieve param samples. \n";
    $self->retrieve_param_samples($prev_chunk_ngen);    # read in from *.run?.p file
#print "after retrieve param samples. \n";
  my @prams = sort keys %{ $self->{chain_data}};
  #  print join(" ", @prams), "\n";
   # for my $chain_data_obj ( values %{ $self->{chain_data} } ) {
       for my $the_param (@prams){
      #    print "Parameter: $the_param\n";
       my $chain_data_obj = $self->{chain_data}->{$the_param};
        my $histogram_filename =
          $self->{file_basename} . "." . $chain_data_obj->{parameter_name} . "_histograms";
        open my $fhhist, ">", "$histogram_filename";
        print $fhhist $chain_data_obj->{histograms}->histogram_string('by_bin_number');
        my ($min_L1, $q1_L1, $median_L1, $q3_L1, $max_L1, $avg_interbip_L1 ) = 
	  $chain_data_obj->{histograms}->avg_L1_distance();
        printf $fhhist ( "# L1 quartiles: %6.3f %6.3f %6.3f %6.3f %6.3f %6.3f\n", 
			 $min_L1, $q1_L1, $median_L1, $q3_L1, $max_L1, $avg_interbip_L1);
        print $fhhist "# Max Kolmogorov-Smirnov D for parameter ",
          $chain_data_obj->{parameter_name},
          " is: ", $chain_data_obj->{histograms}->binned_max_ksd(), "\n\n";
        close $fhhist;
    }

}

sub splits_convergence
{ # looks at splits, i.e. sets of leaves of subtrees produced by removing a branch, for each (non-terminal) branch.
    my $self          = shift;
    my $file_basename = shift;                       # e.g. fam9877
    my $min_hits      = $self->{splits_min_hits};    # ignore splits with fewer hits than this.
    my $max_ok_stddev =
      $self->{splits_max_ok_stddev};    # convergence is 'ok' for a split if stddev < this.
    my $max_ok_avg_stddev =
      $self->{splits_max_ok_avg_stddev};    # convergence is 'ok' on avg if avg stddev < this.

    my $filename = $file_basename . ".nex.tstat";
    open my $fh, "<", "$filename";
    my @lines = <$fh>;

    my ( $avg_stddev, $count, $bad_count ) = ( 0, 0, 0 );
    foreach (@lines) {                      # each line has info on one split
                                            #   print;
        next unless (/^\s*\d/);             # skip if first non-whitespace is not numeral.
        my @cols   = split( " ", $_ );
        my $hits   = $cols[1];
        my $stddev = $cols[3];

        last if ( $hits < $min_hits );
        $count++;                           # counts splits with more than
        $avg_stddev += $stddev;
        if ( $stddev > $max_ok_stddev ) {
            $bad_count++;
            next;
        }
    }
    $avg_stddev = ( $count == 0 ) ? 9.9999 : $avg_stddev / $count;

    my $splits_converged = ( $bad_count == 0 and $avg_stddev < $max_ok_avg_stddev );

    return ( $splits_converged, $count, $bad_count, $avg_stddev );
}

sub modelparam_convergence {    # look at numbers in *.pstat file
                                # to test convergence
    my $self          = shift;
    my $file_basename = shift;
    my $min_ok_ESS    = $self->{modelparam_min_ok_ESS};

    #  my $max_ok_PSRF   = $self->{modelparam_max_ok_PSRF};
    my $max_ok_KSD = $self->{modelparam_max_ok_KSD};
    my $string     = ' ';
    my $ngens_skip = int( $self->{burnin_fraction} * $self->{ngens_run} );

    open my $fh, "<", "$file_basename.nex.pstat";
    my @lines = <$fh>;          # 2 header lines, then each line a parameter (TL, alpha, pinvar)
    close $fh;
    my $discard           = shift @lines;
    my $count_param_lines = 0;
    my $KSD_datacol       = 1;
    my $n_bad             = 0;              #n_bad considers LL_KSD

    foreach (@lines) {
        my @cols   = split( " ", $_ );
        my $avgESS = $cols[7];              # col 6 is the min ESS among the runs, col 7 is avg.
        next unless ( $avgESS =~ /^\d*[.]?\d+/ );    #and $PSRF =~ /^\d*[.]?\d+/ );

        $string .= sprintf( "%4.1f  ", $avgESS );     #$xxx; # "$avgESS $PSRF "; #without PSRF

        #  $string .= sprintf( "%3.0f %6.4f ", $avgESS, $PSRF ); #$xxx; # "$avgESS $PSRF ";
        # print "string $string   $KSDmax \n";
        if ( $avgESS < $min_ok_ESS ) {

            #	   or $PSRF > $max_ok_PSRF ) {
            $n_bad++;    # this parameter is 'bad' i.e. doesn't look converged.
        }
    }
    my @KSDmaxes = ();
    my @L1s      = ();

    for ( @{ $self->{param_names} } ) {
        my $KSDmx = $self->KSDmax($_);
        $n_bad++ if ( $KSDmx > $max_ok_KSD );
        push @KSDmaxes, $KSDmx;
        my @quartile_L1s = # i.e. min, 1st_quartile, median, 3rd_quartile, max
          $self->{chain_data}->{$_}->{histograms}->avg_L1_distance();

        $n_bad++ if ( $quartile_L1s[2] > $self->{max_ok_L1} );
        push @L1s, $quartile_L1s[2]; # median
    }
    $string .= "   " . join( " ", map sprintf( "%5.3f", $_ ), @KSDmaxes );
    $string .= "   " . join( " ", map sprintf( "%5.3f", $_ ), @L1s );
    return ( $n_bad, $string );
}

sub test_convergence {
    my $self          = shift;
    my $file_basename = shift;    # e.g. fam9877.nex

    my ( $splits_converged, $splits_count, $splits_bad_count, $splits_avg_stddev ) =
      $self->splits_convergence($file_basename);
    my ( $modelparam_n_bad, $modelparam_string ) = $self->modelparam_convergence($file_basename);
#print "A: ", $self->{splits_chain_data}->{histograms}->get_total_counts(), "\n";
#print "B: ", $self->{n_runs}, "  ", $self->{n_taxa}, "\n";
    my $n_topos_each_run =
      $self->{splits_chain_data}->{histograms}->get_total_counts() /
      ( $self->{n_runs} * ( $self->{n_taxa} - 3 ) );
#print $self->{splits_chain_data}->{histograms}->get_total_counts(), "\n";
#print "n topos each run: $n_topos_each_run \n";

    my ( $topo_L1, $topo_L1x, $topo_max_diff ) =
      $self->{topo_chain_data}->{histograms}->avg_L1_distance();
    $topo_max_diff /= $n_topos_each_run;
    my $set_size = $self->{n_taxa} - 3;    # number of non-terminal edges in unrooted tree.
  #  my ( $splits_avg_L1d, $splits_interclstr_L1d, $splits_q3_L1d, $splits_max_range, $splits_rms_range,
#	 $above_threshold_string1, $above_threshold_string2 ) =
my @xs = 
      $self->{splits_chain_data}->{histograms}->avg_L1_distance( undef, $set_size );
my @quartile_L1s = @xs[0..4]; my $avg_intercluster_L1 = $xs[5];
my $quartile_mbds = @xs[6..10]; my $avg_intercluster_mbd = $xs[11];
my @above_threshold_strings = @xs[12..15];
    #  $splits_max_diff /= $n_topos_each_run; #  * ($self->{n_taxa} - 3) );
my $fs7 = join("", ('%4.3f ' x 7));
    my $conv_string =
sprintf("%6.3f  ", $splits_avg_stddev);  #,  @xs[0..11]);
#      sprintf(
#        "%5.3f %5.3f %5.3f %5.3f %5.3f %5.3f ",
#        $splits_avg_stddev, $splits_avg_L1d, $splits_interclstr_L1d, $splits_q3_L1d, $splits_max_range, $splits_rms_range) . " $modelparam_string  $modelparam_n_bad   ";
my ($L1stats, $L2stats, $Linfstats, $nbbdstats) =  $self->{splits_chain_data}->{histograms}->four_distance_stats( undef, $set_size );
#    $conv_string .= join("  ", @above_threshold_strings) . "  " . $xs[16] . "  $modelparam_string  $modelparam_n_bad   ";
$conv_string .= sprintf("$fs7 $fs7 $fs7 $fs7 ", @$L1stats, @$L2stats, @$Linfstats, @$nbbdstats) . 
  " $modelparam_string  $modelparam_n_bad   ";

# join(" ", @$L1stats) . "   " .
# join(" ", @$L2stats) . "   " .
# join(" ", @$Linfstats) . "   " .
# join(" ", @$nbbdstats) . "  $modelparam_string  $modelparam_n_bad   ";
    my $converged = ( $splits_converged and $modelparam_n_bad == 0 );

    return ( $converged ? 1 : 0, $conv_string );
}

sub extract_swap_info {
    my $self               = shift;
    my $mb_stdout_string   = shift;
    my @mb_stdout_lines    = split( "\n", $mb_stdout_string );
    my $n_lines_to_extract = 0;
    my $extract_next_n     = 0;
    my $n_runs             = undef;
    my $n_chains           = undef;
    my $out_string         = '';
    foreach (@mb_stdout_lines) {

        if (/number of chains to (\d+)/) {
            $n_chains           = $1;
            $n_lines_to_extract = $n_chains + 4;
            last if ( defined $n_runs );
        }
        elsif (/number of runs to (\d+)/) {
            $n_runs = $1;
            last if ( defined $n_chains );
        }
    }
    my $run;
    my %run_string = ();
    foreach (@mb_stdout_lines) {
        if (/Chain swap information for run (\d+)/) {
            $run            = $1;
            $extract_next_n = $n_lines_to_extract;
        }
        $out_string .= "$_\n" if ( $extract_next_n > 0 );
        $extract_next_n--;
        if ( $extract_next_n == 0 ) {
            $run_string{$run} = $out_string;
            $out_string = '';
            last if ( $run == $n_runs );
        }
    }
    $out_string = '';

    foreach ( keys %run_string ) {

        #print "$_  ", $run_string{$_}, "\n";
        my @lines = split( "\n", $run_string{$_} );
        splice @lines, 0, 4;

        #  print join("\n", @lines);

        my %ij_swap_pA    = ();
        my %ij_swap_tries = ();
        foreach my $i ( 1 .. $n_chains ) {
            my $l = $lines[ $i - 1 ];
            $l =~ s/^\s*\d+\s+[|]\s+//;
            my @xs     = split( " ", $l );
            my $n_ntry = $i - 1;
            my $n_pA   = $n_chains - $i;
            foreach my $j ( 1 .. $n_ntry ) {

                #	print "swap_tries key: [$i $j]\n";
                $ij_swap_tries{"$i $j"} = shift @xs;
            }
            foreach ( 1 .. $n_pA ) {
                my $j = $_ + $i;

                #	print "swap_pA key: [$j $i]\n";
                $ij_swap_pA{"$j $i"} = shift @xs;
            }
        }    # loop over chains
        my %ij_swap_accepts = ();

        # my @sijs = sort {$a cmp $b} keys %ij_swap_tries;
        # foreach (@sijs) {

        foreach my $diff ( 1 .. $n_chains - 1 ) {
            foreach my $i ( 1 .. $n_chains - 1 ) {
                my $j = $i + $diff;

                last if ( $j > $n_chains );
                my $key = "$j $i";

                #	print "i,j: $i, $j, key: [$key] \n";
                if ( exists $ij_swap_pA{$key} and exists $ij_swap_tries{$key} ) {
                    $ij_swap_accepts{$key} = $ij_swap_tries{$key} * $ij_swap_pA{$key};
                    $out_string .=
                      int( $ij_swap_accepts{$key} + 0.5 ) . " " . $ij_swap_tries{$key} . "  ";

 #	  print "i,j: $i, $j, ", int( $ij_swap_accepts{$key} + 0.5 ) . " " . $ij_swap_tries{$key} . "\n";
                }
                else {
                    warn "key $key present in neither ij_swap_tries nor ij_swap_pA.\n";
                }
            }
            $out_string .= ' ';
        }
        $out_string .= ' ';
    }    # loop over runs
    return $out_string;
}

sub KSDmax {    # just gets the binned KSDmax for the parameter specified by the argument.
    my $self       = shift;
    my $param_name = shift;    # data column to use.
    return $self->{chain_data}->{$param_name}->{histograms}->binned_max_ksd();
}

sub retrieve_param_samples {
    # read data from  run?.p files
    # store each param data in separate array of gen/paramval hashrefs
    my $self               = shift;
    my $prev_chunk_max_gen = shift || 0;                         # use only generation > this.
    my $pattern            = $self->{alignment_nex_filename};    # e.g. fam9877.nex
    my $n_runs             = $self->{n_runs};
    my $n_temperatures = $self->{n_temperatures};
    my $n_temperatures_out = $self->{n_temperatures_out};
    # get parameter names from .p file.
    my $dot_p_filename = ($n_runs > 1)? "$pattern.run1.p" : "$pattern.p";

#print "in retrieve param .... prev_chunk_max_gen: $prev_chunk_max_gen \n";
    # print "dotpfilename: $dot_p_filename \n";
    open my $fh1, "<", "$dot_p_filename";
    <$fh1>;                                                      # discard first line.
    my @param_names = split( " ", <$fh1> );
close $fh1;

    if ( shift @param_names ne 'Gen' ) {
        warn "In retrieve_param_samples. Unexpected parameter name line: ",
          join( " ", @param_names ), "\n";
    }
    $self->{param_names} = \@param_names;
    my %col_param = ();

    #  while ( my ( $i, $param_name ) = each @param_names ) {
#print "Parameter names: ", join(" ", @param_names), "\n";
    for my $i ( 0 .. $#param_names ) {
        my $param_name = $param_names[$i];
        $col_param{$i} = $param_name;    # 0 -> LnL_chain_data, 1 -> TL_chain_data, etc.
    }

    while ( my ( $i, $param_name ) = each %col_param ) {    # @param_names ) {
#      print "in retrieve_param... i, param_name: $i $param_name \n";
        if ( !exists $self->{chain_data}->{$param_name} ) {
#              print STDERR "in retrieve_param_samples. about to construct ChainData obj, parameter name: ", $param_name, "\n";
#	      print STDERR "gen_spacing: ", $self->{sample_freq}, "\n";
            $self->{chain_data}->{$param_name} = CXGN::Phylo::ChainData->new(
                {
                    'parameter_name' => $param_name,
                    'n_runs'         => $n_runs,
            'n_temperatures' => $self->{n_temperatures},
                 'n_temperatures_out' => $self->{n_temperatures_out},
                    'gen_spacing'    => $self->{sample_freq},
                    'binnable'       => 1
                }
            );    # binnable = 1 -> continuous parameter values needing to be binned.
        }
    }
    my $new_max_gen;

    # Read param values from .p file and store in ChainData objects.
#print "NRUNS: $n_runs.\n";
    foreach my $i_run ( 1 .. $n_runs ) {    #loop over runs
       my $param_count = {};
        my $param_file = ($n_runs > 1) ? "$pattern.run$i_run.p" : "$pattern.p";
        open my $fhp, "<", "$param_file";
        my @all_lines = <$fhp>;
        my @x = split( " ", $all_lines[-1] );
        $new_max_gen = shift @x;
        while (@all_lines) {
            my $line = pop @all_lines;      # take the last line
            chomp $line;
            next
              unless ( $line =~ /^\s*(\d+)\s+/ );    # first non-whitespace on line should be number
            my @cols       = split( " ", $line );
            my $generation = shift @cols;            # now @cols just has the parameters

            last if ( $generation <= $prev_chunk_max_gen );
      #      my $param_string = join( "  ", @cols );

            for my $i ( 0 .. $#cols ) {
                my $param_value = $cols[$i];
                my $param_name  = $col_param{$i};
           #     print "storing $param_name value: $param_value   generation: $generation, run: $i_run\n";
                $param_count->{$param_name}++;
#print "WWW: ", join("; ", keys %{$self->{chain_data}->{$param_name}->{setid_gen_value}}), "\n";
                $self->{chain_data}->{$param_name}
                  ->store_data_point( $i_run - 1, $generation, $param_value );
#print "YYY: ", join("; ", keys %{$self->{chain_data}->{$param_name}->{setid_gen_value}}), "\n";
            }
        }
   #    print "run $i_run.\n";
       # while(my($p,$c) = each %$param_count){
       #    print "   $p  $c \n";
       # }
    }    # loop over runs.
    # get rid of pre-burn-in data points, and rebin as desired.
 #   print "number of params stored: ", scalar keys %{ $self->{chain_data} }, "\n";
    while ( my ( $param, $chain_data_obj ) = each %{ $self->{chain_data} } ) {

       # while(my($s,$gv) = each  %{$chain_data_obj->{setid_gen_value}}){
       #    print "before binning. ABCDEF:   $param  $s  ", scalar keys %$gv, "\n";
       # }

   #    print "new_max_gen, next_bin_gen:  $new_max_gen   ", $chain_data_obj->{next_bin_gen}, "\n";
        $chain_data_obj->delete_pre_burn_in();
 while(my($s,$gv) = each  %{$chain_data_obj->{setid_gen_value}}){
    #      print "after delete_pre_burn_in. ABCDEF:   $param  $s  ", scalar keys %$gv, "\n";
       }
        die "chain_data_obj->{histograms} is not defined." if ( !defined $chain_data_obj->{histograms} );
        if ( $new_max_gen >= $chain_data_obj->{next_bin_gen} ) {
            $chain_data_obj->bin_the_data();
      #      print "$new_max_gen; binning the data. \n"; #sleep(2);
            $chain_data_obj->{next_bin_gen} = 2 * $new_max_gen;
        }

       # while(my($s,$gv) = each  %{$chain_data_obj->{setid_gen_value}}){
       #    print "after binning. ABCDEF:   $param  $s  ", scalar keys %$gv, "\n";
       # }
    }
}

# end of reading in parameter values

sub retrieve_topology_samples {

    # read data from ...run?.t files
    # store each param data in separate array of gen/paramval hashrefs
    my $self = shift;
    my $pattern = shift || $self->{alignment_nex_filename};    # e.g. fam9877.nex
    my $prev_chunk_max_gen = shift || 0;                        # use only generation > to this.
    # print STDERR "AAA: $prev_chunk_max_gen \n";
    my $n_runs             = $self->{n_runs};
  my $n_temperatures = $self->{n_temperatures};
    my $n_temperatures_out = $self->{n_temperatures_out};
    my %newick_number_map  = %{ $self->{newick_number_map} };
    my %number_newick_map  = %{ $self->{number_newick_map} };
    my $topology_number    = $self->{n_distinct_topologies};
    my $generation;
    my $newick;
    my @generations = ();
#my %newick_count = ();

#print "in retrieve topo .... prev_chunk_max_gen: $prev_chunk_max_gen \n";

    # Read param values from .t file and store in ChainData objects.
#    print STDERR "In retrieve_topology_samples. gen_spacing: ", $self->{sample_freq}, "\n";
    if ( !defined $self->{topo_chain_data} ) {
        $self->{topo_chain_data} = CXGN::Phylo::ChainData->new(  # \@generation_toponumber_hashrefs,
            {
                'parameter_name' => 'topology',
                'n_runs'         => $n_runs,
               'n_temperatures' => $self->{n_temperatures},
                 'n_temperatures_out' => $self->{n_temperatures_out},
                'gen_spacing'    => $self->{sample_freq},
                'binnable'       => 0
            }
        );                                                       #
    }
    if ( !defined $self->{splits_chain_data} ) {
        $self->{splits_chain_data} = CXGN::Phylo::ChainData->new(
            {
                'parameter_name' => 'splits',
                'n_runs'         => $n_runs,
            'n_temperatures' => $self->{n_temperatures},
                 'n_temperatures_out' => $self->{n_temperatures_out},
                'gen_spacing'    => $self->{sample_freq},
                'binnable'       => 0,
                'set_size'       => $self->{n_taxa} - 3          # n interior edges, i.e. number of splits for each topology
            }
        );                                                       #
    }
    foreach my $i_run ( 1 .. $n_runs ) {                         #loop over runs

        my $topo_file = ($n_runs > 1)? "$pattern.run$i_run.t" : "$pattern.t";
#	print "topo file to read from: $topo_file \n";
        open my $fht, "<", "$topo_file";
        my @all_lines = <$fht>;                                  # read chunk
	#print "all_lines, number of lines: ", scalar @all_lines, "\n";
        # analyze the chunk.
        #my $index = -1;
        my @chunk_lines = ();
        while (@all_lines) {
            my $line = pop @all_lines;                           # take the last line
            chomp $line;
            if ( $line =~ s/^\s*tree gen[.](\d+)\s*=\s*.{4}\s+// ) {

         #   if($line =~ s/^\s*tree gen[.](\d+)\s*//){
               $generation = $1;
           #    $newick = $line;
               # my @columns = split(" ", $line);
               #  my ($newick, $iT, $iW, $lnISW) = @columns[2,4,5,6];
                #		print "generation, prev chunk max gen:  $generation  $prev_chunk_max_gen\n";
                # skip data for generations which are already stored:
                if ( $generation > $prev_chunk_max_gen ) {
                #   print "Unshifting generation $generation into chunk_lines array\n";
                    unshift @chunk_lines, "$generation  $line";
                }
                else {
                    last;
                }

                # if ( $generation <= $prev_chunk_max_gen );
            }
	  }
	#print "In retrieve_topo... n chunk lines: ", scalar @chunk_lines, "\n";
        for my $line (@chunk_lines) {
        #   my @columns = split(" ", $line);
            #    my ($generation, $newick, $iT, $iW, $lnISW) = @columns[0, 1, 3, 4, 5];
         #  my $RTWindex = $iW + $self->{n_temperatures}*($iT + $self->{n_temperatures_out}*($i_run-1));
           if($line =~ /^\s*(\d+)\s+(\S+)/){
              ($generation, $newick) = ($1, $2);
           } else {
              die "line has unexpected format: $line \n";
           }
            # my ( $generation, $newick );
            # if (/^(\d+)\s+(.+)\s*$/) {
            #     ( $generation, $newick ) = ( $1, $2 );
            #     print "$generation  $newick \n";
            # }
            # else {
            #     warn "string has unexpected format: $_.\n";
            # }

            # reroot each tree using the same sequence as outgroup
            #print "\n\n", "newick: $newick \n";
            # my $nw = "'" . $newick . "'";
            # if (0) {
            #     my $rerooted_newick = ` echo $nw | nw_reroot - 1 `;
            #     print "rerooted newick: $rerooted_newick \n";

            #     # $newick = $rerooted_newick;
            # }
            $newick =~ s/;\s*$//; # remove final semi-colon.
	    $newick =~ s/^\s+//; # remove init whitespace.
            #    my $gen_run_newick = "$generation  $i_run  $newick \n";
            # open my $fhxxx, ">>", "newicks";
            #       print $fhxxx "$generation  $i_run  $newick \n";
            # close $fhxxx;
#	    print STDERR "In retrieve_topos (bef): [$newick] \n";
            $newick =~ s/:[0-9]+[.][0-9]+(e[-+][0-9]{2,3})?(,|[)])/$2/g;    # remove branch lengths
 # print STDERR "In retrieve_topos (bef1): [$newick] \n";
            $newick =~ s/^\s+//;
 # print STDERR "In retrieve_topos (bef2): [$newick] \n";
            $newick =~ s/;\s*$//;
 # print STDERR "In retrieve_topos (bef3): [$newick] \n";

#	    print STDERR "In retrieve_topos (aft): [$newick] \n";
            my $mask = ( 1 << $self->{n_taxa} ) - 1;                        # n_taxa 1's
            my $split_count =
              {};    # $self->{split_count}; # keys are split bit patterns, values: counts

#print STDERR "In ret topo. bef order_newick. newick: $newick  $split_count, $mask.\n";
            my ( $minlabel, $ordered_newick, $tree_labels, $split_bp ) =
              order_newick( $newick, $split_count, $mask, 0 );
            $newick = $ordered_newick;
#	    print STDERR "ordered newick: $newick\n";
            if ( $newick =~ s/^\s*[(]1,/'(1,(/ ) { # go from form (1,(...),(...)) with trifurcation, to (1,((...),(...))) with only bifurcations
                $newick .= ")'";
            }
            else {
                die "newick: $newick doesn't start with '(1,' as expected.\n";
            }

            if ( !exists $newick_number_map{$newick} ) {
                $topology_number++;

 #		  print "run $i_run encountered new topo number, newick:{{{   $topology_number   $newick }}}\n";
                $newick_number_map{$newick}          = $topology_number;    # 1,2,3,...
                $number_newick_map{$topology_number} = $newick;
            }
         #   $self->{toponumber_count}->{$topology_number}++;
            push @generations, $generation;
            $self->{topo_chain_data}
              ->store_data_point( $i_run - 1, $generation, $newick_number_map{$newick} );
	    $self->{topology_count}->{$newick}++;
 #       $generation_toponumber_hashrefs[ $i_run - 1 ]->{$generation} = $newick_number_map{$newick};

            my $the_split = join( ";", keys %$split_count );
	    # print "the split: $the_split \n";
            $self->{splits_chain_data}->store_data_point($i_run-1, $generation, $the_split );
	  }
    }    # loop over runs.

    $self->{topo_chain_data}->delete_pre_burn_in();
    $self->{splits_chain_data}->delete_pre_burn_in();

    $self->{newick_number_map}     = \%newick_number_map;
    $self->{number_newick_map}     = \%number_newick_map;
    $self->{n_distinct_topologies} = $topology_number;
    return $self->{topo_chain_data};
}

# end of reading in topologies
sub get_topology_count{
my $self = shift;
return $self->{topology_count};
}

sub clear_topology_count{
my $self = shift;
$self->{topology_count} = {};
}

sub retrieve_number_id_map {
    my $self = shift;
    my $pattern = shift || $self->{alignment_nex_filename};    # e.g. fam9877.nex

    my $trprobs_file = "$pattern.trprobs";
    open my $fh, "<", "$trprobs_file";

    my %number_id_map = ();
    while ( my $line = <$fh> ) {
        last if ( $line =~ /^\s*tree\s+tree_/ );
        if ( $line =~ /^\s*(\d+)\s+(\S+)/ ) {
            my $number = $1;
            my $id     = $2;
            $id =~ s/[,;]$//;    # delete final comma
            $number_id_map{$number} = $id;
        }
    }
    return \%number_id_map;
}

# sub count_post_burn_in_topologies {
#   my $self                        = shift;
#   my $generation_toponumber_hrefs = shift;
#   my %topo_count                  = ();	# key: topology number, value: arrayref with counts in each run
#   # e.g. $topo_count{13} = [3,5] means that topo 13 occurred 3 times in run1, 5 times in run 2.
#   my $total_trees = 0;
#   foreach my $i_run ( 1 .. scalar @$generation_toponumber_hrefs ) {
#     my $generation_toponumber =
#       $generation_toponumber_hrefs->[ $i_run - 1 ]; # hashref; key: generation, value: topo number.
#     my $trees_read_in = scalar keys %{$generation_toponumber};

#     # store trees from array in hash, skipping burn-in
#     my $n_burnin = int( $self->{burnin_fraction} * $trees_read_in );
#     my @sorted_generations =
#       sort { $a <=> $b } keys %{$generation_toponumber};
#     foreach my $i_gen ( @sorted_generations[ $n_burnin .. $trees_read_in - 1 ] ) {
#       my $topo_number = $generation_toponumber->{$i_gen};
#       if ( !exists $topo_count{$topo_number} ) {
# 	$topo_count{$topo_number} = [ (0) x scalar @$generation_toponumber_hrefs ];
#       }

#       #print "run, topo#: $i_run  $topo_number \n";
#       $topo_count{$topo_number}->[ $i_run - 1 ]++;
#       $total_trees++;
#     }
#     print STDERR "\n";
#     $i_run++;
#   }
#   return ( \%topo_count, $total_trees );
# }

sub restore_ids_to_newick {
    my $self          = shift;
    my $newick        = shift;
    my $number_id_map = shift;

    foreach my $number ( keys %$number_id_map ) {
        my $id = $number_id_map->{$number};
        $id .= '[species=' . $self->{id_species_map}->{$id} . ']';
        $newick =~ s/([(,])$number([,)])/$1$id$2/;
    }
    return $newick;
}

sub setup_id_species_map {
    my $self = shift;
    my $file = $self->{alignment_nex_filename};
    if(defined $file and -f $file){
    open my $fh, "<", "$file";
    while ( my $line = <$fh> ) {

        next unless ( $line =~ /^(\S+)\[species=(\S+)\]/ );
	# print "$line \n";
        my $id      = $1;
        my $species = $2;
        $self->{id_species_map}->{$id} = $species;
    }
    # print "number of keys in id_species_map: [", scalar keys %{$self->{id_species_map}}, "]\n";
  }
    return;
}

sub get_id_species_string_array {
    my $self            = shift;
    my $id_species_href = $self->{id_species_map};
    my @string_array    = ();
    for my $id ( keys %$id_species_href ) {
        my $species = $id_species_href->{$id};
        push @string_array, "$id  $species";
    }
    return \@string_array;
}

######################## Non-method subroutines ################################

# given a set of numbers (some of which may occur more than once), which
# are stored as keys in a hash, with the values being how many times they occur
# or more generally whatever weights you want, sort the keys and get the
# cumulative distribution.
sub cumulative_prob {
    my $val_weight_href = shift;    # hashref, key: numbers, values: weights.
    my $sum_weights     = shift;

    my $big_negative      = -1e300;
    my $val_cumeprob_href = { $big_negative => 0 };
    my $cume_prob         = 0;
    foreach ( sort { $a <=> $b } keys %{$val_weight_href} ) {
        $cume_prob += $val_weight_href->{$_} / $sum_weights;
        $val_cumeprob_href->{$_} = $cume_prob;

        #		print "$i $_ $cume_prob ", $val_count_hashes[$i]->{$_}, "\n";
    }

    #	print "\n";
    return $val_cumeprob_href;
}

sub Kolmogorov_Smirnov_D {

    # get the maximum difference between two empirical cumulative distributions.
    # Arguments are two hashrefs, each representing an empirical cumulative distribution.
    # Each key is a data point (a real number), and the corresponding hash value is
    # the proportion of data pts <= to it. So the largest value should be 1.
    my $val_cumeprob1 = shift;
    my $val_cumeprob2 = shift;
    my @sorted_vals1  = sort { $a <=> $b } keys %{$val_cumeprob1};
    my @sorted_vals2  = sort { $a <=> $b } keys %{$val_cumeprob2};

    my ( $i1, $i2 ) = ( 0, 0 );

    my $size1 = scalar @sorted_vals1;
    my $size2 = scalar @sorted_vals2;

    my $D = 0;
    while (1) {
        my ( $xlo1, $xhi1 ) = ( $sorted_vals1[$i1], $sorted_vals1[ $i1 + 1 ] );
        my ( $xlo2, $xhi2 ) = ( $sorted_vals2[$i2], $sorted_vals2[ $i2 + 1 ] );
        die "$xlo1 > $xhi2 ??\n" if ( $xlo1 > $xhi2 );
        die "$xlo2 > $xhi1 ??\n" if ( $xlo2 > $xhi1 );

        my ( $cume_prob1, $cume_prob2 ) = ( $val_cumeprob1->{$xlo1}, $val_cumeprob2->{$xlo2} );
        my $abs_diff = abs( $cume_prob1 - $cume_prob2 );
        $D = $abs_diff if ( $abs_diff > $D );
        if ( $xhi1 <= $xhi2 ) {
            $i1++;
        }
        elsif ( $xhi2 <= $xhi1 ) {
            $i2++;
        }
        else {
            die "$xhi1 xhi2 should be numerical.\n";
        }
        last if ( $i1 == $size1 - 1 );
        last if ( $i2 == $size2 - 1 );
    }
    return $D;
}

# new version
sub order_newick {
 # print "XXX: ", join("; ", @_), "\n";
    my $newick      = shift;
    my $split_count = shift;
    my $mask        = shift;
    my $depth       = shift;
    if ( !defined $depth ) {
        $depth = 0;
    }

    # print "$depth \n";
    #print STDERR "\n" if($depth == 0);
    #print STDERR "$depth $newick \n";
    exit if ( $depth > 100000 );

 #   print "   newick: {$newick} \n"; #exit;
    if
      # ( $newick =~ /^([^,]+)$/ ) { # no commas -> this is a leaf!
      ( $newick =~ /^(\d+)(:\d*[.]?\d+)?$/ ) {    # this subtree is leaf!

#        print "leaf branch. newick: $newick \n";
        my $split_bp = 1 << ( $1 - 1 );
        return ( $1, $newick, $1, $split_bp );
    }
    else {                                        # subtree has > 1 leaf.

        #    print "non-leaf branch. newick: $newick \n";
        my $split_bp                = 0;
        my %label_newick            = ();
        my %cladeleaflabelset_count = ();
        $newick =~
          /^[(](.*)[)](:\d+[.]\d+-\d*)?$/;    # remove outer (), and final branch length: e.g. ':0.15'

# print "branch length: $newick  $1  $2 \n";
        my @newick_chars = split( '', $1 );    # without surrounding ()
        my $lmr_paren_count = 0;               # count of left parens - right parens
        my ( $il, $ir ) = ( 0, 0 );
        my $n_chars   = scalar @newick_chars;
        my $min_label = 10000000;
my $max_label = -1;
        foreach (@newick_chars) {
            die "$_ ", $newick_chars[$ir], " not same!\n"
              if ( $_ ne $newick_chars[$ir] );
            if ( $_ eq '(' ) {                 # encountered left paren.
                $lmr_paren_count++;
            }
            if ( $_ eq ')' ) {                 # encountered right paren.
                $lmr_paren_count--;
            }

            if (   ( $ir == $n_chars - 1 )
                or ( $_ eq ',' and $lmr_paren_count == 0 ) )
            {                                  #split
                my $ilast = ( $ir == $n_chars - 1 ) ? $ir : $ir - 1;
                my $sub_newick = join( '', @newick_chars[ $il .. $ilast ] );

               #	       print "subnewick [$sub_newick] il, ilast: $il $ir \n";
		die "In order_newick. depth is $depth; exceeds allowed max. of $MAX_TREE_DEPTH.\n" 
		  if($depth > $MAX_TREE_DEPTH); # (! ($sub_newick =~ /\(.*\)/));
                my ( $label, $ordered_subnewick, $clade_leaf_labels, $subtree_split_bp ) =
                  order_newick( $sub_newick, $split_count, $mask, $depth + 1 );
#		print "ordered subnewick: [$ordered_subnewick] \n";
# exit;
      #	print "CCC:  $depth $label; [$ordered_subnewick]; $clade_leaf_labels; $subtree_split_bp \n";
                $label_newick{$label} = $ordered_subnewick;
                $cladeleaflabelset_count{$clade_leaf_labels}++;

                $split_bp |= $subtree_split_bp;    # bitwise OR of all subtree bitpatterns
                $min_label = min( $min_label, $label );
		$max_label = max( $max_label, $label );
                $il        = $ir + 1;
                $ir        = $il;                         # skip the ','

                #print "il, ir: $il $ir \n";
            }
            else {
                $ir++;
            }

        }    # loop over chars in @newick_chars
        my $ordered_newick = '';
        foreach ( sort { $a <=> $b } keys %label_newick ) { # for low_to_high
#   foreach ( sort { $b <=> $a } keys %label_newick ) {

            $ordered_newick .= $label_newick{$_} . ",";
        }
        $ordered_newick =~ s/,$//;
        $ordered_newick = '(' . $ordered_newick . ')';
        my $clade_leaf_labels = join( "_", keys %cladeleaflabelset_count );

        my $split_bp_complement = ~$split_bp & $mask;
        my $std_split_bp =
          ( $split_bp % 2 == 1 )
          ? $split_bp
          : ~$split_bp & $mask;    ##_complement;
        $split_count->{$std_split_bp}++ if ( $std_split_bp != $mask );
       return ( $min_label, $ordered_newick, $clade_leaf_labels, $split_bp ); # for low_to_high
#  return ( $max_label, $ordered_newick, $clade_leaf_labels, $split_bp );
    }
    die "shouldnt get here, in order_newick\n";
}

# operates on a newick of form (3,(6,4))
# i.e. no whitespace, no branch lengths, ids must be numbers.
# so just parens, commas and numbers
# puts the leaves in order, such that at each node the
# subtree with smaller value is on left. The value of an
# internal node is the min of the values of the two child
# nodes, and the value of a leaf is its id, which must be a number.
# the 'label' of a leaf is its (numerical) id; the label of
# an internal node is the min of labels of its child nodes.
# sub order_newick_old {
#     my $newick      = shift;
#     my $split_count = shift;
#     my $mask        = shift;
#     my $depth       = shift;
#     if ( !defined $depth ) {
#         $depth = 0;
#     }

#     #print STDERR "\n" if($depth == 0);
#     #print STDERR "$depth $newick \n";
#     #exit if($depth > 100);
#     if ( $newick =~ /^(\d+)$/ ) {    # this subtree is leaf!
#         my $split_bp = 1 << ( $1 - 1 );
#         return ( $1, $newick, $1, $split_bp );
#     }
#     else {                           # subtree has > 1 leaf.
#         my $split_bp                = 0;
#         my %label_newick            = ();
#         my %cladeleaflabelset_count = ();
#         $newick =~ /^[(](.*)[)]$/;    # remove outer ()
#         my @newick_chars = split( '', $1 );    # without surrounding ()
#         my $lmr_paren_count = 0;               # count of left parens - right parens
#         my ( $il, $ir ) = ( 0, 0 );
#         my $n_chars   = scalar @newick_chars;
#         my $min_label = 10000000;

#         foreach (@newick_chars) {
#             die "$_ ", $newick_chars[$ir], " not same!\n"
#               if ( $_ ne $newick_chars[$ir] );
#             if ( $_ eq '(' ) {                 # encountered left paren.
#                 $lmr_paren_count++;
#             }
#             if ( $_ eq ')' ) {                 # encountered right paren.
#                 $lmr_paren_count--;
#             }

#             if (   ( $ir == $n_chars - 1 )
#                 or ( $_ eq ',' and $lmr_paren_count == 0 ) )
#             {                                  #split
#                 my $ilast = ( $ir == $n_chars - 1 ) ? $ir : $ir - 1;
#                 my $sub_newick = join( '', @newick_chars[ $il .. $ilast ] );

#                 #       print "subnewick $sub_newick\n";
#                 my ( $label, $ordered_subnewick, $clade_leaf_labels, $subtree_split_bp ) =
#                   order_newick( $sub_newick, $split_count, $mask, $depth + 1 );

#               #print "AAA:  $label; [$ordered_subnewick]; $clade_leaf_labels; $subtree_split_bp \n";
#                 $label_newick{$label} = $ordered_subnewick;
#                 $cladeleaflabelset_count{$clade_leaf_labels}++;

#                 $split_bp |= $subtree_split_bp;    # bitwise OR of all subtree bitpatterns
#                 $min_label = min( $min_label, $label );
#                 $il        = $ir + 1;
#                 $ir        = $il;                         # skip the ','
#             }
#             else {
#                 $ir++;
#             }
#         }    # loop over chars in @newick_chars
#         my $ordered_newick = '';
#         foreach ( sort { $a <=> $b } keys %label_newick ) {
#             $ordered_newick .= $label_newick{$_} . ",";
#         }
#         $ordered_newick =~ s/,$//;
#         $ordered_newick = '(' . $ordered_newick . ')';
#         my $clade_leaf_labels = join( "_", keys %cladeleaflabelset_count );

#         my $split_bp_complement = ~$split_bp & $mask;
#         my $std_split_bp =
#           ( $split_bp % 2 == 1 )
#           ? $split_bp
#           : ~$split_bp & $mask;    ##_complement;
#         $split_count->{$std_split_bp}++ if ( $std_split_bp != $mask );
#         return ( $min_label, $ordered_newick, $clade_leaf_labels, $split_bp );
#     }
#     die "shouldnt get here, in order_newick\n";
# }

# sub Robinson_Foulds_distance {
#     my $split_count1 = shift;
#     my $split_count2 = shift;
#     my $n_splits     = scalar keys %$split_count1;
#     my $n_splits2    = scalar keys %$split_count2;
#     my ( $n_both, $n_1only ) = ( 0, 0 );

#     if ( $n_splits != $n_splits2 ) {

#         #   print "n splits 1,2: $n_splits  $n_splits2 \n";
#         return 0;
#     }
#     for my $split1 ( keys %$split_count1 ) {
#         if ( exists $split_count2->{$split1} ) {
#             $n_both++;
#         }
#         else {
#             $n_1only++;
#         }
#     }
#     die "RF distance inconsistency:  $n_1only ", ( $n_splits - $n_both ), "\n"
#       if ( $n_splits - $n_both != $n_1only );

#     #  print "RF distance: $n_1only\n";
#     return $n_1only;
# }

1;

###########################################################3############################

# sub plot_params{
#   my $self = shift;
#   my @param_names = @{$self->{param_names}};
#   for my $param_name (@param_names) {
#     my $chain_data_obj = $self->{chain_data}->{$param_name};
#     print "param name: $param_name.  ref(chaindataobj): ", ref($chain_data_obj), "\n";
#     my $n_runs = $chain_data_obj->{n_runs};
#     my $run_gen_val = $chain_data_obj->get_run_gen_value();
#     my @gens = sort {$a <=> $b} keys %{$run_gen_val->[0]};
#     my @run_vals = ();
#     for my $i_run (0..$n_runs-1) {
#       my $g_v = $run_gen_val->[$i_run];
#       my @vals = ();
#       for my $gen (@gens) {
# 	push @vals, $g_v->{$gen};
#       }
#       push @run_vals, \@vals;
#     }
#     my @xys = (\@gens, @run_vals);

#     my $gnuplot_obj = GnuplotIF;
#     $gnuplot_obj->gnuplot_plot_xy(@xys);
#     $gnuplot_obj->gnuplot_pause();
#   }
# }

# sub lump_right_tail {
#     my $label_weightslist = shift;
#     my $r_tail_weight     = shift || 0.05;
#     my %label_sumweights  = ();

#     while ( my ( $l, $ws ) = each %$label_weightslist ) {
#         $label_sumweights{$l} = sum(@$ws);
#     }
#     my @sorted_labels = sort { $label_sumweights{$b} <=> $label_sumweights{$a} }
#       keys %$label_weightslist;    #
#     my $n_labels   = scalar @sorted_labels;
#     my $total_hits = sum( map( @{ $label_weightslist->{$_} }, @sorted_labels ) );
#     my $run0_hits  = sum( map( $label_weightslist->{$_}->[0], @sorted_labels ) );
#     my $n_runs     = scalar @{ $label_weightslist->{ $sorted_labels[0] } };

#     my $result       = {};
#     my $cume_weight  = 0;
#     my @cume_weights = ( (0) x $n_runs );
#     foreach my $label (@sorted_labels) {    # loop over categories-
#         my @weights = @{ $label_weightslist->{$label} };
#         @cume_weights = map { $cume_weights[$_] + $weights[$_] } 0 .. $#weights;
#         my $weight = sum(@weights);         # number of hits for this categories, summed over runs.
#         $cume_weight += $weight;
#         $result->{$label} = \@weights;
#         last if ( $label eq $sorted_labels[-1] );
#         if ( $cume_weight >= ( 1 - $r_tail_weight ) * $total_hits ) {
#             my @other_weights = ();
#             for (@cume_weights) {
#                 push @other_weights, $run0_hits - $_;
#             }
#             $result->{ $n_labels + 1000 } = \@other_weights;
#             last;
#         }
#     }
#     return $result;
# }

# sub equal_weight_bins {	#input here is not yet binned, just a few sets of data, each
# 			# just an array of N data points (numbers).
#   my $min_bin_fraction = shift || 0.01;
#   my @data_sets = @_; # each element is array ref storing data points (numbers).

#   my $result         = {}; # keys: binnumbers, values: ref to array of weights.
#   my @data_set_maxes = ();
#   for (@data_sets) {
#     push @data_set_maxes, max(@$_);
#     my @sorted_data_set = sort { $a <=> $b } @$_;
#     $_ = \@sorted_data_set;
#   }
#   my $max_data = max(@data_set_maxes);
#   my $big      = $max_data + 1e100;
#   for (@data_sets) {
#     push @$_, $big;
#   }
#   my $n_data_sets     = scalar @data_sets; #
#   my @n_points        = map( ( scalar @$_ - 1 ), @data_sets );
#   my $n_points_in_set = min(@n_points);
#   warn "Different numbers of data points in different runs: ", join( ", ", @n_points ), "\n"
#     if ( min(@n_points) != max(@n_points) );
#   my $n_total_points = $n_data_sets * $n_points_in_set;

#   my $i                    = 1;
#   my $points_binned_so_far = 0;
#   my $bin_number           = 0;
#   my @next_point_indices   = ( (0) x $n_data_sets );
#   my @counts_this_bin      = ( (0) x $n_data_sets );
#   my $total_this_bin       = 0;
#   while (1) {
#     my $desired_cumulative_points = int( $i * $min_bin_fraction * $n_total_points + 0.5 );
#     my @next_points               = ();
#     while ( my ( $i, $points ) = each @data_sets ) {
#       $next_points[$i] = $points->[ $next_point_indices[$i] ];
#     }
#     my ( $i_min, $min ) = ( 0, $next_points[0] );
#     while ( my ( $i, $v ) = each(@next_points) ) {
#       if ( defined $v and $v <= $min ) {
# 	$min   = $v;
# 	$i_min = $i;
#       }
#     }
#     last if ( $min > $max_data );
#     $counts_this_bin[$i_min]++;
#     $points_binned_so_far++;
#     $total_this_bin++;
#     $next_point_indices[$i_min]++;
#     if ( $points_binned_so_far >= $desired_cumulative_points ) {
#       my @copy = @counts_this_bin;
#       $result->{$bin_number} = \@copy;
#       @counts_this_bin = ( (0) x $n_data_sets );
#       $total_this_bin = 0;
#       $bin_number++;
#       $i++;
#     }
#   }
#   return $result;
# }
