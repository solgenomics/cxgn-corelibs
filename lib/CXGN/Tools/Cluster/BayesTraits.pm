package CXGN::Tools::Cluster::BayesTraits;
use strict;
use base qw/CXGN::Tools::Cluster/;

use CXGN::Tools::Run;
use CXGN::Phylo::Tree;
use File::Temp qw/tempdir/;
use File::Basename;
use constant DEBUG=>$ENV{CLUSTER_DEBUG};

=head1 NAME

 CXGN::Tools::Cluster::BayesTraits

=head1 SYNOPSIS

 Run BayesTraits (multistate or continuous analyses) on the cluster,
 collect output into a nice little data structure and file

=head1 USAGE

 my $btrun = CXGN::Tools::Cluster::BayesTraits->new
           ({
              out => $result_file,
              tree => $tree  });  #or newick => $newick_string

 $btrun->model("continuous");
 $btrun->data({ leafA => { start => 35.5, isoelectric => 1.2 }, 
                leafB => { start => 25.5, isoelectric => 2.2 }, 
                leafC => { start => 32.2, isoelectric => 1.1} 
             });

 $btrun->method("ml"); #max likelihood default, not necessary.  "MCMC" not yet supported
 $btrun->add_command("delta");
 $btrun->add_command("kappa", "lambda");  #can add several at once, array form

 #By default, this will only calculate for the root node.  Use all_nodes() to run on
 #every node with children.  This will take much longer, naturally, but it will
 #be clustered!
 $btrun->all_nodes(); 

 $btrun->submit();
 $btrun->spin();

 my $root_result = $btrun->baseResult();
 
 my $tree_likelihood = $root_result->{lh}; 
 my $start = $root_result->{start};
 my $isoelectric = $root_result->{isoelectric};

 #or, if provided array for data instead of hash:
 my $isoe = $root_result->{trait1};  #if hash provided trait1...x accesses on alphabetical order 

 my $start_variance = $root_result->{start_var};
 my $si_covariance = $root_result->{isoelectric_start_covar}; # or {1_2_covar}
 my $delta = $root_result->{delta};

 my $all_results = $btrun->results();
 my $node_5_start = $all_results->{5}->{start};
 my $root_5_start = $all_results->{1}->{start};

 #if you provide {out => $filepath or \*WF} to constructor, the following will be done
 #automatically after spin()
 open (WF, ">results");
 $btrun->to_file(\*WF);  
 close WF;

=head1 AUTHOR

 C. Carpita <ccarpita@gmail.com>

=cut

sub new {
	my $class = shift;
	my $args = shift;
	my $self = $class->SUPER::new($args);

	die "\nNo input file, send tree instead { tree => \$tree } \n" if $self->infile();

	my $tree = $args->{tree};
	my $newick = $args->{newick};
	die "\nMust send tree file {tree => \$tree } of type CXGN::Phylo::Tree, or a newick string\n"
		unless ($newick || ref($tree) =~ /CXGN::Phylo::Tree/);

	if($newick && ref($tree) =~ /CXGN::Phylo::Tree/){
		die "\nCannot send a tree object AND a newick string...pick one\n";
	}

	$self->{tree} = $tree;

	if($newick){
		my $tree = CXGN::Phylo::Tree->new($newick);
		$self->{tree} = $tree;
	}

	my $temp_dir = tempdir('bayestraits-XXXXXXX',
							DIR => $self->{tmp_base},
							CLEANUP => !DEBUG)
		or die "\nCould not produce temporary directory: $!\n";
	system "chmod a+rwx $temp_dir";

	print STDERR "\nTemporary Directory: $temp_dir" if DEBUG;
	
	$self->{commands} = [];

	$self->{method} = "ml";
	$self->{method_code} = 1;
	$self->method($args->{method}) if $args->{method};

	$self->{model} = ""; #must be specified before submit()
	$self->{model_code} = -1;
	$self->model($args->{model}) if $args->{model};

	$self->data($args->{data}) if $args->{data};
	$self->auto_mla() if $args->{auto_mla};
	$self->all_nodes() if $args->{all_nodes};

	$self->temp_dir($temp_dir);
	return $self;
}	

sub add_command {
	my $self = shift;
	push(@{$self->{commands}}, @_);
}

sub method {
	my $self = shift;
	my $method = shift;
	die "Only recognized methods are 'ml' and 'mcmc'" unless $method =~ /(ml)|(mcmc)/i;

	die "Sorry, MCMC support not yet added" if $method =~ /mcmc/i;
	
	$method = lc($method);

	$self->{method} = $method;
	$self->{method_code} = 1 if $method eq "ml";
	$self->{method_code} = 2 if $method eq "mcmc";
}

sub mlattempt {
	my $self = shift;
	my $attempts = shift;
	return unless $attempts =~ /\d+/ && $attempts > 0;
	$self->{mlattempt} = $attempts;
}

=head2 model

 Args: Model type, which sets the model code
       Accepts: multistate  
	            discrete                #traits are independent
                discrete_depend
                continuous              #non-directional random walk (Model A)
                continuous_directional  #(Model B)
                continuous_regression
       
	   Anything else results in death  

=cut

sub model {
	my $self = shift;
	my $model = shift;
	my %codes = (
		multistate => 1,
		discrete => 2,
		discrete_depend => 3,
		continuous => 4,
		continuous_directional => 5,
		continuous_regression => 6 
		);

	my $errmsg = "Model type '$model' not recognized\n";
	$errmsg .= "Accepted model types:\n";
	while(my ($m, $c) = each %codes) { $errmsg .= "\t$m\n"; }

	unless($codes{$model}) { die $errmsg };

	$self->{model} = $model;
	$self->{model_code} = $codes{$model};
}

sub auto_mla {
	my $self = shift;
	$self->{auto_mla} = 1;
}

sub all_nodes {
	my $self = shift;
	$self->{all_nodes} = 1;
}

sub write_runfile {
	my $self = shift;
	my $run_name = shift;
	$run_name ||= $self->temp_dir . "/run";
	open(RUN, ">$run_name") or die "Can't open run file for writing:$!\n";
	my $command_string = "";
	die "Model must be specified\n" unless $self->{model_code} > 0;
	$command_string .= $self->{model_code} . "\n";
	$command_string .= $self->{method_code} . "\n";
	if ($self->{mlattempt}) {
		$command_string .= "mlt " . $self->{mlattempt} . "\n";
	}
	foreach(@{$self->{commands}}){
		$command_string .= "$_\n";
	}
	$command_string .= "run\n";
	print RUN $command_string or die $!;
	close(RUN);	
}

sub write_traitfile {
	my $self = shift;
	my $data = $self->{data};
	die "Can't write traitfile: no data!\n" unless (ref($data) && keys %$data);
	my $filename = shift;
	$filename ||= $self->temp_dir() . "/trait_file";
	
	open(WF, ">$filename") or die $!;
	
	while(my($id, $ref) = each %$data) {
		my @values;		
		if(ref($ref) eq "ARRAY"){
			@values = @$ref;
		}
		elsif(ref($ref) eq "HASH"){
			my @keys = sort keys %$ref;
			@values = map { $ref->{$_} } @keys;

			#Build Trait# to Key Name convertor
			for(my $i = 0; $i < @keys; $i++){
				my $num = $i + 1;
				$self->{traitnum2name}->{$num} = $keys[$i];
			}	
		}	
		print WF $id . " " . join(" ", @values) . "\n";
	}
	close WF;
}

sub data {
	my $self = shift;
	my $data = shift;
	return $self->{data} unless defined $data;

	#Perform all kinds of tests to make sure data is in good form:
	die "Provided data must be in hash-ref form\n" unless (ref($data) eq "HASH");
	my $all_arrayref = 1;
	my $all_hashref = 1;

	while (my ($k, $v) = each %$data) {
		$all_arrayref = 0 unless (ref($v) eq "ARRAY");
		$all_hashref = 0 unless (ref($v) eq "HASH");
	}
	unless($all_arrayref || $all_hashref){
		die "Data values must all be hash references or all be array references\n";	
	}
	my $ref_found = 0;
	while(my ($k, $v) = each %$data) {
		if($all_arrayref){
			foreach(@$v){	
				$ref_found = 1 if ref($_);
			}
		}
		elsif($all_hashref){
			while(my ($key, $value) = each %$v){
				$ref_found = 1 if ref($value);
			}
		}
	}
	die "Values in hashref or arrayref must be composed of all non-references (scalar values).  You may have nested one or more levels too far\n" if $ref_found;

	#OK, data is good!
	$self->{data_type} = "array" if $all_arrayref;
	$self->{data_type} = "hash" if $all_hashref;
	$self->{data} = $data;
}

sub results {
	my $self = shift;
	my $result_hash = shift;
	return $self->{results} unless $result_hash;
	$self->{results} = $result_hash;
}

sub root_result {
	my $self = shift;
	my $rr = shift;
	return $self->{root_result} unless $rr;
	$self->{root_result} = $rr;
}

sub to_file {
	my $self = shift;
	my $file = shift;

	my $fh = undef;
	if(ref($file) eq "GLOB"){
		$fh = $file;
	}
	else {
		open(WF, ">$file");
		$fh = \*WF;
	}

	my $results = $self->results();

	my $first = $results->{1};
	my @keys = keys %$first;
	my @values = ();
	my @var = ();
	my @covar = ();

	#We are only interested in a selection from the result hash, since
	#many duplicate values (with different key names) will exist
	if($self->{data_type} = "hash"){
		@values = values %{$self->{traitnum2name}};
		@var = map { $_ . "_var" } @values;
		my @stack = @values;
		while(my $value = pop @stack){
			push(@covar, $value . "_$_" . "_covar") foreach @stack;
		}
	}
	else {
		@values = grep { /trait\d+/ } @keys;
		@var = map { $_ . "_var" } @values;
		my @stack = @values;
		while(my $value = pop @stack){
			foreach(@stack){
				my ($num) = /trait(\d+)/;
				push(@covar, $value . "_$num" . "_covar");
			}	
		}
	}

	my @evars = grep { defined $results->{$_} } qw/Kappa Delta Lambda/;
	my @result_names = ("Node", @values, @var, @covar, @evars);
	my @nodes = sort {$a <=> $b} keys %$results;
	
	print $fh (join ("\t", @result_names) . "\n");
	foreach my $n (@nodes){
		my @vals = ();
		my @names = @result_names;
		shift @names;  # No "Node" key!
		foreach(@names){
			push @vals, $results->{$n}->{$_};
		}
		print $fh ("$n\t" . join("\t", @vals) . "\n");
	}	
	close $fh;
}

sub submit {
	my $self = shift;
	my $tree = $self->{tree};
	if($self->{all_nodes}){
		my @nodes = $tree->get_all_nodes();
		foreach(@nodes){
			my @c = $_->get_children();
			next unless (scalar(@c) > 1);
			$self->mlattempt(10);
			my $key = $_->get_node_key();
			if($self->auto_mla){
				my $count = (scalar $_->get_descendents) - 1;
				$self->mlattempt(_calc_mla($count));
			}
			$self->submit_for_treenode($key);
		}
	}
	else {
		$self->submit_for_treenode(1);	
	}
}

sub _calc_mla {
	my $c = shift;	
	return 10_000 if $c==2;
	return 5_000 if $c==3;
	return 2_500 if $c==4;
	return 1_250 if $c==5;
	return 675 if $c==6;
	return 400 if $c==7;
	return 200 if $c==8;
	return 100 if $c==9;
	return 50 if $c==10;
	return 25 if $c==11;
	return 15 if $c==12;
	return 10;
}

sub submit_for_treenode {
	my $self = shift;
	my $node_key = shift;
	
	my $node = $self->{tree}->get_node($node_key);
	if($self->run_locally){
		my $wd = `pwd`;
		chomp $wd;
		my $td = $self->temp_dir();
		unless($td =~ /^\//){
			$self->temp_dir("$wd/$td");
		}
	}
	my $treefile = $self->temp_dir() . "/treefile_$node_key";
	$node->write_nex($treefile);
	
	my $traitfile = $self->temp_dir() . "/traitfile_$node_key";	
	$self->write_traitfile($traitfile);
	
	my $runfile = $self->temp_dir() . "/run_$node_key";
	$self->write_runfile($runfile);

	my $job = undef;
	if($self->run_locally()){
		$job = CXGN::Tools::Run->run(
			"BayesTraits $treefile $traitfile < $runfile" ,
			{
				out_file => "$traitfile.out",
				err_file => "$traitfile.err",
				working_dir => $self->{temp_dir},
				temp_base => $self->{temp_dir}
			});
	}
	else {
		$job = CXGN::Tools::Run->run_cluster( 
			"/data/prod/bin/BayesTraits $treefile $traitfile < $runfile",
			{
				working_dir => $self->{temp_dir},
				temp_base => $self->{temp_dir},
				queue => 'batch@' . $self->cluster_host(),
			}
		);
	}
	$job->property("result_file", "$traitfile.log.txt");
	$job->property("result_processed", 0);
	$job->property("node", $node_key);
	$self->push_job($job);
}

sub process_result {
	my $self = shift;
	my $job = shift;
	my $output_file = $job->property("result_file");
	my $node = $job->property("node");
	open(FH, $output_file) or (print STDERR "\nCannot read result file for node $node, $output_file\n" and return);

	my $hash = {};
	while(<FH>){
		next unless /\t/;
		s/\s*$//;
		s/^\s*//;
		my @names = split /\t+/;
		my $vl = <FH>;
		$vl =~ s/\s*$//;
		$vl =~ s/^\s*//;
		my @values = split /\t+/, $vl;
		while(my $name = pop @names){
			$hash->{$name} = pop @values;
		}
		last;
	}
	close FH;

	#Post process hash names so that they can be accessed
	#by more intuitive means:
	$hash->{likelihood} = $hash->{lh} = $hash->{Lh};
	foreach(qw/ Kappa Delta Lambda /){
		my $lc = lc($_);
		$hash->{$lc} = $hash->{$_};
	}
	my @keys = keys %$hash;
	my @tnames = grep { /Alpha Trait/ } @keys;
	foreach(@tnames){
		my ($num) = /Alpha Trait (\d+)/;
		my $value = $hash->{$_};
		my $var = $hash->{"Trait $num Var"};
		$hash->{"trait$num"} = $value;
		$hash->{"trait$num" . "_var"} = $var;
		if($self->{data_type} eq "hash"){
			my $name = $self->{traitnum2name}->{$num};
			$hash->{$name} = $value;
			$hash->{$name . "_var"} = $var;
		}
	}
	my @covars = grep { /Co\-Var/ } @keys;
	foreach(@covars){
		my ($f, $s) = /Trait (\d+) (\d+) Co-Var/i;
		my $value = $hash->{$_};
		
		$hash->{"trait$f" . "_$s" . "_covar"} = $value;
		$hash->{"trait$s" . "_$f" . "_covar"} = $value;
		
		if($self->{data_type} eq "hash"){
			my ($fn, $sn) = ($self->{traitnum2name}->{$f}, $self->{traitnum2name}->{$s});
			$hash->{$fn . "_$sn" . "_covar"} = $value;
			$hash->{$sn . "_$fn" . "_covar"} = $value;
		}
	}


	$self->{results}->{$node} = $hash;
	$self->{root_result} = $hash if $node == 1;

	$job->{result_processed} = 1;
}

sub alive {
	
	#alive() works very differently here than in parent class.  
	#Result files are written as soon as the job is no longer alive,
	#since there is no need to wait before all the jobs are done to
	#start getting results
	
	my $self = shift;
	my $job_array = $self->jobs();
	my $running = 0;
	foreach my $job (@$job_array){
		#The job will die for a zoem-related reason, which doesn't matter,
		#we don't want the whole process to die just because of that
		my $alive = 0;
		eval {
			$alive = $job->alive();
		};
		$alive = 0 if $@;
		$running = 1 if $alive;
		if(!$alive){
			$self->process_result($job) unless $job->property("result_processed");
		}
	}
	return $running;
}

sub spin {
	my $self = shift;
	my $wait_time = shift;
	$wait_time ||= $self->job_wait();
	print STDERR "\nAll jobs submitted, now we wait...";
	while($self->alive()){
		sleep($wait_time);
		print STDERR "." if DEBUG;
	}
	my $outfile = $self->outfile();
	print STDERR "\n";
	if($outfile){
		print STDERR "\nAutomatically printing to outfile '$outfile'\n";
		$self->to_file($outfile);
	}
}


1;
