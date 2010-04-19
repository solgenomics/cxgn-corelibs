
=head1 NAME

CXGN::Phylo::Tree - an object to handle trees

=head1 USAGE

 my $tree = CXGN::Phylo::Tree->new();
 my $root = $tree->get_root();
 my $node = $root->add_child();
 $node->set_name("I'm a child node");
 $node->set_link("http://solgenomics.net/");
 my $child_node = $node->add_child();
 $child_node->set_name("I'm a grand-child node");
 print $tree->generate_newick();

=head1 DESCRIPTION

The tree object provides metadata for tree data structures. The tree data structure itself is defined with node objjects (L<CXGN::Phylo::Node>), for which the tree object stores the root node, which gives access to the entire tree structure using appropriate node functions such as get_children(). The tree object also provides convenience functions, which usually map to node functions on the root node.

For faster access of individual nodes, the tree object keeps a hash of nodes keyed by a unique id for each node. The tree object also provides a function to obtain new unique node ids.

The tree object also provides the layout and rendering functions. The both layout and rendering are defined by L<CXGN::Phylo::Layout> and L<CXGN::Phylo::Renderer> objects, of which several versions exist that provide different tree layouts and renderings. 


=head1 AUTHORS

 Lukas Mueller (lam87@cornell.edu)
 Tom York (tly2@cornell.edu)

=cut

use strict;

use CXGN::Phylo::Node;
use CXGN::Phylo::Species_name_map;
use CXGN::Phylo::Layout;
use CXGN::Phylo::Renderer;
use CXGN::Phylo::Parser;

use CXGN::Phylo::Alignment;
use CXGN::Phylo::Ortholog_group;

package CXGN::Phylo::Tree;

=head2 function new()

  Synopsis:	my $t = CXGN::Phylo::Tree->new()
  Arguments:	none
  Returns:	an instance of a Tree object.
  Side effects:	creates the object and initializes some parameters.
  Description:	

=cut

sub new {
	my $class = shift;
	my $self = bless {}, $class;   		
	#You can feed constructor with a newick string, which will create
	#a parser object that creates a tree object *without* passing a
	#string, which would lead to an infinite loop.  Watch out!
	my $arg = shift; 
	my $newick_string = "";
	unless (ref($arg)) {
	#	print STDERR "Tree::new. [$newick_string] \n";
		$newick_string = $arg;
# print STDERR "Tree::new. [$newick_string] \n";
	} else {
		my $newick_file = '';
		if ($arg->{from_files}) {
			$newick_file = $arg->{from_files}->{newick};
			die "Need a newick file if 'from_files' is used\n" unless -f $newick_file;
			
			$self = _tree_from_file($newick_file);
			my $alignment_file = $arg->{from_files}->{alignment};
			if ($alignment_file) {
				die "Alignment file: $alignment_file not found" unless -f $alignment_file;
				my $alignment = CXGN::Phylo::Alignment->new( from_file=>$alignment_file);
				$self->set_alignment($alignment);
				$self->standard_alignment_leaf_association();
			}
			return $self;
		} elsif ($arg->{from_file}) {
			$newick_file = $arg->{from_file};
			$self = _tree_from_file($newick_file);
			return $self;
		}
	}
	if ($newick_string) {
		$newick_string =~ s/\s//g;
		$newick_string =~ s/\n|\r//sg;	
		if ($newick_string =~ /^\(.*\)|;$/) { # start with (, end with ) or ;
		#	print STDERR "in Tree::new, about to parse the newick_string \n";
			my $parser = CXGN::Phylo::Parse_newick->new($newick_string);
			my $self = $parser->parse();
			return $self;
		} elsif ($newick_string) {
			print STDERR "String passed not recognized as newick\n";
		}
	}

	##############################################################
	#$self is a new tree, not predefined by newick; instead it will be
	#constructed by methods on this object and Phylo::Node's

	#print STDERR "constructing Tree not predefined by a newick\n";

	$self->set_unique_node_key(0);
	
	# initialize the root node
	#
	my $root = CXGN::Phylo::Node->new();
	$root->set_name(".");
	$root->set_tree($self);
	$root->set_node_key($self->get_unique_node_key());
	$self->add_node_hash($root, $root->get_node_key());
	$self->set_root($root);

	# initialize some imaging parameters
	#
	$self->set_show_labels(1);
	$self->set_hilite_color(255, 0 ,0);
	$self->set_line_color(100, 100, 100);
	$self->set_bgcolor(0, 0, 0);
	$self->set_show_species_in_label(0);
	$self->set_show_standard_species(0);
	$self->set_species_standardizer(CXGN::Phylo::Species_name_map->new()); 

	#Attribute names to show in newick extended format
	$self->{newick_shown_attributes} = {};
	$self->{shown_branch_length_transformation} = "branch_length"; # other possibilities: "proportion_different", equal
	$self->{min_shown_branch_length} = 0.001; # when showing branches graphically, this is added to the displayed length
	$self->{min_branch_length} = 0.0001;
	# initialize a default layout and renderer
	#
	$self->set_layout( CXGN::Phylo::Layout->new($self) );
	$self->set_renderer( CXGN::Phylo::PNG_tree_renderer->new($self) );

	return $self;
}

# copy some of the tree's fields. Other fields will just have default values as set in constructor
# e.g. layout and renderer aren't copied because there is no copy method for these objects
sub copy_tree_fields{
	my $self = shift;							# source
	my $new = shift;							# copy

	$new->set_name($self->get_name());

	# initialize some imaging parameters
	#
	$new->set_show_labels($self->get_show_labels());
	$new->set_hilite_color($self->get_hilite_color());
	$new->set_line_color($self->get_line_color());
	$new->set_bgcolor($self->set_bgcolor());

	$new->set_species_standardizer($self->get_species_standardizer()->copy())	if (defined $self->get_species_standardizer()) ;	
	$new->set_show_species_in_label($self->get_show_species_in_label());
	$new->set_show_standard_species($self->get_show_standard_species());

	#Attribute names to show in newick extended format
#	$new->{newick_shown_attributes} = $self->{newick_shown_attributes};
	#	@{$new->{newick_shown_attributes}} = @{$self->{newick_shown_attributes}};
	%{$new->{newick_shown_attributes}} = %{$self->{newick_shown_attributes}};
	
}

=head2 function copy()

  Synopsis:	my $t_copy = $a_tree->copy()
  Arguments:	none
  Returns: A copy of $a_tree
  Side effects:	creates the object, and makes it be a copy.
  Description:	 

=cut

sub copy {
	my $self = shift;
	my $new = $self->get_root()->copy_subtree();
	$new->update_label_names();
	return $new;
}


sub _tree_from_file {
	my $file = shift;
	my $tree = _tree_from_newick(_newick_from_file($file));
	$tree->standard_layout();
	return $tree;
}

sub _tree_from_newick {
	my $newick_string = shift;	
	$newick_string =~ s/\s//g;
	$newick_string =~ s/\n|\r//g;	
	if($newick_string =~ /^\(.*\)|;$/){
		my $parser = CXGN::Phylo::Parse_newick->new($newick_string);
		my $tree = $parser->parse();
		return $tree;
	}
	elsif($newick_string) {
		print STDERR "String passed not recognized as newick\n";
		return undef;
	}
}

sub _newick_from_file {
	my $file = shift;
	open(FH, $file) or die "Can't open file: $file\n";
	my $newick = "";
	$newick .= $_ while (<FH>);
	close FH;
	$newick =~ s/\n//sg;
	$newick =~ s/\r//sg;
	$newick =~ s/\s//g;
	return $newick;
}

sub get_alignment {
	my $self = shift;
	return $self->{alignment};
}

sub set_alignment {
	my $self = shift;
	$self->{alignment} = shift;
	unless(@{$self->{alignment}->{members}}){
		warn "The alignment set to the tree has no members.  You must construct the alignment before setting it here";
		return -1;
	}
}

=head2 function standard_alignment_leaf_association()

 Associate alignment members to leaf nodes based
 on id/name equality

=cut

sub standard_alignment_leaf_association {
	my $self = shift;
	my $alignment = $self->get_alignment();
	return unless $alignment;
	my %id2mem = ();
	foreach my $m ($alignment->get_members()) {
		$id2mem{$m->get_id()} = $m;
	}
	foreach my $l ($self->get_leaves()) {
		my $m = $id2mem{$l->get_name()};
		next unless $m;		
		$l->set_alignment_member($m);
	}
}

=head2 function get_root()

  Synopsis:	my $node = $t->get_root();
  Arguments:	none
  Returns:	a Node object, which is the root of the tree.
  Side effects:	
  Description:	
  See also:     $node->is_root()

=cut

sub get_root { 
    my $self=shift;
    return $self->{root};
}

=head2 function set_root()

  Synopsis:	$t->set_root($node);
  Arguments:	a Node object
  Returns:	nothing
  Side effects:	the node $node will be defined as the root of the tree.
                Note that $node->is_root() must evaluate to true, 
                set_root() will therefore set the parent of the root 
                to undef.
  See also:     prune_to_subtree() -  takes a node as a parameter and 
                will create a sub-branch of the tree. It throws away all 
                other nodes that are not part of the sub-branch.
                reset_root() - resets the root to the specified node and 
                inverts the parent child relationships from the 
                specified node upwards to the root.

=cut

sub set_root {
    my $self=shift;
    my $new_root=shift;
    $new_root->set_parent(undef); #is_root must be true
    $new_root->set_branch_length(undef);
    $self->{root}=$new_root;
}

=head2 function delete_node() and del_node()

  Synopsis:	$tree->delete_node($node->get_node_key()); 
                $tree->del_node($node);
  Arguments:	delete_node: a unique node key, del_node: a node object.
  Returns:	nothing if operation is successful, 1 if operation 
                not succesful (because it was attempted to delete 
                the root node).
  Side effects:	Adds the branch length to each of its children, 
                Recalculates the leaf list and node hash.
                Note: The root node cannot be deleted.
  Description:	

=cut

sub delete_node {
	my $self = shift;
	my $node_key = shift;

	# get the node object from the key
	#
	my $node=$self->get_node($node_key);
	return $self->del_node($node);
}

# delete node by passing node object as argument
# rather than node key as with delete_node
sub del_node{
	my $self = shift;
	my $node = shift;
	if (!$node) { 
		warn 'The node you want to delete does not exist!'; return;
	}
	my $retval = $node->delete_self();
	$self->recalculate_tree_data();
	return $retval;
}

=head2 function recalculate_tree_data()

  Synopsis:	
  Arguments:	none
  Returns:	nothing
  Side effects:	recalculates the leaf list, the node hash, and all the
                subtree distances. It does not affect the node keys.
  Description:	

=cut

sub recalculate_tree_data { 
    my $self = shift;
    $self->calculate_leaf_list();
    $self->clear_node_hash();
    $self->regenerate_node_hash($self->get_root());
    $self->get_root()->calculate_distances_from_root();
    $self->get_root()->recursive_clear_properties();
}

=head2 function prune_to_subtree()

  Synopsis:	 $a_tree->prune_to_subtree($node);
  Arguments:	 a node object, the root of the subtree to be kept.
  Returns:	
  Side effects:	 Prunes the tree.
  Description:	 Prune the tree so that only $node and its subtree 
                 is left, with $node as the new root.
                 (sub_branch is synonymous)

=cut

sub prune_to_subtree { 
    my $self = shift;
    my $new_root_node = shift;

    $self->set_root($new_root_node);
    $self->recalculate_tree_data();
}

#=head2 function sub_branch()

#  Synopsis:	 deprecated, synonym for prune_to_subtree

#=cut

#sub sub_branch { 
#	if (0) {
#    my $self = shift;
#    my $new_root_node = shift;

#    $self->set_root($new_root_node);
#    $self->recalculate_tree_data();
#	} else {
#		prune_to_subtree(@_);
#	}
#}


=head2 function reset_root()

  Synopsis:	$tree->reset_root($node);
  Arguments:	a node object that will be the new root node
  Returns:	nothing
  Side effects:	recalculates the tree parameters using the new 
                root node
  Description:	reverses all the parent-child relationships 
                between the node $node and the old root node, 
                then sets the tree root node to $node.
  Authors:      Lukas Mueller, Tom York.

=cut

sub reset_root {
	my $self = shift;							# tree object
	my $new_root_node = shift;		# node object	
	
	if (0) {											#either of these branches should work.
		my @parents = $new_root_node->get_all_parents(); # parent, grandparent, etc. up to & including root
		$new_root_node->set_parent(undef); # because it is to be the root
		my $pc_blen = $new_root_node->get_branch_length(); # branch length between $pc and $cp
		my $cp=$new_root_node;
		foreach my $pc (@parents) {
			my $former_p_blen = $pc->get_branch_length();
			$pc->remove_child($cp);		# removes $cp from $pc's child list
			$cp->add_child_node($pc); # adds $pc as child of $cp, and set $pc's parent to $cp
			$pc->set_branch_length($pc_blen);		
			$cp = $pc;
			$pc_blen = $former_p_blen;
		}
	} else {
		my @parents_root_down = reverse $new_root_node->get_all_parents();
		push @parents_root_down, $new_root_node; # need to include the new root in the array
		my $pc = shift @parents_root_down; # pc means goes from being parent to being child

		for (my $cp = shift @parents_root_down; defined $cp; $cp = shift @parents_root_down) {
			my $blen = $cp->get_branch_length();
			$pc->remove_child($cp);		# remove $cp from children list of $pc	
			$cp->set_parent(undef); 
			$cp->add_child_node($pc);	# now $cp is parent, $pc the child
			$pc->set_branch_length($blen);				
			$pc = $cp;
			# at this point we still have a consistent tree, but with the root moved another step along the
			# path from original root to new root.
		}
	}
	$self->set_root($new_root_node);
	$new_root_node->set_branch_length(0);
	$self->recalculate_tree_data();
}

=head2 function get_leaf_count()

  Synopsis:	$tree->get_leaf_count()
  Arguments:	none
  Returns:	the number of leaves in the tree
  Side effects:	
  Description:	

=cut

sub get_leaf_count { 
    my $self = shift;
#    $self->get_root()->count_leaves();
	return scalar $self->get_leaf_list();
}

=head2 function get_unhidden_leaf_count()

 Get the number of visible leaves in the tree

=cut

sub get_unhidden_leaf_count {
	my $self = shift;
	return scalar grep { !$_->is_hidden } $self->get_leaf_list;
}

=head2 function set_unique_node_key()

  Synopsis:	$tree->set_unique_node_key(345);
  Arguments:	an integer value to set the unique node key 
                property to.
  Returns:	nothing
  Side effects:	this value will then be used by get_unique_node_key().
                The getter function increases the unique key by one
                every time it is called.
  Description:	
  Note:         this function is used internally and it should not be
                necessary to ever use it.

=cut

sub set_unique_node_key { 
    my $self = shift; 
    $self->{unique_node_key}=shift;
}

=head2 function get_unique_node_key()

  Synopsis:	$node->set_node_key(
                  $node->get_tree()->get_unique_node_key() );
  Arguments:	none
  Returns:	a unique node key
  Side effects:	
  Description:	
  Note:         it should not be necessary to call this method, because 
                new nodes should always be added using the 
                $node->add_child() function, which assures that the 
                node_key property is filled in correctly.

=cut

sub get_unique_node_key { 
	my $self = shift;
	$self->{unique_node_key}++;		# increment the unique node key
	while (exists $self->{node_hash}->{$self->{unique_node_key}}) { # if key already in node_hash, increment again...
		$self->{unique_node_key}++; 
	}
	return $self->{unique_node_key};
}

=head2 function clear_node_hash()

  Synopsis:	$t -> clear_node_hash()
  Arguments:	none
  Returns:	clears the node hash
  Side effects:	
  Description:	

=cut

sub clear_node_hash { 
    my $self = shift;
    %{$self->{node_hash}}=();
}

=head2 function regenerate_node_hash()

  Synopsis:	$tree->regenerate_node_hash()
  Arguments:	a node, most conveniently the root node.
  Returns:	nothing
  Side effects:	regenerates the node hash from the current root.
  Description:	it uses the predefined ...? Recursive. Adds node 
                to hash and then calls itself on each child

=cut

sub regenerate_node_hash { 
    my $self = shift;
    my $node = shift;
	$node ||= $self->get_root();
#print("in regenerate_node_hash. \n");
#$node->print_node();
#print("node key: ", $node->get_node_key());
    $self->add_node_hash($node, $node->get_node_key());
    foreach my $c ($node->get_children()) { 
		$self->regenerate_node_hash($c);
    }
	$self->set_unique_node_key( scalar $self->get_all_nodes() );
}

=head2 function add_node_hash()

  Synopsis:	$tree->add_node_hash($node, $unique_key);
  Arguments:	an instance of a Node object; a unique node key.
  Returns:	nothing
  Side effects:	the $node is added to the node hash.
                the node hash uses the node\'s node_key property
                as a hash key, and the node object itself as a
                hash value. Note that it should not be necessary
                to call this function. All new nodes should be 
                added using the add_child() method which automatically
                inserts the new node in the node_hash. 
  Description:	

=cut

sub add_node_hash { 
    my $self = shift;
    my $node = shift;
    my $unique_key = shift;

    ${$self->{node_hash}}{$unique_key}=$node;
}

=head2 function get_all_nodes()

  Synopsis:	returns a list of all nodes, in no particular order.
  Arguments:	none
  Returns:	a list of nodes
  Side effects:	none
  Description:	

=cut

sub get_all_nodes { 
    my $self = shift;
    return (values %{$self->{node_hash}});

}

sub get_all_node_keys { 
    my $self = shift;
    return (keys %{$self->{node_hash}});

}

sub get_node_count { 
    my $self = shift;
    return scalar($self->get_all_nodes());
}

=head2 function get_node()

  Synopsis:	my $node->get_node($unique_node_key);
  Arguments:	a unique node key of a node
  Returns:	the $node object associated with the node key.
  Side effects:	
  Description:	this function uses the node hash and should therefore
                be fast. The node key values can be embedded in things
                like HTML imagemaps, and the corresponding nodes can 
                be quickly retrieved for further manipulation using 
                this function.

=cut

sub get_node { 
	my $self = shift;
	my $key = shift;
	return ${$self->{node_hash}}{$key};
}

sub print_node_keys{
	my $self = shift;
	my $hashref = $self->{node_hash};
	foreach my $k (keys (%$hashref)) {
		my $n = $self->get_node($k);	
		if (defined $n) {
			print("key, node: ", $k); $n->print_node();
		} else {
			print("key: ", $k, " has undefined node (returned by get_node($k) ). \n");
		}
	}
print("present value of unique_node_key: ", $self->{unique_node_key}, "\n");
}



=head2 function incorporate_nodes()
 
 Given a list of nodes, add them to this tree's membership
 by setting their 'tree' attributes and giving them new node
 keys from this tree's pool, setting the hash appropriately
 
 Arg: List of node objects
 Ret: Nothing

=cut

sub incorporate_nodes {
	my $self = shift;
	my @nodes = @_;
	foreach my $n (@nodes) {
		my $new_key = $self->get_unique_node_key();
		$n->set_tree($self);
		$n->set_node_key($new_key);
		$self->add_node_hash($n, $new_key);
	}
}

=head2 function incorporate_tree()

Given a tree, incorporate that tree's nodes into this tree.  This does not affect parent/child relationships; you have to set those yourself

=cut

sub incorporate_tree {
	my $self = shift;
	my $sub_tree = shift;
	my @nodes = $sub_tree->get_root()->get_descendents();
	$self->incorporate_nodes(@nodes);
}

=head2 function make_binary() 

Inserts joint nodes at polyphetic points so that the tree is biphetic or monophetic. The joint nodes have branch-length 0, so this should not affect analysis, but it allows the tree to conform to certain standards in external programs.

=cut

sub make_binary {
	my $self = shift;
	my $node = shift;
	$node ||= $self->get_root();
	my $new_bl = shift;
	$new_bl ||= $self->get_min_branch_length();
	$node->binarify_children($new_bl);
	foreach($node->get_children()){
		$self->make_binary($_, $new_bl);
	}
}

=head2 function traverse()

   Synopsis:	 $tree->traverse( sub{ my $node = shift; 
                                      $node->set_hidden() } );
   Arguments:	 a function to be performed on each node, taking 
                 that node as its only argument
   Returns:	 nothing
   Side effects: the function will be executed on each node object.
   Description:	 not yet implemented... UPDATE: C. Carpita attempts

=cut

sub traverse { 
	my $self = shift;
	my $function = shift;
	my $node = shift;
	die "You did not pass a subroutine reference" unless (ref($function) eq "CODE");
	$node ||= $self->get_root();

	&$function($node);

	foreach( $node->get_children() ){
		$self->traverse($function, $_);
	}
}

sub newick_shown_attributes { # just return the keys (attributes), so everything should work the same.
	my $self = shift;
	return keys %{$self->{newick_shown_attributes}};
}

sub show_newick_attribute {
	my $self = shift;
	my $attr = shift;
#	push(@{$self->{newick_shown_attributes}}, $attr);
$self->{newick_shown_attributes}->{$attr}++;
}

sub unshow_newick_attribute {
	my $self = shift;
	my $attr = shift;

	delete $self->{newick_shown_attributes}->{$attr};

#	my $size = scalar @{$self->{newick_shown_attributes}};
#	foreach my $index (0..$size-1) {
#		if ( ($self->{newick_shown_attributes})->[$index] eq $attr) {
#			delete $self->{newick_shown_attributes}->[$index];
#			last;
#		}
#	}
}

sub get_min_branch_length{
my $self = shift;
return $self->{min_branch_length};
}

sub set_min_branch_length{
my $self = shift;
$self->{min_branch_length} = shift;
}

sub get_shown_branch_length_transformation{
my $self = shift;
return $self->{shown_branch_length_transformation};
}

sub set_shown_branch_length_transformation{
my $self = shift;
$self->{shown_branch_length_transformation} = shift;
}

sub set_min_shown_branch_length{
my $self = shift;
$self->{min_shown_branch_length} = shift;
}

sub get_min_shown_branch_length{
my $self = shift;
return $self->{min_shown_branch_length};
}

sub shown_branch_length_transformation_reset{
	my $self = shift;
	$self->set_shown_branch_length_transformation(shift);
	$self->{longest_branch_length} = undef;
	$self->get_root()->calculate_distances_from_root();
}

=head2 function generate_newick()

 Args: (optional) node, defaults to root node
        (optional) $show_root - boolean, will show the root node in the newick string  
 Returns: Newick expression from the given node, or for the whole
          tree if no argument is provided

=cut

sub generate_newick {
    my $self = shift;
    my $node = shift;
    my $show_root = shift;
    
    $node ||= $self->get_root();
    return $node->recursive_generate_newick("", 1, $show_root);
    
}

=head2 function get_orthologs()

  Synopsis:	my $ortho_trees_ref = $tree->get_orthologs();
  Arguments:	none.
  Returns:	a reference to a list of trees in which the leaves are all 
                orthologs.
  Side effects:	Sets some node attributes, but deletes at end.
  Description:	This version uses the number of leaves and the number of 
                leaf species in a subtree to decide if that subtree's 
                leaves are all orthologs. (The topology is not used, 
                subroutine orthologs compares the topology to a 
                species_tree.)
  Author:       Tom York

=cut

sub get_orthologs {
	my $self=shift;
	my $root_node = $self->get_root();

	$root_node->recursive_set_leaf_count(); # set leaf_count attribute for all nodes
	$root_node->recursive_set_leaf_species_count(); # set leaf_species_count attribute for all nodes
	my $trees_ref = $root_node->collect_orthologs();

	# can delete the leaf_count and leaf_species_count attributes here
	my @node_list = $self->get_all_nodes(); 
	map($_->delete_attribute("leaf_count"), @node_list);
	map($_->delete_attribute("leaf_species_count"), @node_list);
	
	return $trees_ref;
}

#This should recursively get all the subtree leaf species counts, and then run over everything again,
# comparing to the leaf counts for each species in the whole tree, to get the leaf species counts for the 
# complement of each subtree.
sub set_all_subtree_and_complement_leaf_species_counts{
	my $self = shift;
	my $leaf_species_count_hash = $self->get_root()->recursive_set_leaf_species_count(); 
	print "in set_all_subtree... ; number of species: ", scalar keys %$leaf_species_count_hash, "\n"; readline();
	$self->get_root()->recursive_set_leaf_species_count($leaf_species_count_hash);
}

sub get_complement_ortho_group_candidates{
	my $self = shift;
	my @node_list = $self->get_root()->recursive_subtree_node_list();
	foreach my $n (@node_list) {
		my $comp_leaf_count = $self->get_root()->get_attribute("leaf_count") - $n->get_attribute("leaf_count");
		my $comp_leaf_species_count = $n->get_attribute("comp_leaf_species_count");
		if ($comp_leaf_count == $comp_leaf_species_count && $comp_leaf_count >1) {
			print "complement to subtree : ", $n->get_name(), " is a og candidate \n";
			print "with $comp_leaf_count leaves and $comp_leaf_species_count leaf species \n";
		}
	}
}


sub get_leaf_parents_list { 
    my $self = shift;
    foreach my $leaf ($self->get_leaf_list()) { 
	my $parent = $leaf->get_parent();
	${$self->{leaf_parent_hash}}{$parent->get_node_key()}=$parent;
    }
    # return the parents as a neat list
    return map (${$self->{leaf_parent_hash}}{$_}, keys(%{$self->{leaf_parent_hash}}));
}

# helper functions that deal with the leaf list. It contains a list of nodes
# that form leaves, in the order they will be rendered. The leaf list is stored
# in the Tree datastructure.
#

=head2 function get_leaf_list()

  Synopsis:	my @leaves = $tree->get_leaf_list();
  Arguments:	none
  Returns:	a list of Nodes that represent the leaves of the tree
  Side effects:	
  Description:	

=cut

sub get_leaf_list { 
    my $self=shift;
    if (!exists($self->{leaf_list}) || !@{$self->{leaf_list}}) { $self->calculate_leaf_list(); }
    return @{$self->{leaf_list}};
}

=head2 get_leaves

 Alias for get_leaf_list()

=cut

sub get_leaves {
	my $self = shift;
	return $self->get_leaf_list();
}

sub add_leaf_list { 
    my $self = shift;
    my $leaf_node = shift;
    push @{$self->{leaf_list}}, $leaf_node;
}

sub clear_leaf_list { 
    my $self = shift;
    @{$self->{leaf_list}}=();
}

sub calculate_leaf_list { 
    my $self = shift;
    $self->clear_leaf_list();
    my @leaf_list = $self->get_root()->recursive_leaf_list(); 
    foreach my $leaf (@leaf_list) { 
	$self->add_leaf_list($leaf);
    }
}



# the tree_topology_changed member variable contains the status of the 
# topology of the tree. If the tree has been changed, it should be 1, 
# otherwise it should be 0. 
#
sub get_tree_topology_changed { 
    my $self = shift;
    return $self->{tree_topology_changed};
}

sub _set_tree_topology_changed { 
    my $self = shift;
    $self->{tree_topology_changed}=shift;
}

=head2 function get_name()

  Synopsis:	my $tree_name = $tree->get_name();
  Arguments:	none
  Returns:	the name of the tree.
  Side effects:	none
  Description:	

=cut

sub get_name { 
    my $self=shift;
    return $self->{name};
}

=head2 function set_name()

  Synopsis:	$tree->set_name("A tree of the cytochrome P450 family in the Solanaceae");
  Arguments:	a string representing a name
  Returns:	nothing
  Side effects:	this name will be used somehow in the future, such as when 
                the tree is rendered as an image.
  Description:	

=cut

sub set_name { 
    my $self=shift;
    $self->{name}=shift;
}

=head2 function get_longest_root_leaf_length()

  Synopsis:	my $longest = $tree->get_longest_root_leaf_length()
  Arguments:	none
  Returns:	the longest distance from the root to any leaf [real]
  Side effects:	
  Description:	

=cut

sub get_longest_root_leaf_length { 
	my $self=shift;
	if (!$self->{longest_branch_length}) {
		$self->set_longest_root_leaf_length($self->calculate_longest_root_leaf_length());
	}
# print "in get_longest_root_leaf_length: ", $self->{longest_branch_length}, "\n";
	return $self->{longest_branch_length};
}

=head2 function set_longest_root_leaf_length()

  Synopsis:	$tree->set_longest_root_leaf_length($distance)
  Arguments:	the distance from root to the furthest leaf.
  Returns:	nothing
  Side effects:	This value is used for the scaling of the tree in the
                horizontal dimension. Normally it should be calculated
                using get_longest_root_leaf_length().
  Description:	

=cut

sub set_longest_root_leaf_length { 
	my $self=shift;
	$self->{longest_branch_length}=shift;
}

sub calculate_longest_root_leaf_length {
	my $self=shift;
	my $largest = 0;
	foreach my $leaf ($self->get_leaf_list()) { 
		my $dist = $leaf->get_dist_from_root();
		if ($dist > $largest) {
			$largest=$dist;
		}
	}
	return $largest;
}

=head2 function retrieve_longest_branch_node()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub retrieve_longest_branch_node { 
    my $self=shift;
    my $longest_branch_node = $self->get_root()->_recursive_longest_branch_node(CXGN::Phylo::Node->new());
    return $longest_branch_node;
}




=head2 APPEARANCE OF THE TREE

=head2 function get_show_labels()

  Synopsis:	my $flag = $tree->get_show_lables();
  Arguments:	none
  Returns:	a boolean if the labels are currently visible.
  Side effects:	
  Description:	

=cut

sub get_show_labels { 
    my $self=shift;
    return $self->{show_labels};
}

=head2 function set_show_labels()

  Synopsis:	$tree->set_show_lables(1);
  Arguments:	a boolean value representing the visibility
                of the labels.
  Returns:	nothing
  Side effects:	
  Description:	

=cut

sub set_show_labels { 
    my $self=shift;
    $self->{show_labels}=shift;
}


sub get_show_species_in_label{
    my $self = shift;
    return $self->{show_species_in_labels};
}

sub set_show_species_in_label{
    my $self = shift;
    $self->{show_species_in_labels} = shift;
}


=head2 accessors get_line_color(), set_line_color()

  Synopsis:	my ($r, $g, $b) = $tree->get_line_color();
  
  Property:	a list of (red, gree, blue) components of the
                color used to draw the tree lines.
  Side effects:	
  Description:	

=cut

sub get_line_color { 
    my $self=shift;
    return @{$self->{line_color}};
}

sub set_line_color { 
    my $self=shift;
    @{$self->{line_color}}=@_;
}


=head2 accessors get_bgcolor(), set_bgcolor()

  Synopsis:	$tree->set_bgcolor(255, 255, 255);
  Property:     a list of (red, green, blue) components for the 
                tree background color.
  Side effects:	
  Description:	

=cut

sub get_bgcolor { 
    my $self=shift;
    return @{$self->{bgcolor}};
}

sub set_bgcolor { 
    my $self=shift;
    @{$self->{bgcolor}}=@_;
}

=head2 accessors get_hilite_color(), set_hilite_color()

  Synopsis:	$tree->set_hilite_color(0, 255, 255);
  Property:     a list of color components for the hilite color
  Side effects:	this color is used to hilite labels of nodes that
                have the hilite propery set to a true value.
  Description:	

=cut

sub get_hilite_color { 
    my $self=shift;
    return @{$self->{hilite_color}};
}

sub set_hilite_color { 
    my $self=shift;
    @{$self->{hilite_color}}=@_;
}

=head2 function get_node_by_name()

  Synopsis:	
  Arguments:	a search term
  Returns:	a node object that has a matching node name
  Side effects:	
  Description:	get_node_by_name() calls search_node_name(), appending
                ^ and $ to the regular expression. It assumes that all
                nodes have distinct names. If several nodes have the same
                name, only the first node it finds is returned. If it
                does not find the node, it returns undef.

=cut

sub get_node_by_name { 
    my $self = shift;
    my $name = shift;
	foreach my $n ($self->get_all_nodes()){
		return $n if ($n->get_name() eq $name);
	}
	return undef;
}

#returns a list of nodes matching a certain reg expression depending on the argument
sub search_node_name { 
    my $self = shift;
    my $term = shift;
    my @nodes = ();
    foreach my $n ($self->get_all_nodes()) {
		my $node_name = $n->get_name();
		if ($node_name =~ /\Q$term\E/i) { 
		    push @nodes, $n;
		}
    }
    return @nodes;
}

#returns a list of nodes matching a certain reg expression depending on the argument
sub search_label_name { 
	my $self = shift;
	my $term = shift;
	my @nodes = ();
	foreach my $n ($self->get_all_nodes()) {
	    my $label_name = $n->get_label()->get_name();
	    if ($term =~ m/m\/(.*)\//) { # if enter m/stuff/ then treat stuff as perl regex
		my $match = $1;
		if ($match && $label_name =~ /$match/) {
		    push @nodes, $n;
		}
	    } else {
		if ($term && $label_name =~ /\Q$term\E/i) { 
		    push @nodes, $n;
		}
	    }
	}
	return @nodes;
}

=head2 function compare()

  Synopsis:	$this_tree->compare($another_tree);
  Arguments:	a tree object
  Returns:	1 if the tree is identical in topology to 
                $another_tree, 
                0 if the trees have a different topology.
  Side effects:	
  Description:	compare() works by comparing the node names and 
                the topology of the tree. Because not all nodes 
                usually have explicit names, it derives implicit 
                names for each node (it assumes the leaf nodes have 
                unique names). The implicit names are defined by an 
                array containing all the names of the subnodes. The 
                names are sorted by alphabetical order and then compared.

  Note:         This is a synonym for compare_rooted. There is also a 
                compare_unrooted routine to test whether trees
                are the same aside from being rooted in different places.

=cut

#sub compare {
#	my $self = shift;
#	my $other_tree = shift;
#my $compare_field = shift;

## print STDOUT "in compare. compare_field: $compare_field \n";

#	return $self->compare_rooted($other_tree, $compare_field);
#}

=head2 function compare_rooted

  Synopsis:	$tree1->compare_rooted($tree2);
  Arguments:	A tree object.
  Returns:	1 if $tree1 and $tree2 are topologically the same 
                when regarded as rooted trees, 0 otherwise.
  Side effects:	None.
  Description:	Works with copies of trees; collapses them, gets 
                implicit names, then recursively compares trees 
                using implicit names.
  Note:         Now synonymous with compare. Can compare subtrees 
                with Node->compare_subtrees
Author:         Tom York

=cut

sub compare_rooted{
    my $self = shift;
    my $other_tree = shift;
my $compare_field = shift;
# print STDOUT "in compare_rooted. compare_field: $compare_field \n";
    return $self->get_root()->compare_subtrees($other_tree->get_root(), $compare_field);
}

=head2 function compare_unrooted

  Synopsis:	$tree1->compare_unrooted($tree2);
  Arguments:	A tree object.
  Returns:	1 if $tree1 and $tree2 are topologically the same 
                when regarded as unrooted trees, 0 otherwise.
  Side effects:	None.
  Description:	Copies the 2 trees, finds a leaf common to both
                (if one exists) and resets roots of both trees to those 
                leaves. Then recursively compares trees using implicit 
                names in same way as compare_rooted().
  Note:         In its present form, assumes uniqueness of leaf names. 
                Otherwise, if may return 0 when it should return 1.
  Author:       Tom York.

=cut

sub compare_unrooted { 
	my $self = shift;
	my $other_tree = shift;
	my $compare_field = shift;		# to control comparison of names (default) or species ("species")
	# copy the trees into temporary trees, so that the trees can 
	# be manipulated (rerooted, collapsed) without changing the original trees.
	#
	# print STDOUT "in compare_unrooted. compare_field: $compare_feld \n";
	my $tree1 = $self->copy();
	my $tree2 = $other_tree->copy();

	# find a leaf - any leaf - of tree1 and the corresponding leaf (i.e. with the same name) of tree2

	my $leaf1 = $tree1->get_root()->recursive_get_a_leaf();
	my $corresponding_leaf = $tree2->get_node_by_name($leaf1->get_name());

	if (!$corresponding_leaf) {
		print("in compare_unrooted. leaf1 name: ", $leaf1->get_name(), ". Can't find corresponding leaf in other tree. \n"); 
		return 0;
	}

	# reset roots of trees to the two corresponding leaves:
	$tree1->reset_root($leaf1);
	$tree2->reset_root($corresponding_leaf);

	return $tree1->get_root()->compare_subtrees($tree2->get_root(), $compare_field);
}


=head2 function get_layout(), set_layout()

  Synopsis:	$tree->set_layout($layout)
  Arguments:	a CXGN::Phylo::Layout object or subclass
  Returns:	nothing
  Side effects:	the layout object will be used to lay out the 
                tree in the rendering process.
  Description:	

=cut

sub get_layout { 
    my $self=shift;
    return $self->{layout};
}

sub set_layout { 
    my $self=shift;
    $self->{layout}=shift;
}


=head2 function layout()

  Synopsis:	$tree->layout()
  Arguments:	
  Returns:	
  Side effects:	
  Description:	a convenience function that calls the layout function of the 
                trees layout object.

=cut


sub layout { 
    my $self = shift;
    $self->get_layout()->layout();
}


=head2 accessors get_renderer(), set_renderer()

  Synopsis:	$tree->set_renderer($renderer)
  Arguments:	a CXGN::Phylo::Renderer object or subclass
  Returns:	nothing
  Side effects:	the $renderer is used for rendering the tree
  Description:	

=cut

sub get_renderer { 
    my $self=shift;
    return $self->{renderer};
}

sub set_renderer { 
    my $self=shift;
    $self->{renderer}=shift;
}

=head2 function render()

  Synopsis:	$tree->render();
  Arguments:	(optional) a boolean for printing all node names, and  not only the leaf labels
  Returns:	
  Side effects:	
  Description:	a convenience function that calls the render() 
                function on the tree\'s renderer. Does not perform
                the layout of the tree. Call layout() on the tree
                object before render().

=cut

sub render   { 
    my $self = shift;
    my $print_all_labels=shift;
    $self->get_renderer()->render($print_all_labels);
}

sub standard_layout {
	my $self = shift;
	my $layout = CXGN::Phylo::Layout->new($self);
	$layout->set_top_margin(20);
	$layout->set_bottom_margin(20);
	$layout->set_image_height(400);
	$layout->set_image_width(700);
	$self->set_layout($layout);
	$self->layout();
}

=head2 function render_png()

  Synopsis:	$r->render_png($filename, $print_all_labels);
  Arguments:	a filename, (optional) a boolean for printing the labels for all nodes in the tree.
  Returns:	nothing
  Side effects:	creates (or overwrites) file $filename
                which contains the png graphics representing 
                the tree.
  Description:	

=cut

sub render_png { 
    my $self = shift;
    my $file = shift;
    my $print_all_labels= shift; ## Boolean for printing non-leaf node labels
    $self->layout();
    my $png_string = $self->render($print_all_labels);
    if(defined $file){
	open (my $T, ">$file") || die "PNG_tree_renderer: render_png(): Can't open file $file.";
	print $T $png_string; 
	close $T ;
    }
    else {
	return $png_string;
    }
}

=head2 function collapse_tree()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub collapse_tree {
    my $self = shift;
    # first, collapse all nodes that have only one child onto the
    # parent node
    #
#print STDERR "before rec..coll...single_nodes\n";
    $self->get_root()->recursive_collapse_single_nodes();
#print STDERR "after rec..coll...single_nodes\n";
    $self->recalculate_tree_data();

    # then, collapse all nodes that have branch lengths of zero 
    # with their parent node
    #
#print STDERR "before rec..coll...zero_branches\n";
    $self->get_root()->recursive_collapse_zero_branches();
#print STDERR "after rec..coll...zero_branches\n";

    # let's re-calculate the tree's properties
    #
    $self->recalculate_tree_data();
}

sub  collapse_unique_species_subtrees { 
    my $self = shift;
   # calculate, for each node, how many nodes are beneath it.
    # This information can then be accessed using the
    # $node-> get_subtree_node_count() function.
    #
  #  $self->get_root()->calculate_subtree_node_count();

    # calculate, for each node, how many different species are in the leaves of the subtree beneath it.
    #
    $self->get_root()->recursive_set_leaf_species_count();

    # recursively go through the tree
    #
    $self->get_root()->recursive_collapse_unique_species_subtrees();
}

=head2 function find_point_furthest_from_leaves()

  Synopsis:	$t->find_point_furthest_from_leaves()
  Arguments:	None.
  Returns:	A list containing a node object, and the distance 
                above that node of the point furthest from the leaves.
  Side effects:	Calls recursive_find_point_furthest_from_leaves, 
                which sets some attributes.
  Description:	For each point there is a nearest leaf at distance 
                dnear. This returns the point which maximizes dnear.

=cut					

sub find_point_furthest_from_leaves{
		my $self = shift;
		$self->set_min_dist_to_leaf();
		my @furthest_point = $self->get_root()->recursive_find_point_furthest_from_leaves();
		$furthest_point[1] -= $furthest_point[0]->get_attribute("min_dist_to_leaf"); 
		return @furthest_point;
}

=head2 function find_point_closest_to_furthest_leaf()

  Synopsis:	$t->find_point_closest_to_furthest_leaf();
  Arguments:	None.
  Returns:	A list containing a node object, and the distance 
                above that node of the point closest to furthest leaf.
  Side effects:	Calls recursive_set_max_dist_to_leaf_in_subtree, 
                which sets some attributes.
  Description:	For each point there is a furthest leaf at distance 
                dfar. This returns the point which minimizes dfar.

=cut					

# returns a list containing a node object, and the distance of the point above that node
sub find_point_closest_to_furthest_leaf{
		my $self = shift;
		$self->get_root()->recursive_set_max_dist_to_leaf_in_subtree();

		my @nodes = $self->get_root()->recursive_subtree_node_list();
		push @nodes, $self->get_root(); # we want the root in our list
	
		my @sorted_nodes = sort 
				{ $a->get_max_leaf_leaf_pathlength_in_subtree_thru_node() 
							<=> 
									$b->get_max_leaf_leaf_pathlength_in_subtree_thru_node() } 
						@nodes;

		# using attribute "lptl_child" (longest path to leaf child) follow the longest path to leaf,
		# until you reach the midpoint of the longest leaf to leaf path
		my $current_node = pop @sorted_nodes;
		my $distance_to_go = 0.5*($current_node->get_attribute("dist_to_leaf_longest") - $current_node->get_attribute("dist_to_leaf_next_longest"));
		for (;;) {
				my $next_node = $current_node->get_attribute("lptl_child");
				my $branch_length = $next_node->get_branch_length();
				if ($branch_length >= $distance_to_go) {
						return ($next_node, $branch_length - $distance_to_go);
				} else {
						$distance_to_go -= $branch_length;
						$current_node = $next_node;
				}
		}
}



=head2 function reset_root_to_point_on_branch()

  Synopsis:	$t->reset_root_to_point_on_branch($anode, $distance)
  Arguments:	First arg is a node, the second a distance above that 
                node. Together they define a point which will be new 
                root.
  Returns:	Nothing.
  Side effects:	Resets root to a point specified by arguments, and 
                deletes old root node.
  Description:	Use this to reset the root to a point along a branch.
  Author:       Tom York.

=cut
sub reset_root_to_point_on_branch{
		my $self = shift; 
		my ($child_of_new_node, $dist_above) = @_;

		my $new_node = $child_of_new_node->add_parent($dist_above); # goes
		my $former_root = $self->get_root();

		$self->reset_root($new_node);

		$self->collapse_tree();
}

=head2 function set_min_dist_to_leaf()

  Synopsis:	$t->set_min_dist_to_leaf()
  Arguments:	None.
  Returns:	Nothing.
  Side effects:	Sets the following attributes for every node 
                in tree: min_dist_to_leaf, near_leaf_path_direction, 
                near_leaf_path_next_node
  Description:	 
  Author:       Tom York.

=cut

sub set_min_dist_to_leaf{
	my $self = shift;
	$self->get_root()->recursive_set_min_dist_to_leaf();
	$self->get_root()->recursive_propagate_mdtl();
}


=head2 function min_leaf_dist_variance_point()

  Synopsis:	$t->min_leaf_dist_variance_point()
  Arguments:	None.
  Returns:	List ($n, $d) specifying the desired point as 
                lying at a distance $d above the node $n.
  Side effects:	Calls recursive_set_dl_dlsqr_sums_down(), and 
                recursive_set_dl_dlsqr_sums_up(), which set 
                several node attributes
  Description:	Returns the point in the tree such that the 
                variance of the distances from the point to the 
                leaves is minimized.
  Author:       Tom York.

=cut

sub min_leaf_dist_variance_point{
	my $self = shift;

	$self->get_root()->recursive_set_dl_dlsqr_sums_down();
	$self->get_root()->recursive_set_dl_dlsqr_sums_up();

	my @node_list = $self->get_root()->recursive_subtree_node_list();
	my $opt_node = shift @node_list;
	my ($opt_dist_above, $opt_var) =  $opt_node->min_leaf_dist_variance_point();

	foreach my $n (@node_list) {
		my ($da, $var) = $n->min_leaf_dist_variance_point();
		if ($var < $opt_var) {
			$opt_node = $n;
			$opt_dist_above = $da;
			$opt_var = $var;
		}
	}
		$self->get_root()->recursive_delete_dl_dlsqr_attributes();
	return ($opt_node, $opt_dist_above, $opt_var);
}


=head2 function test_tree_node_hash()

  Synopsis:	$t->test_tree_node_hash()
  Arguments:	None.
  Returns:	1 if test is passed, 0 otherwise.
  Side effects:	None.
  Description:	Tests that the nodes in the tree as found by  
                recursive_subtree_node_list() agree
                with the node hash. Specifically tests that 
                1) the key of each node (found by 
                   recursive_subtree_node_list()) is found in 
                   the node hash, 
                2) no two nodes have the same key,
                3) each key in the node hash is the key of some node.
      
                It is possible for parts of the tree to become 
                disconnected,  so that it would not be possible to 
                get from one to the other by at each step going from 
                a node to a parent or child node, although all nodes 
                would be in the node hash.
  Author:       Tom York.

=cut

sub test_tree_node_hash{
	my $ok1 = 1; my $ok2 = 1; my $ok3 = 1;
	my $self = shift;
	my $node_hashref = $self->{node_hash};
	my $root = $self->get_root();
	my @node_list = $root->recursive_subtree_node_list();
	push @node_list, $root;
	my %nodekeys;
	
	foreach my $n (@node_list) { # test that each node in this list is found in the tree's node hash
		my $node_key = $n->get_node_key();
		$nodekeys{$node_key}++;
		if (!defined $node_hashref->{$node_key}) { # a node in node_list is not in the hash.
			$ok1 = 0;
		}
	}

	if (scalar keys %nodekeys != scalar @node_list) { # test that each node in node_list has a distinct key
		$ok2 = 0;
	}

	my @node_keys = keys (%$node_hashref); # test that each key in node hash is
	if (scalar @node_keys != scalar @node_list) {
		$ok3 = 0;
	}
	return $ok1*$ok2*$ok3; 
}


=head2 function test_tree_parents_and_children()

  Synopsis:	$t->test_tree_parents_and_children()
  Arguments:	None.
  Returns:	1 if test is passed, 0 otherwise.
  Side effects:	None.
  Description:	Tests that node $a is a child of $b, 
                if and only iff $b is the parent of $a.
  Author:       Tom York.

=cut

sub test_tree_parents_and_children{
	my $self = shift;
	my $ok1 = $self->test_tree_nodes_are_parents_of_their_children();
	my $ok2 = $self->test_tree_nodes_are_children_of_their_parents();
	return ($ok1 && $ok2);
}

sub test_tree{
	my $self = shift;
	return $self->test_tree_node_hash() && $self->test_tree_parents_and_children();
}

# tests that for all nodes n, each child of n has n as its parent.
sub test_tree_nodes_are_parents_of_their_children{
	my $self = shift;
	my $root = $self->get_root();
	my @node_list = $root->recursive_subtree_node_list();
	push @node_list, $root;
	my $ok = 1;

	foreach my $n (@node_list) {
		my @children = $n->get_children();
		my $node_key = $n->get_node_key();
		foreach my $c (@children) {
			if(! defined $c->get_parent()){
				print("child node has undefined parent. \n"); $n->print_node(); $c->print_node();
				$ok = 0;
			} elsif ($c->get_parent()->get_node_key() != $node_key) {
				print("child node has wrong parent. \n"); $n->print_node(); $c->print_node();
				$ok = 0;
			}
		}
	}
	return $ok;
}


# tests that for all nodes n, that if n has a parent, then n is among the children of that parent.
sub test_tree_nodes_are_children_of_their_parents{
	my $self = shift;
	my $root = $self->get_root();
	my @node_list = $root->recursive_subtree_node_list();
	push @node_list, $root;
	my $ok = 1;

	foreach my $n (@node_list) {	# test that $n is among the children of its parent
		my $p = $n->get_parent();
		if (defined $p) {						# if not defined, do no test for this node
			my @children = $p->get_children();
			my $this_n_ok = 0;
			foreach my $c (@children) {
				if ($c->get_node_key() == $n->get_node_key()) {
					$this_n_ok = 1;
					last;
				}
			}
			if(! $this_n_ok){ print("This node not among the children of its parent: \n"), $n->print_node(); }
			$ok &&= $this_n_ok;
		}		
	}
	return $ok;
}

=head2 function orthologs()

  Synopsis:	$ortho_grp = $ortho_tree->
                    orthologs($species_tree, $cssst)
  Arguments:	a tree object, and an argument which, if non-zero, 
                causes single-species trees to be collapsed to a 
                single node.
  Returns:	An list of ortholog groups.
  Side effects:	
  Description:  Calls get_orthologs to get the ortholog_trees 
                defined without using a species tree, i.e. maximal 
                subtrees in which all leaves are of distinct species.
                Then for each ortholog group compare its tree to 
                the species tree (if present), to see if topologies 
                are the same, and if not, get a "distance " from 
                ortholog tree to species tree topology.
  See also:

=cut

sub orthologs{
	my $self = shift;						# tree
	my $species_t = shift;				# species tree; if undefined, 
	my $cssst = shift;						# switch to collapse single-species subtrees to a single node
	my $qRFd_max = shift;
	if (!defined $qRFd_max) {
		$qRFd_max = 0;
	}
	if ($cssst) {
		$self->collapse_unique_species_subtrees();
	}
	# should  we collapse the tree here?
	my $ortho_trees_ref = $self->get_orthologs();
	my @ortho_groups=();					# a list of Ortholog_group object that will contain the results

	# go through all the ortho_trees and compare to the species tree
	#
	foreach my $ortho_t (@$ortho_trees_ref) {
		my $ortho_group = CXGN::Phylo::Ortholog_group->new($ortho_t, $species_t, $qRFd_max);	
		if ($ortho_group->get_ortholog_tree()->get_leaf_count()>1) {
			push @ortho_groups, $ortho_group;
		}
	}															# end of foreach my $ortho_t (@$ortho_trees_ref) {
	return @ortho_groups;
}																# end of sub orthologs

=head2 function set_missing_species_from_names()

  Synopsis:	$atree->set_missing_species_from_names()
  Arguments:	none
  Returns:	nothing
  Side effects:	For any leaf nodes with species undefined, 
                sets the species to something derived from 
                node name
  Description:  Try to come up with a species for each leaf node 
                if not already defined. So will not overwrite 
                species names coming from, e.g., the [species='tomato'] 
                type specification in a newick file.
  See also:

=cut

sub set_missing_species_from_names{
	my $self = shift;
	foreach my $n ($self->get_leaf_list()) { 
		#	print("defined \$n->get_species():{", defined $n->get_species(), "}  ,\$n->get_species():{", $n->get_species(), "}\n");
		if (!$n->get_species()) {
			$n->set_species($n->determine_species_from_name());
		}
	}
}

=head2 function impose_branch_length_minimum()

  Synopsis:	$atree->impose_branch_length_minimum($bl_min)
  Arguments:	The minimum branch length.
  Returns:	nothing
  Side effects:	Set branch lengths < $bl_min to $bl_min. 
                (Root branch length remains 0)
  Description:  Zero branch lengths may possibly cause problems 
                in some cases; use this to establish a small 
                non-zero minimum branch length;

=cut

sub impose_branch_length_minimum{
	my $self = shift;
	my $minimum_bl = shift;
	$minimum_bl ||= $self->get_min_branch_length();
	foreach my $n ($self->get_all_nodes()) { 
		unless (defined $n->get_branch_length() and $n->get_branch_length() > $minimum_bl) {
			$n->set_branch_length($minimum_bl);
		}
	}
	$self->get_root()->set_branch_length(0.0); # leave this at 0
}


sub set_show_standard_species{
	my $self = shift;
	$self->{show_standard_species} = shift;
}
sub get_show_standard_species{
	my $self = shift;
	return $self->{show_standard_species};
}

sub set_species_standardizer{
	my $self = shift;
	$self->{species_standardizer} = shift;
}

sub get_species_standardizer{
	my $self = shift;
	return $self->{species_standardizer};
}


=head2 function update_label_names()

  Synopsis:	$atree->update_label_names()
  Arguments:	none
  Returns:	nothing
  Side effects:	Sets all the node labels to the node name 
                with or without the species appended,
	        as specified by $self->get_show_species_in_labels()

=cut

sub update_label_names{
	my $self = shift;
	my $show_spec = $self->get_show_species_in_label();
	foreach my $n ($self->get_all_nodes()) {
		my $n_leaves = scalar @{$n->get_implicit_names()};	
		my $label_text = $n->get_name();	
		#	print STDERR "in update_label_names. $n_leaves, [", $n->get_name(), "][", $label_text, "] \n";
		if ($show_spec) {
			my $species_text = $n->get_shown_species();
			#	print STDERR "species text: ", $n->get_shown_species(), "   is leaf:[", $n->is_leaf(), "]\n";
			$label_text .= " [".$species_text."]" if(defined $species_text);
		}
		$n->get_label()->set_name($label_text);
	}
}

=head2 function prune_nameless_leaves()

  Synopsis:	$atree->prune_nameless_leaves()
  Arguments:	none
  Returns:	nothing
  Side effects:	Deletes from the tree all leaves whose 
                names are empty or undefined. 

=cut

sub prune_nameless_leaves{
	
		my $self = shift;
		my @leaf_list = $self->get_root()->recursive_leaf_list(); 
		my $count_leaves_deleted = 0;
		$self->get_root()->recursive_implicit_names(); # is this needed?
		foreach my $l (@leaf_list) {
			if ($l->get_name()) {			# non-empty string. OK.
			} else {
		#	print STDERR "Warning. Leaf node with key: ", $l->get_node_key(), " has empty or undefined name. Deleting nameless node. \n";
			$self->del_node($l);
			$self->collapse_tree();
			$count_leaves_deleted++;
		}
	}
	return $count_leaves_deleted;
}

# return key, node pair corresponding to the implicit name given as argument.
sub node_from_implicit_name_string{
	#searches tree until the node with the specified implicit name string (tab separated) is found
	my $self = shift;
	my $in_string = shift;
	if (! scalar $self->get_root()->get_implicit_names() > 0) {
		$self->get_root()->recursive_implicit_names();
	}

	foreach my $k ($self->get_all_node_keys()) {
		my $n = $self->get_node($k);
		my $node_impl_name = join("\t", @{$n->get_implicit_names()});
		if ($node_impl_name eq $in_string) {
			return ($k, $n);
		}
	}
#	print STDOUT "In Tree::node_from_implicit_name_string. Node not found which matches specified string: $in_string \n";
# $self->get_root()->print_subtree("<br>");
	return (undef, undef);
}


sub leaf_species_string{
	my $self = shift; 
my $str = "species,     standard species \n";
	foreach my $l ($self->get_leaf_list()) {
		$str .=  $l->get_species() . "  " . $l->get_standard_species() . "\n";
	}
}

=head2 function quasiRF_distance

  Synopsis:	$tree1->quasiRF_distance($tree2), or 
                $node1->quasiRF_distance($tree2, "species");
  Arguments:	A tree object; and optionally a string specifying 
                whether to compare node name or species. 
                (Default is name)
  Returns:	Compares tree1 and tree2. If they are topologically 
                the same, 0 is returned. Otherwise returns a "distance" 
                describing how different the two trees are.
  Side effects:	Sets "subtree_leaves_match" field for each node, and 
                (by calling recursive_quasiRF_distance) sets 
                "qRF_distance" field for each node.
  Description:	Tree1, tree2 should be collapsed before calling this 
                function. For each node in tree1 add branch length to 
                distance if a node with the same implicit name 
                (or implicit species, depending on value of second 
                argument) is not present in tree2. 
                This is somewhat like the Robinson-Foulds distance, but 
                is not symmetric (hence not a true distance), 
                as the topologies of both subtrees are used, but only 
                the tree1 branch lengths are used. Think of it as a 
                measure of how much tree1 much be changed to reach the 
                topology of tree2.
                We are typically going to use it to compare an ortholog 
                tree with a species tree, in which case the implicit 
                species should be used in the comparison, i.e. it 
                should be called with the optional 2nd arg having value 
                "species"

=cut

sub quasiRF_distance{
my $self = shift;
my $tree1 = $self;
my $tree2 = shift;
my $compare_field = shift; 

	my $root1 = $tree1->get_root();
	my $root2 = $tree2->get_root();

	my $distance = 0.0;

	# get the implicit names or species for each node in both trees
	#
	if (lc $compare_field eq "species") {
#print STDOUT "top of quasiRF... compare_field eq species branch. \n";
		$root1->recursive_implicit_species();
		$root2->recursive_implicit_species();

		my %n_bl_2 = ();						# set up the hash for tree2 nodes, with species as key (value unused)
		my $nhr2 = $tree2->{node_hash};	
		foreach my $n2 (values ( %$nhr2)) {
			my $implicit_species = join("\t", @{$n2->get_implicit_species()});
			#	print STDOUT "Y stree implicit species: $implicit_species <br>\n";
			$n_bl_2{$implicit_species}++;	# values are not used, just count occurrences
		}													
		
		my $nhr1 = $tree1->{node_hash};
		foreach my $n1 (values ( %$nhr1)) {
			my $implicit_species = join("\t", @{$n1->get_implicit_species()});
			#	print STDOUT "otree implicit species: $implicit_species <br>\n";
			if (exists $n_bl_2{$implicit_species}) { # there are subtrees with this set of leaves in both trees, do nothing
				$n1->set_attribute("subtree_leaves_match", "true"); 
			#	print STDOUT "true <br>\n";
			} else {									# no node with this implicit name in tree2, so add branch length to total
				$distance += $n1->get_branch_length();
				$n1->set_attribute("subtree_leaves_match", "false");
			}
		}
	} else {
			$root1->recursive_implicit_names();
			$root2->recursive_implicit_names();

			# set up the hash for tree2 nodes, with name as key (value unused)
			my %n_bl_2 = ();
			my $nhr2 = $tree2->{node_hash};	
			foreach my $n2 (values ( %$nhr2)) {
				$n_bl_2{$n2->get_name()}++;	# values are not used, just count occurrences of the name
			}													
		
			my $nhr1 = $tree1->{node_hash};
			foreach my $n1 (values ( %$nhr1)) {			
				if (exists $n_bl_2{$n1->get_name()}) { # there are subtrees with this set of leaves in both trees, do nothing
					$n1->set_attribute("subtree_leaves_match", "true");
				} else {								# no node with this implicit name in tree2, so add branch length to total
					$distance += $n1->get_branch_length();
					$n1->set_attribute("subtree_leaves_match", "false");
				}
			}
		}
my $distance2 = $root1->recursive_quasiRF_distance(); # this works on tree1 - which is not a copy here.
return $distance;								# $tree1 has qRFd info at every node.
}

sub RF_distance { 
	my $self = shift;
	my $other_tree = shift;
	my $compare_field = shift;		# to control comparison of names (default) or species ("species")
	# copy the trees into temporary trees, so that the trees can 
	# be manipulated (rerooted, collapsed) without changing the original trees.
	#
	# print STDOUT "in compare_unrooted. compare_field: $compare_feld \n";
	my $tree1 = $self->copy();
	my $tree2 = $other_tree->copy();

	# find a leaf - any leaf - of tree1 and the corresponding leaf (i.e. with the same name) of tree2

	my $leaf1 = $tree1->get_root()->recursive_get_a_leaf();
	my $corresponding_leaf = $tree2->get_node_by_name($leaf1->get_name());

	if (!$corresponding_leaf) {
		print("in compare_unrooted. leaf1 name: ", $leaf1->get_name(), ". Can't find corresponding leaf in other tree. \n"); 
		return 0;
	}

	# reset roots of trees to the two corresponding leaves:
	$tree1->reset_root($leaf1);
	$tree2->reset_root($corresponding_leaf);

	return $tree1->RF_distance_inner($tree2, $compare_field);
}

=head2 function RF_distance_inner

  Synopsis:	$tree1->RF_distance($tree2),
                or $node1->RF_distance($tree2, "species");
  Arguments:	A tree object; and optionally a string specifying 
                whether to compare node name or species. 
                (Default is name)
  Returns:	Compares tree1 and tree2. If they are topologically 
                the same, 0 is returned. Otherwise returns a "distance" 
                describing how different the two trees are.
  Side effects:	Sets "subtree_leaves_match" field for each node
  Description:	Tree1, tree2 should be collapsed before calling this 
                function. For each node in tree1 add branch length to 
                distance if a node with the same implicit name 
                (or implicit species, depending on value of second 
                argument) is not present in tree2. 
                This computes the Robinson-Foulds distance. Topologies 
                and branch lengths of both trees are used
                Think of it as a measure of how much tree1 much be 
                changed to become tree2.
     

=cut

sub RF_distance_inner{
	my $self = shift;
	my $tree1 = $self;
	my $tree2 = shift;
	my $compare_field = shift; 

	my $root1 = $tree1->get_root();
	my $root2 = $tree2->get_root();

	my $sym_diff = 0;							#symmetric difference, just one for each partition in only one tree
	my $distance = 0.0;
	my $in_both_sum = 0.0;
	my $in_one_only_sum = 0.0;
	my $branch_score = 0.0;

	# get the implicit names or species for each node in both trees
	#
	if (lc $compare_field eq "species") {
	#	die "RF_distance with compare_field set to species is not implemented. \n";
		#print STDOUT "top of quasiRF... compare_field eq species branch. \n";
		$root1->recursive_implicit_species();
		$root2->recursive_implicit_species();
		unless(join("\t", $root1->get_implicit_species()) eq join("\t", $root1->get_implicit_species())){
			print STDERR "In RFdistance; trees do not have same set of leaves (by species).\n";
			return undef;
		}
		# set up the hash for tree nodes, with species as key, node obj as value
		my %n_bl_1 = ();
		my @nhr1 = $root1->recursive_subtree_node_list; #->{node_hash};	

		foreach my $n1 (@nhr1) {		#all tree1 nodes except root1
			$n_bl_1{$n1->get_species()} = $n1;	
		}		
		my %n_bl_2 = ();
		my @nhr2 = $root2->recursive_subtree_node_list; #$tree2->{node_hash};	
		foreach my $n2 (@nhr2) {		#all tree2 nodes except  root2
			$n_bl_2{$n2->get_species()} = $n2;
		}													
		
		#	my $in_both_sum = 0.0;
		#		my $in_one_only_sum = 0.0;
		foreach my $n1 (@nhr1) {	
			if (exists $n_bl_2{$n1->get_species()}) { # there are subtrees with this set of leaves in both trees
				my $n2 = $n_bl_2{$n1->get_species()};
				$in_both_sum += abs($n1->get_branch_length() - $n2->get_branch_length());
			} else {									# no node with this implicit species in tree2, so add branch length to total
				$in_one_only_sum += $n1->get_branch_length();
				$sym_diff++;
			}
		}
		#		my $in_both_sum2 = 0.0;
		foreach my $n2 (@nhr2) {		
			if (exists $n_bl_1{$n2->get_species()}) { # there are subtrees with this set of leaves in both trees
				#	my $n1 = $n_bl_1{$n2->get_species()};
				#				$in_both_sum2 += abs($n1->get_branch_length() - $n2->get_branch_length());
			} else {									# no node with this implicit species in tree2, so add branch length to total
				$in_one_only_sum += $n2->get_branch_length();
				$sym_diff++;
			}
		}
		#	print ("in_both_sum: ", $in_both_sum, "   in_one_only_sum: ", $in_one_only_sum, "\n");
		#		$distance = $in_both_sum + $in_one_only_sum;
		#		print "distance: ", $distance, "\n";


	} else {											# compare field is "name"
#		print "comparing trees by name fields \n";
		$root1->recursive_implicit_names();
		$root2->recursive_implicit_names();
		unless(join("\t", $root1->get_name()) eq join("\t", $root1->get_name())){
			print STDERR "In RFdistance; trees do not have same set of leaves (by name).\n";
			return undef;
		}
		# set up the hash for tree nodes, with name as key, node obj as value
		my %n_bl_1 = ();
		my @nhr1 = $root1->recursive_subtree_node_list(); #->{node_hash};	

		foreach my $n1 (@nhr1) {		#all tree1 nodes except root1
#			print "n1 name: ", $n1->get_name(), "\n";
			$n_bl_1{$n1->get_name()} = $n1;	
		}		
		my %n_bl_2 = ();
		my @nhr2 = $root2->recursive_subtree_node_list(); #$tree2->{node_hash};	
		foreach my $n2 (@nhr2) {		#all tree2 nodes except  root2
#			print "n2 name: ", $n2->get_name(), "\n";
			$n_bl_2{$n2->get_name()} = $n2;
		}													
		
		#	my $in_both_sum = 0.0;
		#		my $in_one_only_sum = 0.0;
		my $diff = 0.0;
		# foreach my $n1 (@nhr1) {
		foreach my $name1 (keys %n_bl_1){
			my $n1 = $n_bl_1{$name1};
			if (exists $n_bl_2{$n1->get_name()}) { # there are subtrees with this set of leaves in both trees
				my $n2 = $n_bl_2{$n1->get_name()};
				$diff = $n1->get_branch_length() - $n2->get_branch_length();
				$in_both_sum += abs($diff);	# $n1->get_branch_length() - $n2->get_branch_length());
				#	$branch_score += $diff*$diff;
			} else {									# no node with this implicit name in tree2, so add branch length to total
				$diff = $n1->get_branch_length();
				$in_one_only_sum += $diff; # $n1->get_branch_length();
				#	$branch_score += $diff*$diff;
				$sym_diff++;
#				print "name not present in hash 2: ", $n1->get_name(), "\n";
			}
			$branch_score += $diff*$diff;
		}
		#		my $in_both_sum2 = 0.0;
	#	foreach my $n2 (@nhr2) {		
		foreach my $name2 (keys %n_bl_2){
			my $n2 = $n_bl_2{$name2};
			if (exists $n_bl_1{$n2->get_name()}) { # there are subtrees with this set of leaves in both trees
				#	my $n1 = $n_bl_1{$n2->get_name()};
				#				$in_both_sum2 += abs($n1->get_branch_length() - $n2->get_branch_length());
			} else {									# no node with this implicit name in tree2, so add branch length to total
				$in_one_only_sum += $n2->get_branch_length();
				$sym_diff++;
			#	print "name not present in hash 1: ", $n2->get_name(), "\n";
			}
		}	
	}

	$distance = $in_both_sum + $in_one_only_sum;
#	print ("in_both_sum: ", $in_both_sum, "   in_one_only_sum: ", $in_one_only_sum,  "       RFdistance: ", $distance, "\n");
	return ($distance, $sym_diff, $branch_score);							
}

sub get_branch_length_sum{
	my $self = shift;
	my @nodelist = $self->get_root()->recursive_subtree_node_list; 
	my $bl_sum = 0.0;
	foreach (@nodelist) {
		$bl_sum += $_->get_branch_length();
	}
	return $bl_sum;
}

sub get_branch_length_sum_noterm{ # sum of all non-terminal branch lengths
	my $self = shift;
	my @nodelist = $self->get_root()->recursive_subtree_node_list; 
	my $bl_sum = 0.0;
	foreach (@nodelist) {
		next if($->is_leaf());
		$bl_sum += $_->get_branch_length();
	}
	return $bl_sum;
}

sub multiply_branch_lengths_by{
	my $self = shift;
	my $factor = shift;
	my @nodelist = $self->get_root()->recursive_subtree_node_list; 
	foreach (@nodelist) {
		$_->set_branch_length($_->get_branch_length()*$factor);
	}
}

#scale branch lengths s.t. their sum is #desired_bl_sum (1.0 by default)
# returns original bl sum
sub normalize_branch_length_sum{
	my $self = shift;
	my $desired_bl_sum = shift;
	$desired_bl_sum ||= 1.0;
	my $bl_sum = $self->get_branch_length_sum();
	if ($bl_sum <= 0.0) {
		print STDERR "Can\'t normalize branch length sum, sum is $bl_sum; <= zero. \n";
	} else {
		$self->multiply_branch_lengths_by($desired_bl_sum/$bl_sum);
	}
	return $bl_sum;
}

sub RFdist_over_totbl{ # this is (weighted, i.e. using branch lengths) RF distance, normalized by sum of all
# branch lengths in both trees, so it will lie in range [0,1]
	my $self = shift;
	my $tree1 = $self;
	my $tree2 = shift;
	my $compare_field = shift;
	my $normalize_bl_sums = shift;
	$normalize_bl_sums = 0 unless(defined $normalize_bl_sums);

	if ($normalize_bl_sums) {
		$tree1->normalize_branch_length_sum();
		$tree2->normalize_branch_length_sum();
	}
	my $bl_sum = $tree1->get_branch_length_sum() + $tree2->get_branch_length_sum();
	#print "bl_sum: $bl_sum \n";
	my ($rfd, $symdiff, $branch_score) = $tree1->RF_distance($tree2, $compare_field);
#	print "bl_sum: $bl_sum . rfd:  $rfd \n";
	return $rfd/$bl_sum;
}

# divide into trees no bigger than $max_leaves
sub divide_into_small_trees{
	my $self = shift;
	my $max_leaves = shift;
	$max_leaves ||= 100;
	#	print "in Tree::divide_into_small_trees.  ", $self->get_root()->get_attribute("leaf_count"), "\n\n";
	my $small_trees_array = $self->get_root()->recursive_divide_subtree_into_small_trees($max_leaves);
	return $small_trees_array;
}

# get list of subtrees containing ortholog group candidate subtrees
# (trees with > 1 leaf, and distinct species in all leaves)
# the  argument allows one to specify to go up some number of parent
# nodes above the nodes with the ortholog group candidate subtrees.
sub get_ortholog_group_candidate_subtrees{
	my $self = shift;
	my $desired_levels_above = shift;
	$desired_levels_above = 0 unless($desired_levels_above > 0);
#	print "tree. levels_above: ", $desired_levels_above, "\n";
	my $ortholog_group_candidate_subtrees_array = [];
	$self->get_root()->recursive_set_levels_above_distinct_species_subtree();
	$self->get_root()->recursive_find_ortholog_group_candidate_subtrees($ortholog_group_candidate_subtrees_array, $desired_levels_above);
	return $ortholog_group_candidate_subtrees_array;
}

	# using urec, find the node s.t. rooting on its branch gives minimal duplications and losses
	# w.r.t. a species tree
sub find_mindl_node{					
	my $gene_tree = shift;				# a rooted gene tree
	my $species_t = shift;				# a species tree

# print STDERR "##################### Top of find_mindl_node. #############\n";
	# urec requires binary tree - make sure the tree is binary
	# if polytomy at root, reroot a bit down one branch, to get binary root (if was tritomy)
	my @new_root_point;
	{
		my @root_children = $gene_tree->get_root()->get_children();
		if (scalar @root_children != 2) {
			@new_root_point = ($root_children[0], 0.9*$root_children[0]->get_branch_length());
			$gene_tree->reset_root_to_point_on_branch(@new_root_point);
		}
	}
	# binarify every non-binary node. At present doesn't attempt to choose in a smart way
	# among the various possible resolutions
	$gene_tree->make_binary($gene_tree->get_root()); # urec requires binary tree. 

	my $store_show_std_species = $gene_tree->get_show_standard_species();
	# put the trees into form of newick strings with no whitespace, so urec will be happy
	$gene_tree->show_newick_attribute("species");
	$gene_tree->set_show_standard_species(1);
	my $gene_newick_string = $gene_tree->generate_newick();
	print "binarified gene tree (urec input): ", $gene_newick_string, "\n";
	$gene_newick_string =~ s/\s//g; 

	$species_t->show_newick_attribute("species");
	$species_t->set_show_standard_species(1);
	my $species_newick_string = $species_t->generate_newick();
	$species_newick_string =~ s/\s//g; 

#	my $rerooted_newick = `/data/local/cxgn/core/sgn-tools/family/Urec/urec -s "$species_newick_string"  -g "$gene_newick_string" -b -O`;
	my $rerooted_newick = `/data/local/cxgn/core/perllib/CXGN/Phylo/Urec/urec -s "$species_newick_string"  -g "$gene_newick_string" -b -O`;
#	my $rerooted_newick = `urec -s "$species_newick_string"  -g "$gene_newick_string" -b -O`;

	#	print STDERR "gene_newick_string: \n $gene_newick_string   \n\nspecies_newick_string: \n $species_newick_string.\n\n";
#		print STDERR "Rerooted newick string: [$rerooted_newick].\n";

#exit;

	my $minDL_rerooted_gene_tree = (CXGN::Phylo::Parse_newick->new($rerooted_newick))->parse(); # this is now rooted so as to minimize gene duplication and loss needed to reconcile with species tree,
	# but  branch lengthswill be wrong for nodes whose parent has changed in the rerooting (they are just the branch lengths to the old parents). 
	$minDL_rerooted_gene_tree->get_root()->recursive_implicit_names();

	# $minDL_rerooted_gene_tree should have 2 children and (at least) one should have it's subtree also present in the pre-rerooting tree.
	# identify the node at the root of this subtree (using implicit names) and reroot there. 
	# Have to do this because some branch length info was lost in urec step. 
	my @root_children = $minDL_rerooted_gene_tree->get_root()->get_children();
	my ($node_key, $rr_node);
	foreach (@root_children) {
		my $implicit_name_string = join("\t", @{$_->get_implicit_names()});
		($node_key, $rr_node) = $gene_tree->node_from_implicit_name_string($implicit_name_string);
		if (defined $rr_node) { 
		#	debug ("Reroot above this node: $implicit_name_string \n"); 
			return @new_root_point = ($rr_node, 0.5*($rr_node->get_branch_length));
		}
	}
	die "find_mindl_node failed. \n";

#	$gene_tree->set_shown_standard_species($store_show_standard_species);
#$gene_tree->update_label_names();
	return (undef, undef);
}



sub get_species_bithash{ #get a hash giving a bit pattern for each species in both $gene_tree and $spec_tree
	my $gene_tree = shift;
	my $spec_tree = shift;
	my $bithash = {};
	my %genehash;
	my %spechash;
	$spec_tree->show_newick_attribute("species");
	my $stree_newick = $spec_tree->generate_newick();
# print STDERR "SPECIES TREE: $stree_newick \n";
	my @leaf_list = $gene_tree->get_leaf_list();
	foreach (@leaf_list) {
		my $lspecies = $_->get_standard_species();
	#	print STDERR "gtree species: $lspecies \n";
		$genehash{$lspecies}++; # keys are species in gene tree, values are number of leaves with that species
	}
	@leaf_list = $spec_tree->get_leaf_list();
	foreach (@leaf_list) {
		my $lspecies = $_->get_standard_species();
	#	print STDERR "stree species, raw, std: ", $_->get_standard_species(), "  $lspecies \n";
		if ($genehash{$lspecies}) {
			$spechash{$lspecies}++; # keys are species in both trees.
		}
	}
	my @species_list = sort (keys %spechash);
	#	print join(" ", @species_list), "\n";
	my $bits = 1;
	foreach (@species_list) {
		$bithash->{$_} = $bits;
		$bits = $bits << 1;					# mult by two
		#	print "$_, $bits \n";
	}

	return $bithash;
}

sub prune_non{  # prune leaves from tree 1 if their species does not occur in tree2
}

# return a hash whose keys are leaf node names (hidden nodes excluded)
# and whose values are refs to arrays of 1's and 0's, the 1's indicating orthology.
sub ortho_matrix_hash{
	my $self = shift;
	my @leaf_names = ();
	for ($self->get_leaves()) {
		next if($_->get_hide_label()); # do not include hidden labels
		push @leaf_names, $_->get_name();
	}
	@leaf_names = sort @leaf_names; 
#	print STDERR join(" ", @leaf_names), "\n";
	my $n_leaves = scalar @leaf_names;
	my %name_hash;
	my %ortho_hash;

	my $i = 0;
	foreach (@leaf_names) {
		$name_hash{$_} = $i;
		my @zeroes = (0)x$n_leaves;
		$ortho_hash{$_} = \@zeroes;
		$i++;
	}
	my @leaves = $self->get_leaves();
	foreach (@leaves) {
		my $name = $_->get_name();
		my $o_array = $ortho_hash{$name};
	#	print STDERR join(" ", @$o_array), "\n";
		my @orthologs = $_->collect_orthologs_of_leaf();
		foreach (@orthologs) {
			my $o_name = $_;					#->get_name();
		#	print STDERR $o_name, "  ", $name_hash{$o_name}, "\n";
			$o_array->[$name_hash{$o_name}] = 1; # in the array for $name set the right element to 1
		}
	}
#	foreach (@leaf_names) {
#		my $ortho_array_ref = $ortho_hash{$_};
#		printf STDERR ("%50s    ", $_); print STDERR join(" ", @$ortho_array_ref), "\n";
#	}
	return \%ortho_hash;
}
1;
