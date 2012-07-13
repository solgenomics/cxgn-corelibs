package Orthologger;
use strict;
use List::Util qw ( min max sum );

# use Devel::Cycle; # not gonna use this anymore?

my $default_arg_href = {
			'reroot_method' => 'none',
			'gene_tree' => undef,
			'gene_tree_newick' => undef,
			'species_tree' => undef, # tree object.
			'species_name_map' => undef,
			'query_species' => undef,
			'query_id_regex' => undef
		       };

sub new {
  my $class = shift;
  my $arg_href = shift;

  my $self = bless {}, $class;

  # initialize parameters to defaults.
  foreach (keys %$default_arg_href) {
    $self->{$_} = $default_arg_href->{$_};
  }
  # reset any parameters specified in argument hash ref.
  foreach (keys %$arg_href) {
#      print STDERR "param => value: $_ => ", $arg_href->{$_}, "\n";
    $self->{$_} = $arg_href->{$_};
  }
  $self->set_species_name_map(CXGN::Phylo::Species_name_map->new()) unless(defined $self->get_species_name_map());

  # get the gene tree
  die "Must supply either a gene tree object, or gene tree newick string.\n" 
    if (!defined $self->get_gene_tree() and !defined $self->get_gene_tree_newick());
  my $do_set_error = 0;
  my $gene_tree;
  if (defined $self->get_gene_tree()) {
  #  print "gene tree branch \n";
    $gene_tree = $self->get_gene_tree();
  } else {
    my $gene_tree_newick = $self->get_gene_tree_newick();
    $gene_tree = CXGN::Phylo::Parse_newick->new($gene_tree_newick, $do_set_error)->parse();
    $gene_tree->show_newick_attribute('species'); 
    if (!$gene_tree) {
      die "Gene tree. Parser_newick->parse() failed to return a tree object.\n Newick string: ". $gene_tree_newick . "\n";
    }
    $self->set_gene_tree($gene_tree);
  }
  my $species_tree = $self->get_species_tree();
  # tweak the gene tree object:
  $gene_tree->impose_branch_length_minimum();
  $gene_tree->get_root()->recursive_implicit_names();
 $gene_tree->get_root()->recursive_implicit_species();
  # if species is empty, (because no [species=x] in newick), get it from the name...
  $gene_tree->set_missing_species_from_names();

  $gene_tree->set_show_standard_species(1);
  $gene_tree->update_label_names();
  $gene_tree->set_species_standardizer($self->get_species_name_map());

  # now tweak species tree:
  $species_tree->set_missing_species_from_names(); # get species from name if species undef
  $species_tree->impose_branch_length_minimum();
  $species_tree->collapse_tree();
  $species_tree->get_root()->recursive_implicit_names();
  $species_tree->get_root()->recursive_implicit_species();

  my $spec_bit_hash = $self->get_species_bithash();

 $gene_tree->get_root()->recursive_set_implicit_species_bits($spec_bit_hash);
  $species_tree->get_root()->recursive_set_implicit_species_bits($spec_bit_hash);


  $species_tree->set_show_standard_species(1);
  $species_tree->update_label_names();
  $species_tree->set_species_standardizer($self->get_species_name_map());
  
#print STDERR "in Orthogger->new. About to call reroot. \n";

  $self->reroot();

  $gene_tree->get_root()->recursive_set_leaf_species_count();
  $gene_tree->get_root()->recursive_set_leaf_count();
  $gene_tree->get_root()->recursive_implicit_species();
  $gene_tree->get_root()->recursive_set_implicit_species_bits($spec_bit_hash);

  my $root_spec = $gene_tree->get_root()->speciation_at_this_node($species_tree);
  if ($root_spec < 0) {
    # if trifurcation at root, reroot to one of the neighboring branches
    # if this will yield a speciation at root...
    my $cn = ($gene_tree->get_root()->get_children())[$root_spec + 3];
    my $bl = $cn->get_branch_length();
    $gene_tree->reset_root_to_point_on_branch($cn, 0.5*$bl);

    $gene_tree->get_root()->recursive_implicit_species();
    $gene_tree->get_root()->recursive_set_implicit_species_bits($spec_bit_hash);
  }
  $gene_tree->get_root()->recursive_implicit_names();
  $gene_tree->get_root()->recursive_set_speciation($species_tree);
  #	$gene_tree->show_newick_attribute("species"); # should work now
  $gene_tree->show_newick_attribute("speciation");
  return $self;
}				# end of constructor

sub reroot{
  my $self = shift;
  my $gene_tree = $self->get_gene_tree();
  my $species_tree = $self->get_species_tree();
  my $reroot_method = $self->get_reroot_method();
 # print "top of reroot. reroot method: $reroot_method ; \n", $gene_tree->generate_newick(), "\n";
  my @new_root_point = (undef, undef);
  if (defined $reroot_method and $reroot_method ne 'none') {
    # reset root
    if ($reroot_method eq "mindl") { # min duplicate & loss
   #   $gene_tree->set_branch_lengths_equal(0.0001);

      @new_root_point = $gene_tree->find_mindl_node($species_tree);
      die "find_mindl_node failed\n" if(!defined $new_root_point[0]);
    } elsif ($reroot_method eq "minvar") { # min variance
      @new_root_point = $gene_tree->min_leaf_dist_variance_point();
    } elsif ($reroot_method eq "maxmin") { # max min; max over possible pts in tree (along branches) of min over nodes of pt-node distance. 
      @new_root_point = $gene_tree->find_point_furthest_from_leaves();
    } elsif ($reroot_method eq "minmax" or $reroot_method eq "midpoint") { # min max, aka midpoint (midpoint of longest leaf-leaf path)
      @new_root_point = $gene_tree->find_point_closest_to_furthest_leaf();
    }
    $gene_tree->reset_root_to_point_on_branch(@new_root_point);
    $gene_tree->get_root()->recursive_implicit_names(); # needed after rerooting?
  }
  return $gene_tree;
}

sub ortholog_result_string{
  my $self = shift;
  my $gene_tree = $self->get_gene_tree();
  my $ortholog_str = '';
  my @leaves = $gene_tree->get_leaves();
  my $query_species = $self->get_query_species();
  my $standard_query_species = undef;
  if (defined $query_species) {
    $standard_query_species =  $self->get_species_name_map()->get_standard_name($query_species); #e.g. "Ipomoea_batatas";
  }
  my $query_id_regex = $self->get_query_id_regex();

  my $non_species_tree_leaf_node_names = $self->get_gene_tree()->non_speciestree_leafnode_names();
  foreach my $leaf (@leaves) {
    my $species_ok = (! defined $query_species or ( $leaf->get_standard_species() =~ /$standard_query_species/) );
    my $name_ok = (! defined $query_id_regex or $leaf->get_name() =~ /$query_id_regex/);
    next if(!$species_ok or !$name_ok);
    my $leafname = $leaf->get_name();
    next if( exists $non_species_tree_leaf_node_names->{$leafname} );
    $ortholog_str .= "orthologs of " . $leafname . ":  ";

  my @cand_orthologs = $leaf->collect_orthologs_of_leaf();

            # keep only leaves whose species appear in species tree
            my @orthologs = ();

            #  my $non_species_tree_leaf_node_names =
            #  $browser->get_tree()->non_speciestree_leafnode_names();
            if ( scalar keys %$non_species_tree_leaf_node_names > 0 ) {
                foreach (@cand_orthologs) {
                    if ( exists $non_species_tree_leaf_node_names->{$_} ) {
                        #  unknown species, can't claim orthology
                    } else {
                        push @orthologs, $_;
                    }
                }
            } else {
                @orthologs = @cand_orthologs;
            }

 #   my @orthologs = $leaf->collect_orthologs_of_leaf(); # list of leaf names
    $ortholog_str .= join(" ", @orthologs) . "\n";
  }
  my $non_speciestree_names_str = "Leaves not in species tree: " . join(" ", keys %{$non_species_tree_leaf_node_names}) . "\n";
  $ortholog_str .= $non_speciestree_names_str;
  return $ortholog_str;
} # end of ortholog_result_string

sub get_species_bithash{ #  get a hash giving a bit pattern for each species which is in both $gene_tree and $spec_tree
  my $self = shift;
  return $self->get_gene_tree()->get_species_bithash($self->get_species_tree());
}				# end get_species_bithash

sub get_expanded_subtrees{
  my $self = shift;
  my $node = shift;
  my $treename = shift || 'Default_tree_name';
  if (!defined $node->get_leaf_species_count()) {
    $node->recursive_set_leaf_species_count();
  }
  my $expansion_report_string = '';
  my $leaf_species_count = $node->get_attribute("leaf_species_count");
  my $leaf_count = $node->get_attribute("leaf_count");

  if (($leaf_species_count==1) && ($leaf_count>1)) {
    my $sp = $node->recursive_get_a_leaf()->get_standard_species();
    $expansion_report_string = "tree $treename has expansion of $leaf_count for species $sp\n";
    return $expansion_report_string;
  }
  foreach my $c ($node->get_children()) {
    $expansion_report_string .= $self->get_expanded_subtrees($c, $treename);
  }
  return $expansion_report_string;
}

sub decircularize{ 
# call before Orthologger obj goes out of scope 
# so it can be garbage collected, to avoid memory leak.
my $self = shift;
$self->set_species_tree(undef);
$self->get_gene_tree()->decircularize();
$self->set_gene_tree(undef);
}


#accessors:

sub get_gene_tree_newick{
  my $self = shift;
  return $self->{gene_tree_newick};
}
sub set_gene_tree_newick{
  my $self = shift;
  $self->{gene_tree_newick} = shift;
}

sub get_gene_tree{
  my $self = shift;
  return $self->{gene_tree};
}
sub set_gene_tree{
  my $self = shift;
  $self->{gene_tree} = shift;
}

sub get_species_tree{
  my $self = shift;
  return $self->{species_tree};
}
sub set_species_tree{
  my $self = shift;
  $self->{species_tree} = shift;
}

sub get_reroot_method{
  my $self = shift;
  return $self->{reroot_method};
}
sub set_reroot_method{
  my $self = shift;
  $self->{reroot_method} = shift;
}

sub get_species_name_map{
  my $self = shift;
  return $self->{species_name_map};
}
sub set_species_name_map{
  my $self = shift;
  $self->{species_name_map} = shift;
}

sub get_query_species{
  my $self = shift;
  return $self->{query_species};
}
sub set_query_species{
  my $self = shift;
  $self->{query_species} = shift;
}

sub get_query_id_regex{
  my $self = shift;
  return $self->{query_id_regex};
}
sub set_query_id_regex{
  my $self = shift;
  $self->{query_id_regex} = shift;
}

1;
