
package CXGN::Phylo::Ortholog_group_factory;

sub new { 
    my $class = shift;
    my $tree = shift;

    my $args = {};
    my $self = bless $args, $class;
    
    my @ortholog_groups = $self->collect_orthologs($tree->get_root());

    return $self;
}

sub collect_orthologs { 
    my $self = shift;
    my $node = shift;
    my $ortho_groups_ref = shift;
    my $ortho_tree_ref = shift;

    # test if we have a subtree that contains orthologs... that's the case
    # when the subtree_species_count is equal to the subtree_node_count.
    #
    if ($node->get_subtree_species_count() == $node->get_subtree_node_count()) { 
	#print STDERR "Found ortholog group starting at node ". $node->get_name()."\n";
	
	# collect all the leaves in that subtree
	#
	my @orthologs = $node->recursive_leaf_list();
	push @$ortho_groups_ref, \@orthologs;
	#print STDERR "Done collecting ".scalar(@orthologs)." subnodes.\n";
	
	# now we also want the actual subtree so that we can compare it to the 
	# species tree. First, copy the subtree.
	#print STDERR "Getting the subtree...\n";
	my $new_tree = CXGN::Phylo::Tree->new();
	my $new_root = $node->recursive_copy(undef, $new_tree);

	$new_tree->set_root($new_root);
	
	push @$ortho_tree_ref, $new_tree;

	return ($ortho_groups_ref, $ortho_tree_ref);
    }
    else { 
	foreach my $c ($node->get_children()) { 
	    #print STDERR "Testing child node ".$c->get_name()." for orthology.\n";
	    my ($children_ortho_groups_ref, $children_ortho_trees_ref) = $self->collect_orthologs($node);
	    foreach my $ref (@$children_ortho_groups_ref) { 
		#print STDERR "Adding subnodes...\n";
		push @$ortho_groups_ref, $ref;
	    }
	    foreach my $ref (@$children_ortho_trees_ref) { 
		#print STDERR "Adding subtree to ortholog tree list...\n";
		push @$ortho_tree_ref, $ref;
	    }
	}
    }
    #print STDERR  "Returning.\n";
    return ($ortho_groups_ref, $ortho_tree_ref);
}

1;
