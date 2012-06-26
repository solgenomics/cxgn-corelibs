
=head1 NAME
 

CXGN::Phylo::Node - a package that handles nodes in a CXGN::Phylo::Tree object.

=head1 DESCRIPTION

This class deals with a node of a tree (see L<CXGN::Phylo::Tree>). The nodes can have children nodes, which can in turn have children, etc, to form a tree structure. Note that the tree need not be a binominal tree. However, it is a directed structure in the sense that the parent-child relationship is directional. The tree data structure will therefore always have an implicit root, which may not be the actual root. The root can be reset to any node in the tree by calling the reset_root() function in the Tree object. 

In addition to child information, a node object also contains a link to its parent node, which is undef in the case of the tree\'s root. Every node object also contains a pointer to the tree object it belongs to. The tree object contains additional data structures for rapidly identifying nodes in the tree. The node object also stores the name of the node, the species, hiliting information, and other data. Some of the data associated with nodes have their own accessors, while other data can be stored in the each node object using the set_attribute() and get_attribute() calls.

=head1 AUTHOR

Lukas Mueller (lam87@cornell.edu) and Tom York (tly2@cornell.edu)

=head1 FUNCTIONS

This class implements the following functions:

=cut

use strict; 

package CXGN::Phylo::Node;


use CXGN::Phylo::Species_name_map;
use CXGN::Phylo::Tree;
use CXGN::Phylo::Label;
use CXGN::Page::FormattingHelpers qw/tooltipped_text/;
 

=head2 function new()

  Synopsis:	Constructor
  Arguments:	none
  Returns:	a Node object
  Side effects:	
  Description:	

=cut

sub new {
	my $class = shift;
	my $args = {};
	my $self = bless $args, $class;

	$self->init_children();

	$self->set_label(CXGN::Phylo::Label->new());
	$self->set_name("");
	$self->set_species("");
	$self->set_node_key(0);
	$self->set_parent(undef);
	$self->set_branch_length(0);
	$self->set_hilited(0);
	$self->set_hidden(0);
	$self->set_X(0);
	$self->set_Y(0);
	$self->set_subtree_node_count(0);
$self->set_attribute("leaf_count", 0);
	$self->set_leaf_species_count(0);

	$self->{line_color} = [];

	return $self;
}

=head2 function print_node()

  Synopsis:	 $node->print_node();
  Arguments:	 Optionally a string which will be appended after the 
                 node_string, "\n" by default.
  Returns:	 nothing.
  Side effects:	 none.
  Description:	 Prints node name, key, etc on one line. See sub node_string.
  Author:        Tom York (tly2@cornell.edu)

=cut

sub print_node{
	my $self = shift;
	my $end_string = shift;
	if (!$end_string) {
		$end_string = "\n";
	}
	print $self->node_string() . $end_string;
}

=head2 function node_string()

  Synopsis:	$node->node_string();
  Returns:	A string describing the node, with name, key, 
                branch_length, species. No newline at end.
  Author:       Tom York (tly2@cornell.edu)

=cut

sub node_string{
	my $self = shift;
	my $name = $self->get_name();
	$name =~ s/\t/,/g;						# string together leaf names with - rather than tab
	my $p = $self->get_parent();
	my $pn = undef;
	if (defined $p) {
		$pn = $p->get_name(); $pn =~ s/\t/-/g;
	}
	my $node_string = "[" . $name . "] " . "[key:" . $self->get_node_key() . "]".
		"[bl:" . $self->get_branch_length() . "] " . 
			#				"[parent:" . $p . "]" . 
			#	"[implname=" . (join(",", @{$self->get_implicit_names()})) . "]" .
			#		"[implspecies=" . (join("-", @{$self->get_implicit_species()})) . "]" .
			#"[isroot:" . $self->is_root() . "]" .
			"[species=" . $self->get_species() . "] ";
	$node_string .= 
	#	"subtree/complement leaf species counts: [".$self->get_attribute("leaf_species_count")."]".
	#	"[".$self->get_attribute("comp_leaf_species_count")."]".
			"subtree species bit pattern: [".$self->get_attribute("species_bit_pattern")."]  ".
				"speciation: [".$self->get_attribute("speciation")."]  ";
	return $node_string;
}

=head2 function recursive_subtree_string()

  Synopsis:	$node->recursive_subtree_string($nl_string, $indent) 
  Arguments:	First arg is string to appear after each node (optional, 
                default is "\n"); second arg is indent string (optional, 
                default is "")
  Returns:      A string describing the subtree with by default each node
                on its own line, and indented proportional to depth in 
                tree.
  Author:       Tom York

=cut

sub recursive_subtree_string{
	my $self = shift;
	my $nl_string = shift;
	my $indent_string = shift;	
	if ($nl_string eq undef) { $nl_string = "\n"; }
	my $the_string .= $indent_string . $self->node_string() . $nl_string;
	foreach my $c ($self->get_children) {
		$the_string .= $c->recursive_subtree_string($nl_string, $indent_string . "  ");
	}
	return $the_string;
}

=head2 function print_subtree()

  Synopsis:	 $node->print_subtree() or $node->print_subtree("<br>") 
  Arguments:	 Optionally a string which will be printed after each 
                 node.  This will be "\n" by default, but could use 
                 "<br>" if using as html.
  Description:	 Prints the subtree with indentation indicating depth 
                 in subtree. 
  Author:        Tom York

=cut

sub print_subtree{
	print shift->recursive_subtree_string(shift);
}


sub get_alignment_member {
	my $self = shift;
	return $self->{alignment_member};
}

sub set_alignment_member {
	my $self = shift;
	$self->{alignment_member} = shift;
}

sub init_children {
	my $self = shift;
	@{$self->{children}} = ();
}

=head2 function get_children()

  Synopsis:	my @children = $n->get_children();
  Arguments:	none
  Returns:	a list of node objects that are children of $n
  Side effects:	none
  Description:	

=cut

sub get_children { 
	my $self = shift;
	if (exists ($self->{children})) {
		return @{$self->{children}};
	}
	return undef;
}

=head2 function set_children()

  Synopsis:
  Arguments:	an array of children.
  Returns:	
  Side effects:	sets the children to the specified array.
                You should normally use $node->add_child() to 
                add children. This function is intended for internal use.
  Description:	

=cut

sub set_children { 
	my $self = shift;
	@{$self->{children}}=@_;
}

=head2 function add_child()

  Synopsis:	$n->add_child();
  Arguments:	none
  Returns:	ref to newly added child
  Side effects:	adds a new CXGN::Phylo::Node object  to the list of 
                children for node $n adds the new node to the node 
                hash, using the unique id that add_child obtains 
                through $tree->get_unique_node_key().
  Description:	

=cut

sub add_child { 
	my $self = shift;
	my $child = CXGN::Phylo::Node->new();
	$self->add_child_node($child);
	my $tree = $self->get_tree();
	$child->set_tree($tree);

	# add the child node to the node_hash,
	# using the unique_node_key property of the corresponding tree 
        # object.
	#
	my $key = $tree->get_unique_node_key();
	$child->set_node_key($key);

	$tree->add_node_hash($child, $key);
	return $child;
}


=head2 function add_child_node()

  Synopsis:	$node->add_child_node($child)
  Arguments:	a node to be added as child of invocant node.
  Returns:	nothing
  Side effects:	Adds $child to $node's children list, and sets the parent 
                of $child to $node
  Description:	to construct a tree, generally use add_child(),
                which has more side effects. add_child_node()
                is useful in cases where the child node already
                exists and changes parentage.

=cut

sub add_child_node { 
	my $self = shift;
	my $child = shift;
	if (!$child) {
		warn 'CXGN::Phylo::Node::add_child_node: Would need a child node object to add.\n';  return;
	}
	foreach my $c ($self->get_children()) { 
		if (!$c) {
			warn 'CXGN::Phylo::Node::add_child_node: Illegal children...(continuing...)\n'; next;
		}
		if ($c->get_node_key() == $child->get_node_key()) { 
	    #print STDERR "CXGN::Phylo::Node::add_child_node: Attempting to add a child that already is a child.\n";
	    return;
		}
	}
	push @{$self->{children}}, $child;
	my $i=1;
	#foreach my $c (@{$self->{children}}) { print STDERR "!!!!!!Child name " . $i++ . ":"  . $c->get_name() . "!!!!!!!!!!!!!!\n"; }
	#print STDERR "adding child " . $child->get_name() . " to parent " . $self->get_name() . "...........\n" ;
	$child->set_parent($self);
}

=head2 function remove_child()

  Synopsis:	$a_node->remove_child($child)
  Arguments:	a node object, which should be a child of the invocant.
  Returns:	nothing
  Side effects: Remove a node from another node's list of children.  
                $child's parent.
  Description:	 

=cut

sub remove_child {							
#remove a node from another node's list of children - doesn't change $childs parent, should it?
	my $self = shift;
	my $child = shift;						# child node object to remove

	my $child_key = $child->get_node_key();

	my @children = $self->get_children();
	my $element = undef;
	my $found = 0;
	for (my $i=0; $i<(@children);$i++) {
		if ($child_key eq ($children[$i]->get_node_key())) {
		
	    $element = $i;
	    $found =1;
		}
	}

	if ($found) {
#	$children[$element]->set_parent(undef);
		my @removed = splice @children, $element, 1;
	
		if (@removed != 1) {
			print STDERR "remove_child: WARNING! Nothing was removed!\n";
		}
	} else {
		print STDERR "WARNING! Child cannot be removed because it has not been found!\n"; 
	}
	$self->set_children(@children);
}


=head2 function add_parent()

  Synopsis:	$n->add_parent(distance);
  Arguments:    a distance.
  Returns:	Reference to new node object.
  Side effects:	Constructs a new node object $p, make $p the parent of 
                $n, and the only child of $n's former parent. Adds $p 
                to the node hash, using the unique id obtained through 
                $tree->get_unique_node_key().
  Description:	Adds a node above the node specified as first argument, 
                at the distance specified as second argument. The new
                node has as its parent the parent of the original node, 
                which is its only child.
                So we are adding a node somewhere in the middle of a 
                branch. 
                Might want to do this and then reset root to the new node.
  Author:       Tom York

=cut

sub add_parent{
	my $self = shift;							# the node above which new node is to be added
	my $dist_above = shift;				# distance above $self to put the new node
	my $parent = $self->get_parent();
	my $bl = $self->get_branch_length();

	my $new = $parent->add_child(); # add $new as child of $parent
	$parent->remove_child($self); # remove $self as child of parent
	$new->add_child_node($self);	# add $self as child of $new
	$self->set_branch_length($dist_above);
	$new->set_branch_length($bl - $dist_above);
	return $new;
}


=head2 function binarify_children()

Some analysis programs, such as BayesTraits, requires that a tree be binary, meaning that each node has no more than two children.

This function creates new nodes (branch_length zero) recursively so this node will only have two children.  The distance relationships to the existing children will remain the same.

 Example

 ------1
 |
 x-------2
 |
 ----3

 will become

        -------1
        |
  -----b
 |     |
 |     -------2
 x
 |
 ----3
 
 where 'b' is a new node (branch point) that has 1 and 2 as children,
 and 'x' now has two children: 'b' and '3'

=cut

sub binarify_children {
# print "top of binarify children \n";
	my $self = shift;
	my $new_bl = shift;
	$new_bl ||= 0.0;
	my @children = $self->get_children();
	my @new_children = ();
	return if @children < 3;
 # print ("In binarify_children. number of children is > 2: ", scalar @children, " newbl: $new_bl\n");
	my $c1 = shift @children;
	my $c2 = shift @children;
	my $b = CXGN::Phylo::Node->new();
	$b->set_children($c1, $c2);
	$c1->set_parent($b);
	$c2->set_parent($b);
	$b->set_branch_length($new_bl);
	$b->set_parent($self); # don't forget to set parent of new node to $self!!!
	push(@children, $b);
	$self->set_children(@children);
	$self->get_tree()->incorporate_nodes($b);
	$self->binarify_children($new_bl);
#  print "bottom of binarify children \n";
}

=head2 function binarify_with_specified_resolution()

This takes two array refs as arguments, the arrays specify
the nodes which will be the children of the two newly created
nodes which are children of $self. (If one of the arguments contains
only one node, then no new parent node for that node is created.)
so a node:

s = (a,b,c,d) will go to ((a,b), (c,d)) if 
we call s->binarify_with_specified_resolution((a,b), (c,d))

=cut 

sub binarify_with_specified_resolution{
	my $self = shift;
	my $new_child_set1 = shift;		# a subset of self's children; these all go in one of the new subtrees,
	my $new_child_set2 = shift;		# a subset of self's children; these all go in the other new subtree.
	my @new_child_species_sets = ($new_child_set1, $new_child_set2);

	return if  $self->get_children() < 3;
	my @new_children = ();
#	if(0){
#	if (@$new_child_set1 > 1) {
#		my $b = CXGN::Phylo::Node->new();
#		$b->set_parent($self);
#		$b->set_children(@$new_child_set1);
#		my $new_bp = 0;							# species bit pattern for new node
#		my @new_implicit_species = ();
#		my @new_implicit_names = ();
#		foreach (@$new_child_set1) { 
#			$new_bp |= $_->get_attribute("species_bit_pattern");
#			@new_implicit_species = (@new_implicit_species, @{$_->get_implicit_species()});
#			@new_implicit_names = (@new_implicit_names, @{$_->get_implicit_names()});
#			$_->set_parent($b);
#		}
#		$b->set_attribute("species_bit_pattern", $new_bp);
#		$b->set_implicit_species(\@new_implicit_species);
#		$b->set_implicit_names(\@new_implicit_names);
#		$b->set_branch_length(0);
#		push @new_children, $b;
#		$self->get_tree()->incorporate_nodes($b);
#	} else {											# new_child_set has just one node; just push onto @new_children
#		push @new_children, $new_child_set1->[0];
#	}
#	if (@$new_child_set2 > 1) {
#		my $b = CXGN::Phylo::Node->new();
#		$b->set_parent($self);
#		$b->set_children(@$new_child_set2);
#		my $new_bp = 0;
#		my @new_implicit_species = ();
#		my @new_implicit_names = ();
#		foreach (@$new_child_set2) {
#			$new_bp |= $_->get_attribute("species_bit_pattern");
#			@new_implicit_species = (@new_implicit_species, @{$_->get_implicit_species()});
#			@new_implicit_names = (@new_implicit_names, @{$_->get_implicit_names()});
#			$_->set_parent($b);
#		}
#		$b->set_attribute("species_bit_pattern", $new_bp);
#		$b->set_implicit_species(\@new_implicit_species);
#		$b->set_implicit_names(\@new_implicit_names);
#		$b->set_branch_length(0);
#		push @new_children, $b;
#		$self->get_tree()->incorporate_nodes($b);
#	} else {											# new_child_set has just one node; just push onto @new_children
#		push @new_children, $new_child_set2->[0];
#	}
#}
#	else {
		foreach my $css (@new_child_species_sets) {
# print "XXXXX\n";
			if (@$css > 1) {
				my $b = CXGN::Phylo::Node->new();
				$b->set_parent($self);
				$b->set_children(@$css);
				my $new_bp = 0;
				my @new_implicit_species = ();
				my @new_implicit_names = ();
				foreach (@$css) {
					$new_bp |= $_->get_attribute("species_bit_pattern");
					@new_implicit_species = (@new_implicit_species, @{$_->get_implicit_species()});
					@new_implicit_names = (@new_implicit_names, @{$_->get_implicit_names()});
					$_->set_parent($b);
				}
				$b->set_attribute("species_bit_pattern", $new_bp);
				$b->set_implicit_species(\@new_implicit_species);
				$b->set_implicit_names(\@new_implicit_names);
				$b->set_branch_length(0);
				push @new_children, $b;
				$self->get_tree()->incorporate_nodes($b);
			} else {									# new_child_set has just one node; just push onto @new_children
				push @new_children, $css->[0];
			}
		}
	#}
	$self->set_children(@new_children);
}

=head2 function get_descendents()

 Return a list of all descendent nodes, in no particular order
 Args: (optional), [int] recursion depth.  
 	1=self+children, 
	2 => self+children+grandchildren, ...  
	-1 or no argument => all descendents

=cut

sub get_descendents {
	my $self = shift;
	my $order = shift;
	$order = -1 unless defined $order;
	my @desc = ();
	my @children = $self->get_children();
	return $self unless scalar @children;
	return $self if $order==0;
	$order--;
	foreach (@children) {
		push(@desc, $_->get_descendents($order));
	}
	push(@desc, $self);
	return @desc;
}


=head2 function get_parent()

  Synopsis:	my $p=$n->get_parent();
  Arguments:	none
  Returns:	a Node object that is the parent of $n, 
                undef if $n is the root node
  Side effects:	
  Description:	

=cut

sub get_parent { 
	my $self=shift;
	return $self->{parent};
}

=head2 function set_parent()

  Synopsis:	$n->set_parent($p)
  Arguments:	a Node object that will be the parent of $n.
  Returns:	nothing
  Side effects:	$p will be considered the parent of $n.
  Description:	

=cut

sub set_parent { 
	my $self=shift;
	$self->{parent}=shift;
}

=head2 function get_all_parents()

  Synopsis:	my $parent_nodes = $node->get_all_parents();
  Arguments:	none
  Returns:      a list of parent nodes in order as seen from the node 
                $node, including the root node.
  Side effects:	none
  Description:	

=cut

sub get_all_parents { 
	my $self = shift;
	my @parents = ();
	my $p = $self;

	# get all parents, including the root node (i.e. parent, parent's 
        #  parent, etc. up to root)
	#
	while (!$p->is_root()) { 

		$p = $p->get_parent();

		push @parents, $p;

	}
	return @parents;
}

=head2 function splice()

  Synopsis:	$node->splice($tree)
  Arguments:	a CXGN::Phylo::Tree object
  Returns:	nothing
  Side effects:	replaces the $node object with the root of the given tree,
                and incorporates the subtree into the current tree

=cut

sub splice {
	my $self = shift;
	my $sub_tree = shift;
	my $tree = $self->get_tree();
	
	my @sub_nodes = $sub_tree->get_root()->get_descendents();

	#remove sub_tree root node, since we want it to take this node's key
	#and not be incorporated as a new node to this tree
	my $sub_root = pop @sub_nodes; 

	$tree->incorporate_nodes(@sub_nodes);

	#And now, the splice!
	#The subtree root's attributes are copied to this node, with a few 
	#exceptions (next five lines)
	$sub_root->set_tree($tree);
	$sub_root->set_name($self->get_name);
	$sub_root->set_node_key($self->get_node_key);
	$sub_root->set_parent($self->get_parent);
	$sub_root->set_branch_length($self->get_branch_length);
	$_->set_parent($self) foreach( $sub_root->get_children() );

	while (my ($k, $v) = each %$sub_root) {
		$self->{$k} = $v;
	}
}

sub add_subtree {
	my $self = shift;
	my $subtree = shift;
	my $branch_length = shift;
	$branch_length = 0 unless defined $branch_length;
	$self->get_tree()->incorporate_tree($subtree);
	$self->add_child_node($subtree->get_root());	
	$subtree->get_root()->set_branch_length($branch_length)
}


=head2 function get_species()

  Synopsis:	my $species = $node->get_species();
  Arguments:	none
  Returns:	the species of this node (set using set_species). The 
                returned value may be a standardized form of the value 
                set with set_species (if the tree's 
                show_standard_species is true)
  Side effects:	none
  Description:
  See also:     get_standard_species, get_shown_species

=cut

sub get_species {
	my $self=shift;
	return $self->{species};
}

=head2 function get_standard_species()

  Synopsis:    my $species = $node->get_standard_species();
  Arguments:   none
  Returns:     The standardized form of the species name.
  Description: This gives the standardized form of the species, which 
               is used in implicit species, which are used in ortholog 
               finding
  See also:    get_standard_species, get_shown_species  
  See also:    CXGN::Phylo::Species_name_map which implements the 
               mapping between species names and their standardized 
               forms. 

=cut

sub get_standard_species {
	my $self=shift;
	my $species = $self->{species};
	my $tree = $self->get_tree();
	if (defined $tree) {
		my $species_standardizer = $tree->get_species_standardizer();
		if (defined $species_standardizer and defined ($species_standardizer->get_standard_name($species)) ) {
			$species = $species_standardizer->get_standard_name($species);
		#	print "species standardizer branch. species: [$species] \n";
		} else {
#	print "species: [$species]\n";
      $species = CXGN::Phylo::Species_name_map->to_standard_format($species, 1); # just e.g.  solanum lycopersicum -> Solanum_lycopersicum
#      print "to_standard_format branch: [$species] \n";
		}
	}
	return $species;
}

=head2 function get_shown_species()

  Synopsis:	my $species = $node->get_shown_species();
  Arguments:	none
  Returns:	The species name as returned by either get_species or 
                get_standard_species, depending on the value returned by the 
                tree's get_show_standard_species() method.

=cut

sub get_shown_species{
	my $self = shift;
# print "in get_shown_species. show_standard_species: {{{", $self->get_tree()->get_show_standard_species, " standard species:[", $self->get_standard_species(), "]  raw species:[", $self->get_species(), "] isleaf:[", $self->is_leaf(), "]}}}\n";
	if ($self->get_tree()->get_show_standard_species) {
#	print STDERR "in get_shown_species. standardized branch. ",  $self->get_tree()->get_show_standard_species," \n";
		return $self->get_standard_species();
	} else {
#		print STDERR "in get_shown_species. raw branch ", $self->get_tree()->get_show_standard_species, "\n";
		return $self->get_species();
	}
}


=head2 function set_species()

  Synopsis:	$species->set_species("Solanum lycopersicum");
  Arguments:	a species name. In order for orthology calculation to 
                work, we need to do recursive_set_implicit_species(), 
                to store implicit species for each node based on the 
                leaf species names.
  Returns:	nothing
  Side effects:	Sets the species attribute to the argument
  Description:	
  See also:     $tree->get_orthologs()

=cut

sub set_species { 
	my $self=shift;
	$self->{species}=shift;
}

=head2 function get_label()

  Synopsis:	 $a_node->get_label()
  Returns:	The nodes label

=cut

sub get_label { 
	my $self=shift;
	return $self->{label};
}

=head2 function set_label()

  Synopsis:	 $a_node->set_label($label)
  Description:	Set the nodes label to $label.

=cut

sub set_label { 
	my $self=shift;
	$self->{label}= shift;
        $self->{label} 
}

=head2 function set_tooltip()

=cut

sub set_tooltip {
	my $self = shift;
	$self->{tooltip} = shift;
}

=head2 function get_tooltip()

=cut

sub get_tooltip {
	my $self = shift;
	return $self->{tooltip};

}

=head2 function set_onmouseout()

  Synopsis:	 $a_node->set_onmouseout($javascript)
  Description:	Set the nodes onmouseout javascript code to $javascript.

=cut

sub set_onmouseout{
    my $self=shift;
    $self->{onmouseout}=shift;
}

=head2 function get_onmouseout()

  Synopsis:	 $a_node->get_onmouseout()
  Returns:      Javascript code that will occur onmouseout.

=cut

sub get_onmouseout{
    my $self=shift;
    return $self->{onmouseout};
}

=head2 function set_onmouseover()

  Synopsis:	 $a_node->onmouseover($javascript)
  Description:	Sets the onMouseOver code to be $javascript.

=cut

sub set_onmouseover{
    my $self=shift;
    my $script=shift;
    $self->{onmouseover}=$script;
}

=head2 function get_onmouseover()

  Synopsis:	 $a_node->get_onmouseover()
  Description:	Returns the javascript code for onmouseover for this node.

=cut

sub get_onmouseover{
    my $self= shift;
  
    return $self->{onmouseover};
}

=head2 function get_branch_length()

  Synopsis:	 $a_node->get_branch_length()
  Returns:	The branch length, or if the tree's 

=cut

sub get_branch_length { 
	my $self=shift;
	if (!exists($self->{branch_length})) { $self->{branch_length}= $self->get_tree()->get_min_branch_length();	}
	return $self->{branch_length};
}

=head2 function set_branch_length()

  Synopsis:	 $a_node->set_branch_length($bl)
  Description:	 Sets the node's branch length to $bl.

=cut

sub set_branch_length { 
	my $self=shift;
	$self->{branch_length}=shift;
}

=head2 function get_transformed_branch_length()

  Synopsis:	$a_node->get_transformed_branch_length($bltype, $addbl)
  Arguments:	First argument is one of "equal", "branch_length", 
                "proportion_different". 
  Returns:	Some function of the branch length, depending on the 1st 
                argument, of if no arguments, then on (???) 
  Side effects:	
  Description:	

=cut

sub get_transformed_branch_length { 
	my $self=shift;
	my $bltype = shift;
	return 0.0 if($self->is_root());
	$bltype ||= $self->get_tree()->get_shown_branch_length();  #"branch_length";
	my $addbl = shift; $addbl ||= $self->get_tree()->get_min_shown_branch_length();
	if (!exists($self->{branch_length})) {
		$self->{branch_length}= $self->get_tree()->get_min_branch_length();
	}

	if ($bltype eq "branch_length") {
		return ($addbl + $self->{branch_length});
	} elsif ($bltype eq "equal") {
		return 1.0;
	} elsif ($bltype eq "proportion_different") {
		return ($addbl + 0.75*(1.0 - exp(-4.0*($self->{branch_length})/3.0)));
	} elsif ($bltype eq "square_root") {
		return ($addbl + ($self->{branch_length})**0.5);
	} else {
		return $self->{branch_length};
	}
}


=head2 function is_root()

  Synopsis:	$rootflag = $node->is_root();
  Arguments:	none
  Returns:	true if the node is a root node, false if not.
  Side effects:	none
  Description:	 If node has no parent, returns true

=cut

sub is_root {
	my $self = shift;
	if (!$self->get_parent()) {
		return 1;
	}
	return 0;
}

=head2 function get_tree()

  Synopsis:	 $a_node->get_tree()
  Returns:	the tree object this node belongs to.
  Description:	every node belongs to a tree object. The tree objects
                keeps track of the keys for each node, which must be unique.

=cut

sub get_tree { 
	my $self=shift;
	return $self->{tree};
}

=head2 function set_tree()

  Synopsis:	 $a_node->set_tree($a_tree)
  Arguments:	 One argument, a tree object.
  Description:	 Set the tree node belongs to to be $a_tree

=cut

sub set_tree { 
	my $self=shift;
	$self->{tree}=shift;
}

=head2 function is_leaf()

  Synopsis:	my $leaf_flat = $node->is_leaf();
  Returns:	true if $node is a leaf, false if it is not.

=cut

sub is_leaf {
	my $self = shift;
	if ($self->get_children()) {
		return 0;
	}
	return 1;
}

=head2 function get_hidden() and is_hidden()

  Synopsis:	my $flag = $node->get_hidden();
  Arguments:	none
  Returns:	true if the node is hidden, 
                false if the node is shown.
  Side effects:	
  Description:	see set_hidden()
                get_hidden() is equivalent to is_hidden()

=cut

sub get_hidden {
	my $self=shift;	
	return $self->{hidden};
}

sub is_hidden { 	
	my $self=shift;
	return $self->get_hidden();
}


=head2 function set_hidden()

  Synopsis:	$node->set_hidden(1);
  Arguments:	a true or a false value
  Returns:	nothing
  Side effects:	the node is being marked as being hidden,
                ie, it won\'t be drawn if get_hidden() returns
                a true value. 
  Description:	if a node is being marked as hidden, all nodes
                beneath it will also be hidden. This propagation
                is implemented by recursive_propagate_properties().
  See also:     recursive_propagate_properties()

=cut

sub set_hidden { 
	my $self=shift;
	$self->{hidden}=shift;
}

=head2 function recursive_propagate_properties()

  Synopsis:	$root->recursive_propagate_properties('hidden');
  Arguments:	A list of properties to be propagated. e.g.
'hidden', but if no list given then hidden and hilited are propagated.
  Returns:	
  Side effects:	
  Description:	recursively propagates certain attributes to the
                children nodes.
                currently, the default propagated properties are:
                hidden, hilited

=cut

sub recursive_propagate_properties { 
	my $self = shift;
    
	my $hidden = $self->get_hidden();
	my $hilited = $self->get_hilited();
   
	my @properties = @_; 
	unless (@properties){ @properties = ('hidden', 'hilited') } 
 # print STDERR "X [", scalar @properties, "] ", join("; ", @properties), "\n";
	my @children = $self->get_children();
	foreach my $c (@children) {
		foreach my $prop (@properties){

			if (($prop eq 'hidden') and $hidden) {
			$c->set_hidden($hidden);
			}elsif (($prop eq 'hilited') and $hilited) {
				print STDERR "In rec.propagate_properties.: ", $c->get_name(), " being set hilited\n";
			$c->set_hilited($hilited);
			}elsif(defined $self->get_attribute($prop)){
				$c->set_attribute($prop, $self->get_attribute($prop));		
		}
		}
#	print STDERR "Y [", scalar @properties, "] ", join("; ", @properties), "\n";
		$c->recursive_propagate_properties(@properties);
	}
}

sub recursive_clear_properties { 
	my $self = shift;
    
	$self->set_hidden(0);
	$self->set_hilited(0);
    
	my @children = $self->get_children();
	foreach my $c (@children) { 
		$c -> recursive_clear_properties();
	}
}

=head2 accessors get_hilited(), set_hilited()

  Synopsis:	$hilite_flag = $node->get_hilited();
  Arguments:	none
  Returns:	true if node is highlighted, false if not.
  Side effects:	hilited nodes are rendered differently 
  Description:	
  See also:     set_hilite_color();

=cut

sub get_hilited { 
	my $self=shift;
	if (!defined($self->{hilited})) { 
	    $self->{hilited}="";
	}
	return $self->{hilited};
}

sub set_hilited { 
	my $self=shift;
	$self->{hilited}=shift;
}

=head2 accessors get_hide_label(), set_hide_label()

  Synopsis:	$n->set_hide_label(1);
  Property:	a boolean value representing the hide state of the label
  Side effects:	labels with a true value will not be drawn.
  Description:	

=cut

sub get_hide_label { 
	my $self=shift;
	return $self->get_label()->is_hidden();
}

sub set_hide_label { 
	my $self=shift;
	$self->get_label()->set_hidden(1);
}

=head2 accessors get_line_color(), set_line_color()

 Usage:        $node->set_line_color(255, 0, 0);
 Property:     the line color
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub get_line_color {
	my $self = shift;
	return @{$self->{line_color}};
}

sub set_line_color {
	my $self = shift;
	my @color = shift;
	return unless (@color==3);
	foreach (@color) {
		return unless ($_ >= 0 && $_ <= 255);
	}
	@{$self->{line_color}} = @color;
}

=head2 function get_name()

  Synopsis:	my $name_string = $a_node->get_name()
  Returns:	The string stored in the nodes name

=cut

sub get_name { 
	my $self=shift;
	return $self->{name};
}

=head2 function set_name()

  Synopsis:	$n->set_name("At1g01010");
  Arguments:	a name for the node
  Side effects:	The node's label also gets its name set here - Nope now 
                in update_label_names (?). The species is also 
                incorporated into the label name, if the tree's 
                show_species_in_label is true. 
                (Where?)
                CXGN::Phylo::Node::search searches the name property.
  Description:	

=cut

sub set_name { 
	my $self=shift;
	$self->{name}=shift;
#	$self->get_label()->set_name($self->{name});
}
=head2 function wrap_tooltip(){

  Synopsis:	$n->wrap_tooltip("At1g01010");
  Arguments:	text/variable to wrap in tooltip, tooltip itself
  Side effects:	NOT SURE YET. NEED TO TEST 
                CXGN::Phylo::Node::search searches the name property.
  Description:	//TODO//

=cut

sub wrap_tooltip { 
	my $self=shift;
	my $tooltip = shift;
	$self->{name}=shift;
        my $wrappedobj = tooltipped_text($self->{name},$tooltip);
        return $wrappedobj;
}

=head2 accessors get_link(), set_link()

  Synopsis:	my $url = $n->get_link();
  Property:     the url to link to when clicking on the label for this 
                node
  Side effects:	get_html_image_map() will include the url for linking on
                images embedded in html pages.
  Description:	

=cut

sub get_link { 
	my $self=shift;
	return $self->{link};
}

sub set_link { 
	my $self=shift;
	$self->{link}=shift;
}

=head2 accessors get_horizontal_coord(), set_horizontal_coord()

  Synopsis:	
  Property:     the horizontal offset of the node on the image object, in 
                pixels
  Side effects:	
  Description:	
  Synonym:      get_X()

=cut

sub get_horizontal_coord { 
	my $self=shift;
	return int($self->{horizontal_coord});
}

sub get_X { 
	my $self=shift;
	return $self->{horizontal_coord};
}

sub set_horizontal_coord { 
	my $self=shift;
	$self->{horizontal_coord}=shift;
	$self->get_label()->set_reference_point($self->{horizontal_coord}, $self->get_Y());
}

sub set_X { 
	my $self = shift;
	$self->set_horizontal_coord(shift);
}

=head2 accessors get_vertical_coord(), set_vertical_coord()

  Synopsis:	
  Property:     the vertical offset of the node in the image, in pixels.
  Side effects:	
  Description:	
  Synonyms:     get_Y(), set_Y()

=cut

sub get_vertical_coord { 
	my $self=shift;
	if (!$self->{vertical_coord}) {
		$self->{vertical_coord}=0;
	}
	return int($self->{vertical_coord});
}

sub get_Y { 
	my $self = shift;
#my $Y = $self->get_vertical_coord();
#return sqrt($Y);
	return $self->get_vertical_coord();
}

sub set_vertical_coord { 
	my $self=shift;
	$self->{vertical_coord}=shift;
	$self->get_label()->set_reference_point($self->get_X(), $self->{vertical_coord});
}

sub set_Y { 
	my $self=shift;
	$self->set_vertical_coord(shift);

}

=head2 function get_node_key()

  Synopsis:	my $key = $node->get_node_key()
  Arguments:	none
  Returns:	the key of the node, which should uniquely
                identify a node.
  Side effects:	
  Description:	

=cut

sub get_node_key { 
	my $self=shift;
	return $self->{node_key};
}

=head2 function set_node_key()

  Synopsis:	$node -> set_node_key($i++);
  Arguments:	a unique key for each node, used to identify the
                nodes
  Returns:	nothing
  Side effects:	sets the node_key property.  
  Description:	
  See also:     the Tree object implements the get_unique_node_key() 
                function that assures a unique key per tree. 

=cut

sub set_node_key { 
	my $self=shift;
	$self->{node_key}=shift;
}


=head2 function get_dist_from_root()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_dist_from_root { 
	my $self=shift;
	return $self->{dist_from_root};
}

=head2 function set_dist_from_root()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_dist_from_root { 
	my $self=shift;
	$self->{dist_from_root}=shift;
}

=head2 function set_subtree_distance()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

=head2 function calculate_distances_from_root()

  Synopsis:	$node->calculate_distances_from_root
  Arguments:	none
  Returns:	the distance of this node all the way up to the root.
  Side effects:	sets the subtree_distance property in each node
  Description:  This function needs to be called before calling
                $node->get_subtree_distance(), because it initializes
                the subtree_distance property in all nodes. The values
                are used for scaling the tree.

=cut

sub calculate_distances_from_root {
	my $self=shift;
	my $dist = shift; $dist ||= 0.0;
	my $dist_type = shift;
$dist_type ||= $self->get_tree()->get_shown_branch_length_transformation();  #{shown_branch_length}; 
	my $node_dist = $self->get_transformed_branch_length($dist_type);
	$dist += $node_dist;

	$self->set_dist_from_root($dist);
	if ($self->get_hidden()) {
		return $dist;
	}
	# if the node is hidden, don't go through the children.
	#
	my @children = $self->get_children();
	foreach my $c (@children) {
		my $sub_dist = $c->calculate_distances_from_root($dist, $dist_type);
	}
	return $dist;
}

=head2 function rotate_node()

 Synopsis:	$node->rotate_node();
 Arguments:	none
 Returns:	nothing
 Side effects:	Rotates the node 180 degrees. The formerly topmost child 
                node will be the lowest child node and vice versa. 
 Description:	

=cut

sub rotate_node {
	my $self = shift;
	my @children = $self->get_children();

	#print STDERR "Rotating node...\n";
	my @reverse_children = reverse(@children);

	$self->set_children(@reverse_children);
}

sub recursive_text_render { 
	my $self = shift;
	my $offset = shift;
	if (!$offset) {
		$offset=0;
	}
	for (my $i=0; $i<$offset; $i++) {
		print STDERR "-";
	}
	my $hidden = "";
	my $hilited = "";
 
	$self->print();

	my @children = $self->get_children();

	foreach my $c (@children) { 
		$c->recursive_text_render($offset+1);
	}
}

sub print {
	my $self = shift;
	my $hidden = "";
	my $hilited = "";
	if ($self->get_hidden()) {
		$hidden = "HIDDEN";
	}
	if ($self->get_hilited()) {
		$hilited = "HILITED";
	}
	if ($self->is_root()) {
		print STDERR "*";
	}
	print STDERR $self->get_name()." key=".$self->get_node_key()." (".$self->get_horizontal_coord().", ". $self->get_vertical_coord().") [$hidden] [$hilited] [".$self->get_subtree_node_count()."] species: ".$self->get_species()." link: ".$self->get_link()." [".$self->get_attribute("leaf_species_count")."] blen =".$self->get_branch_length();
	if ($self->get_parent() ne undef) {
		print "  parent name: \'", $self->get_parent()->get_name(),  "\'\n";
	} else {
		print "\n";
	}
}

=head2 function recursive_leaf_list()

  Synopsis:	my @leaves = $node->recursive_leaf_list()
  Arguments:	
  Returns:	a list of leaf nodes @leaves that are below the node $node.
  Side effects:	none
  Description:	

=cut

sub recursive_leaf_list { 
    my $self = shift;
    my @leaf_list = @_;

    # test if the current node is a leaf, or is hidden (in which
    # case it is treated similarly to a leaf) and if true, add it
    # to the leaf list array.
    #
    if ($self->is_leaf() || $self->get_hidden()) { 
			push @leaf_list, $self;
			return @leaf_list;
    }
    my @children = $self->get_children();
    foreach my $c (@children) { 
			my @children_leaf_list = $c->recursive_leaf_list();
			@leaf_list = (@leaf_list, @children_leaf_list);
    }
    return @leaf_list;
}


=head2 function get_subtree_node_count()

  Synopsis:	 $my $n_nodes = $a_node->get_subtree_node_count();
  Arguments:	 none
  Returns:	number of nodes in subtree
  Side effects:	 none
  Description:	

=cut

sub get_subtree_node_count { 
	my $self=shift;
	return $self->{subtree_node_count};
}

=head2 function set_subtree_node_count()

  Synopsis:	 $a_node->get_subtree_node_count($count);
  Arguments:	 an integer, the subtree node count
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_subtree_node_count { 
	my $self=shift;
	$self->{subtree_node_count}=shift;
}


=head2 function get_leaf_species_count()

  Synopsis:	 my $count = $a_node->get_leaf_species_count();
  Arguments:	 none
  Returns:	$self->{leaf_species_count}
  Side effects:	 none
  Description:	 just returns stored value. 

=cut

sub get_leaf_species_count { 
	my $self=shift;
	return $self->{leaf_species_count};
}

=head2 function set_leaf_species_count()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_leaf_species_count { 
	my $self=shift;
	$self->{leaf_species_count}=shift;
}


=head2 function get_comp_leaf_species_count()

  Synopsis:	my $count = $a_node->get_comp_leaf_species_count();
  Arguments:	none
  Returns:	$self->{comp_leaf_species_count} the number of species in 
                the leaves of the complement of $a_node's subtree.
  Side effects:	none
  Description:	just returns stored value. 

=cut

sub get_comp_leaf_species_count { 
	my $self=shift;
	return $self->{comp_leaf_species_count};
}

=head2 function set_comp_leaf_species_count()

  Synopsis:	$anode->set_leaf_species_count($count);
  Arguments:	 
  Returns:	
  Side effects:	
  Description:	Set this field, which is the number of species 
                represented in the leaves of the complement of the 
                subtree defined by $anode

=cut

sub set_comp_leaf_species_count { 
	my $self=shift;
	$self->{comp_leaf_species_count}=shift;
}


=head2 function calculate_subtree_node_count()

  Synopsis:	
  Arguments:	
  Returns:	Number of nodes in subtree, excluding this one (so 0 
                for leaves)
  Side effects:	Calls set_subtree_node_count for this node and all 
                nodes in subtree.
  Description:	

=cut

sub calculate_subtree_node_count { 
	my $self = shift;
	my $count = 0;
	foreach my $c ($self->get_children()) {
		$count += $c->calculate_subtree_node_count()+1;
	}
	$self->set_subtree_node_count($count); #each node has a subtree node count which is set here
	return $count;
}


=head2 function collect_orthologs()

  Synopsis:    my $ortho_trees = $a_node->collect_orthologs()
  Arguments:   Optionally a reference to a list of trees; if absent just 
               starts with empty list.
  Returns:     Reference to list of ortholog trees.
  Description: Recursively looks in $a_node's subtree for subtrees with 
               all leaves of distinct species.
  Author:      Tom York (tly2@cornell.edu)
 
=cut

sub collect_orthologs { 
	my $self = shift;
	my $ortho_tree_ref = shift;

	# test if subtree contains all orthologs; that's the case when leaf count is equal to leaf species count:
	if ($self->get_attribute("leaf_species_count") == $self->get_attribute("leaf_count")) {			
		my $new_tree = $self->copy_subtree(); 
		push @$ortho_tree_ref, $new_tree;
		return$ortho_tree_ref;
	} else {											# $self subtree not all orthologs, look in child subtrees
		foreach my $c ($self->get_children()) {
			my$children_ortho_trees_ref = $c->collect_orthologs();
			push @$ortho_tree_ref, @$children_ortho_trees_ref;
		}
	}
	return $ortho_tree_ref;
}

=head2 function copy_subtree

  Synopsis:	my $new_tree = $a_node->copy_subtree()
  Arguments:	none.
  Returns:	A new tree object which is a copy of the subtree of 
                $a_node.
  Description:	Returns a new tree which is a copy of the subtree. The 
                tree's fields such as show_species_in_labels, are copied 
                from $a_node's tree.
  Author:       Tom York (tly2@cornell.edu)

=cut

sub copy_subtree{
	my $self = shift;
	my $new_tree = CXGN::Phylo::Tree->new();
	my $orig_tree = $self->get_tree();
	$orig_tree->copy_tree_fields($new_tree); #
	my $new_root = $self->recursive_copy(undef, $new_tree);
	$new_tree->set_root($new_root);
	$new_tree->recalculate_tree_data();
	return $new_tree;
}

=head2 function to_string()

  Synopsis:	
  Arguments:	
  Returns:	a string with a serialization of the node
  Side effects:	
  Description:	

=cut

sub to_string { 
	my $self = shift;
	my $s = "";
	$s = join (" ", ("name:".$self->get_name(), "key:".$self->get_node_key(), "hidden:".$self->get_hidden, "hilited:".$self->get_hilited()));
	if ($self->get_parent()) { 
		$s .= " parent:".$self->get_parent()->get_node_key(); 
	} else { 
		$s .= " parent:[undef]"; 
	}
	$s .="children:".(join "|", (map $_->get_node_key(), $self->get_children() ));
	return $s; 

}

=head2 function recursive_implicit_names()

  Synopsis:	my @name = $anode->recursive_implicit_names();
  Arguments:	none
  Returns:	A list representing the implicit name of $anode, i.e. a sorted 
                list whose elements are the leaf names of the subtree.
  Side effects:	recursively calls itself and calls set_implicit_names and 
                set_name for each node in subtree, 
  Description:	Use to define implicit names from leaf names. 
                get_implicit_names() gives a sorted list of leaf names,
                and set_name() to the string obtained by joining members of 
                that list with tab.
  Author:       Lukas Mueller. (lam87@cornell.edu)

=cut

sub recursive_implicit_names { 
	my $self = shift;
#	print "top of recursive_implicit_names() \n";
	my @name_list = ();
	my @sorted_list = ();
	if ($self->is_leaf()) {
		my $the_name = $self->get_name();
		#print STDERR "in recursive_implicit_names. before: $the_name \n";

		# Is there some standard regarding which characters are/aren't allowed in sequence identifiers?
		if ($the_name =~ /([^{|]+)/) { # Leave just the identifier to go into implicit names; for now trim off everything from the first pipe or { on.
			$the_name = $1;
		}
		push @name_list, $the_name;
		@sorted_list = @name_list;
	} else {

		my @children = $self->get_children();
		foreach my $c (@children) {
			my @child_name_list = $c->recursive_implicit_names();
			@name_list = (@name_list, @child_name_list);
		}
		@sorted_list = sort @name_list;
		$self->set_name(join "\t", @sorted_list); # Do we need this? What else are the internal nodes' names good for?
	}
	$self->set_implicit_names(\@sorted_list);
	#	print "In rec..impl..names. impl names: ", join("\t", @sorted_list), "\n", join("\t",@{$self->get_implicit_names()}), "\n";
#	print STDERR "ZZZZ in rec..imp...names.  subtree size: [", scalar @sorted_list, "]  name:[", $self->get_name(), "]\n";
	return @sorted_list;
}

=head2 function recursive_implicit_species()

  Synopsis:	my @species = $anode->recursive_implicit_species();
  Arguments:	
  Returns:	A list representing the implicit species of $anode, i.e. 
                a sorted list whose elements are the leaf species of the 
                subtree.
  Side effects:	recursively calls itself and calls set_implicit_species 
                and set_name for each node in subtree
  Description:	Use to define implicit species from leaf species. 
                get_implicit_species() gives a sorted list of 
                standardized leaf species names
  Author:       Lukas Mueller. (lam87@cornell.edu)

=cut

sub recursive_implicit_species { 
	my $self = shift;

	my @species_list = ();
	my @children = $self->get_children();
	foreach my $c (@children) {
		my @children_species_list = $c->recursive_implicit_species();
		@species_list = (@species_list, @children_species_list); #species can occur multiple times
	}

	if ($self->is_leaf()) {
		# put species in standard form, push it on the species list.
		push @species_list, $self->get_standard_species();
	}

	my @sorted_list = sort @species_list;

	$self->set_implicit_species(\@sorted_list); # sorted list of species in standard form
	# should we $self->set_species(join("\t",@sorted_list));  here? No
	return @sorted_list;
}

#sets subtree species bit pattern from implicit species recursively for all nodes in subtree.
sub recursive_set_implicit_species_bits{
	my $self = shift;
	my $bithash = shift;					# this gives the bit pattern associated with each species
	my $species_bits = int 0;
	my $implicit_species = $self->get_implicit_species();
	# print "implicit species: ", join(" ", @$implicit_species), "\n";
	my $a = int 0;
	my $b = int 0;
	foreach (@$implicit_species) {
		if (exists $bithash->{$_}) {
			$species_bits |= $bithash->{$_};
		#	print STDERR "impl species: [$_],    [", $bithash->{$_}, "]\n";
		}
	}
	$self->set_attribute("species_bit_pattern", $species_bits);
	foreach ($self->get_children()) {
		$_->recursive_set_implicit_species_bits($bithash);
	}
}


=head2 function recursive_compare()

  Synopsis:	 my $same = $a_node->recursive_compare($another_node)
  Arguments:	 
  Returns:	1 if same, 0 otherwise
  Side effects:	
  Description:	 Compares

=cut

sub recursive_compare { 
	my $self = shift;
	my $you  = shift;
	my $compare_field = shift;		# optional argument to allow choosing to compare species

	my $self_implicit_name;
	my $your_implicit_name;
#	print STDOUT "compare_field: ", $compare_field, "\n";
	if (lc $compare_field eq "species") {
		$self_implicit_name = join "\t", sort( @{$self->get_implicit_species()}); #case sensitive
		$your_implicit_name = join "\t", sort( @{$you->get_implicit_species()});
	} else {											# default; use names
		$self_implicit_name = join "\t", sort( @{$self->get_implicit_names()}); #case sensitive
		$your_implicit_name = join "\t", sort( @{$you->get_implicit_names()});
	}

	#     print STDERR "checking node with implicit name : $self_implicit_name.\n";
	#     print STDERR "comparing to node: $your_implicit_name\n";

	#		print("self/you implicit names :[", ($self_implicit_name), "][", ($your_implicit_name), "]  match?_", 
#						(($self_implicit_name) eq ($your_implicit_name)), "_\n");
	if ( ($self_implicit_name) eq ($your_implicit_name)) { # not case-sensitive ( uc is uppercase )


		my @children = $self->get_children();
		my @your_children = $you->get_children();
		my $identity_count = 0;
		for (my $i=0; $i<@children; $i++) {
						for (my $n=0; $n<@your_children; $n++) { 
								my $identity = $children[$i]->recursive_compare($your_children[$n], $compare_field);
								$identity_count += $identity;
						}
				}
				if ($identity_count < @children) {
						return 0;
				}
		} else {
				return 0;
		}
		return 1;
}

=head2 function get_implicit_names()

  Synopsis:	
  Arguments:	none.
  Returns:	Reference to a list of implicit names, as defined by 
                recursive_implicit_names.
  Side effects:	
  Description:	

=cut

sub get_implicit_names { 
	my $self=shift;
	return $self->{implicit_names};
}

=head2 function set_implicit_names()

  Synopsis:	
  Arguments:	a pointer to an array containing a list of implicit names
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_implicit_names {
	my $self=shift;
	$self->{implicit_names}=shift;
}


=head2 function get_implicit_species()

  Synopsis:	
  Arguments:	none.
  Returns:	Reference to a list of implicit species, as defined by 
                recursive_implicit_species.
  Side effects:	
  Description:	

=cut

sub get_implicit_species { 
	my $self=shift;
	return $self->{implicit_species};
}

=head2 function set_implicit_species()

  Synopsis:	
  Arguments:	a pointer to an array containing a list of implicit 
                species
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_implicit_species {
	my $self=shift;
	$self->{implicit_species}=shift;
}


=head2 function recursive_copy()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut


sub recursive_copy { 
	my $self = shift;
	my $new_parent = shift;
	my $new_tree = shift;

	my $new = $self->copy($new_parent, $new_tree);

	foreach my $c ($self->get_children()) { 
		$c->recursive_copy($new, $new_tree);
	}
	return $new;
}

=head2 function copy()

  Synopsis:	my $node_copy = $a_node->copy($new_parent, $new_tree)
  Arguments:	First arg is a node to be set as the copies parent (or is 
                undef, e.g. for root), and second arg is the tree to 
                which the copied node will belong
  Returns:	A node object
  Description:	

=cut

sub copy { 
	my $self = shift;
	my $new_parent = shift;
	my $new_tree = shift;

	my $new = CXGN::Phylo::Node->new();

	if ($new_parent) {
		$new_parent->add_child_node($new);
	}

	$new->set_name($self->get_name());
	$new->set_tree($new_tree);
	$new->set_species($self->get_species());
	$new->set_label($self->get_label()->copy());
	$new->set_node_key($self->get_node_key());
	$new->set_hidden($self->get_hidden());
	$new->set_hilited($self->get_hilited());
	$new->set_horizontal_coord($self->get_horizontal_coord());
	$new->set_vertical_coord($self->get_vertical_coord());
	$new->set_subtree_node_count($self->get_subtree_node_count());
	$new->set_species($self->get_species());
	$new->set_leaf_species_count($self->get_leaf_species_count);
	$new->set_branch_length($self->get_branch_length());

	$new->set_attribute("leaf_count", $self->get_attribute("leaf_count"));
$new->set_attribute("leaf_species_count", $self->get_attribute("leaf_species_count"));

	return $new;
}

=head2 function recursive_generate_newick("", $make_attribs, $show_root)

Synopsis:	my $newick_string = $tree->get_root()
	->recursive_generate_newick();
Arguments:	first should be undef (this is a Node object that is passed to the function from the inner loop for each recursive child node.
				optional= $make_attribs - boolean. Will call  $self->make_newick_attributes() on the root node.
				(defaults to '1' in Tree->generate_newick() ) 
				optional= $show_root - boolean for printing the root node in the newick string.

				Returns:	a string with a newick representation of the tree
				Side effects:	none
				Description:	

=cut

sub recursive_generate_newick {
my $self = shift;
my $s = shift;
my @children = @{$self->{children}};
if (@children) {
  no warnings 'uninitialized';
  $s.="(";
    foreach my $child (@children) {
$s .= $child->recursive_generate_newick('');
   #   $s = $child->recursive_generate_newick($s); # , 1 ,$show_root);
      $s .= $child->get_name() if($child->is_leaf()); # || $show_root ) ;
      $s .= $child->make_newick_attributes() . ":" . $child->get_branch_length();
      $s .= ",";
    } chop $s;
	$s.=")";
}

# if (0 and $make_attribs ) {

# 	if (!$show_root) { $s = "(" . $s . $self->make_newick_attributes(1); }
# 	else {
# 		no warnings 'uninitialized';
# 		$s = "(" . $s;
# 		$s .= $self->get_name();
# 		$s .= $self->make_newick_attributes(1).":".$self->get_branch_length() || 0 ;
# 	}
# 	$s .=")";
# }

return $s;
}


=head2 function make_newick_attributes()

	Synopsis:	
Arguments:	none
Returns:	a string, representing the tree's shown attributes, and their 
values for this node. e.g. [name=g47788;species=potato]
Side effects:	none
Description:	

=cut

sub make_newick_attributes {
	my $self = shift;
	my $show_all = shift;
	my $string = "";
#	print "In Node::make_newick_attributes. ", join("; ", $self->get_tree()->newick_shown_attributes() ), "\n";
	
foreach my $attr ( $self->get_tree()->newick_shown_attributes() ) {
	#  print "in make_newick_attributes. attribute: $attr\n";
		my $value = "";
		if ($attr eq "species") { # species shown for leaves, or all nodes if $show_all
			$value = $self->get_shown_species();
		#	print "value: $value\n";
			if ($self->is_leaf() || $show_all ) {
				$string .= "$attr=$value;" # don't show attribute if value is 0
			}
		} else { # other attributes shown for all nodes (except speciation not shown for leaves)
			$value = $self->get_attribute($attr);
#	print("in make_newick_attributes. newick_shown_attributes: ", $attr, "  value: ", $value, "\n");
			$string .= "$attr=$value;" unless($self->is_leaf() && ($attr eq "speciation")); # don't show speciation attr for leaves
		}
#	  print "attribute string: $string \n";

	}
	if ($string) {
		chop($string); return ("[" . $string . "]");
	}
	return "";
}



=head2 function generate_nex()

	Recursively generate a newick from the current node, and then
	return the text of a hypothetical nex file describing the 
	tree and numeric translations for the leaves.

=cut

sub generate_nex {
  my $self = shift;
  my $treename = shift;	
  $treename ||= "Node_" . $self->get_node_key();

  my @desc = $self->get_descendents();
  my @leaves = $self->recursive_leaf_list();

  my $newick = $self->recursive_generate_newick();
  $newick =~ s/;$//;

  my %translate = ();

  my $output = "#NEXUS\nBegin trees;\n\ttranslate\n";
  for (my $i = 0; $i < @leaves; $i++) {
    my $j = $i + 1;
    my $name = $leaves[$i]->get_name();
    $translate{$j} = $name;
    $output .= "\t\t$j $name";
    $output .= "," if $j < @leaves;
    $output .= "\n";
  }
  $output .= "\t\t;\n";

  while (my ($num, $id) = each %translate) {
    $newick =~ s/\Q$id\E/$num/;	
  }

  $output .= "tree $treename = $newick;\nEnd;";
  return $output;
}

=head2 function write_nex()

	Given a filehandle OR filepath, writes a nex file containing
	a subtree from the current node.

	Ex:  $node->write_nex(\*FH);  #appends to file specified by handle
	or $node->write_nex($path_to_file); #overwrites/creates file in path

	=cut

	sub write_nex {
		my $self = shift;
		my $file = shift;
		my $nex_text = $self->generate_nex(@_);
		if (ref($file) eq "GLOB") {
			print $file $nex_text or die $!;
		} else {
			open(WF, ">$file") or die $!;
			print WF $nex_text;
			close WF;
		}
	}


=head2 function recursive_collapse_single_nodes()

Synopsis:	$tree->get_root()->recursive_collapse_single_nodes()
	Arguments:	none
	Returns:	nothing
	Side effects:	collapses nodes that have only one child into one
	node. The names and other node properties from the 
	child node are propagated to the parent node, whose
	information is lost. The collapsed node keeps its 
	original node_key.
	Description:	
Authors:      Lukas Mueller (lam87@cornell.edu), 
	Tom York (tly2@cornell.edu)

=cut

sub recursive_collapse_single_nodes { 
		my $self = shift;
		my @children = $self->get_children();

		if (@children==1) {						# delete the node with only 1 child 
			if ($self->is_root()) {			# special delete node for case of node being root with just 1 child
				my $the_tree = $self->get_tree();
				$the_tree->set_root($children[0]); # in order to delete $self if it is root, first set its only child to be root
					$self->set_children(undef);
				$self->set_parent(undef);
				$self->set_label(undef);
				$self = undef;	
				$the_tree->recalculate_tree_data();
			} else {
				$self->get_tree()->del_node($self);
			}
		}

		foreach my $c (@children) { 
			$c->recursive_collapse_single_nodes();
		}	
	}

=head2 function recursive_collapse_zero_branches()

  Synopsis:	$t->get_root()->recursive_collapse_zero_branches()
  Arguments:	none
  Returns:	nothing
  Side effects:	deletes the nodes that have zero branch length
  Description:	

=cut

sub recursive_collapse_zero_branches { 
  my $self = shift;

  #    print STDERR "recursive_collapse_zero_branches: checking children of node ".$self->get_name()."\n";

  # collapse the node if its branch length is zero,
  # but don't do it if the node is the root.
  #
  foreach my $c ($self->get_children()) { 
	
    if ($c->get_branch_length()==0) {

      # if the branch length of $c is zero, we will delete the
      # node, the function delete_node should take care of most of 
      # the intricacies of removing our favorite node here...
      # (we want the children of $c to become children of the parent,
      # that's what delete_node should do).
      # $c may be a leaf node. We want to percolate some of it's information
      # to the parent before deleting, such as species information.
      #
      $self->set_species($c->get_species());
      $self->set_link($c->get_link());

      # now it's safe to delete the node
      #
      #   $c->get_tree()->delete_node($c->get_node_key());
      $c->get_tree()->del_node($c);


      # we have to call this function again on this same node, 
      # because this node may have acquired the children from $c.
      #
      $self->recursive_collapse_zero_branches();
    } else { 
	    
      # if the branch length is not zero, descend more...
      #
      $c->recursive_collapse_zero_branches();
    }
  }
	
  #     my @children = $self->get_children();
  #     foreach my $c (@children) { 
  # 	$c->recursive_collapse_zero_branches();
  #     }
    
}

=pod

_recursive_longest_branch_node returns a Node object representing the node with the longest branch in the tree. It is called by the tree function retrieve_longest_branch_node().

=cut

sub _recursive_longest_branch_node { 
  my $self = shift;
  my $largest_branch_node = shift;
  foreach my $c ($self->get_children()) { 
    my $c_branch = $c->get_branch_length();
    if ( $c_branch > ($largest_branch_node->get_branch_length())) { 
      $largest_branch_node = $c;
    }
    $largest_branch_node = $c -> _recursive_longest_branch_node($largest_branch_node);
  }
  return $largest_branch_node;
}

=head2 function recursive_collapse_unique_species_subtrees()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	If subtree contains only one species, it is collapsed 
                into a single node. Labels are concatenated.

=cut

sub recursive_collapse_unique_species_subtrees {
  my $self = shift;
  if ($self->is_leaf()) {
    $self->collapse_unique_species_siblings();
    return;
  }
  if (!defined $self->get_attribute("leaf_species_count")) {
    $self->recursive_set_leaf_species_count();
  }

  if ($self->get_attribute("leaf_species_count") == 1) {
    #	print STDERR "node name, leaf_species_count: ", $self->get_name(), "  ", $self->get_attribute("leaf_species_count"), "\n";
    my @sub_nodes = $self->recursive_subtree_node_list();	

    if (0) { # this shouldn't be necessary as name should be the leaf names joined with tabs already (from recursive_implicit_names)
      $self->set_name("");
      my $separator = "\t";
      foreach my $n (@sub_nodes) {			
	if ($n->is_leaf()) {
	  if ($self->get_name() eq "") {
	    $self->set_name($n->get_name());
	  } else {
	    $self->set_name($self->get_name() . $separator . $n->get_name());
	  }
	  #	print STDERR "Setting species of node with name: ", $self->get_name(), "  to: ", $n->get_species(), "\n";
	  #	$self->set_species($n->get_species()) if($self->get_species() eq ""); # get species name from any leaf (all have same species)
	  #	print STDERR "Species name is now: ", $self->get_species(), "\n";
	  #	print STDOUT "in rec...collapse..unique. set species of collapsed subtree to: ", $n->get_species, "\n";
	}			
      }
    }

    $self->set_species("");
    foreach my $n (@sub_nodes) {			
      if ($n->is_leaf()) {
	$self->set_species($n->get_species()) if($self->get_species() eq ""); # get species name from any leaf (all have same species)
      }		
      $self->get_tree()->del_node($n); # unceremoniously delete the subnode
    }
    $self->collapse_unique_species_siblings();
  }
  foreach my $child ($self->get_children()) {
    if (defined $child) {
      $child->recursive_collapse_unique_species_subtrees();
    }
  }
}

=head2 function collapse_unique_species_siblings()

  Synopsis:	 $a_node->collapse_unique_species_siblings();
  Arguments:	 none
  Returns:	
  Side effects:	
  Description:	 If node is leaf, delete siblings with same species and 
                 smaller key, and join names of deleted sibs to node's 
                 name

=cut

sub collapse_unique_species_siblings {
	my $self = shift;
	#$self->node_info();
	if ($self->is_leaf()) {
		my $parent = $self->get_parent();
	
		if (defined $parent) {
		#	print("parent name: \'", $parent->get_name(), "\'\n");
#			print("self name: ", $self->get_name(), " key: ", $self->get_node_key(), "  species: ", $self->get_species(), "\n");
			my @siblings = $parent->get_children();
			foreach my $sib (@siblings) {
				# if species are same, and sib key < $self key
		#		print("sib name: ", $sib->get_name(), " key: ", $sib->get_node_key(), "  species: ", $sib->get_species(), "\n");
				if (($sib->get_species() eq $self->get_species()) && ($sib->get_node_key() < $self->get_node_key())  ) {

#					print("sibkey: ", $sib->get_node_key(), " sib species: ", $sib->get_species(), 
#								" selfkey: ", $self->get_node_key(), " self species: ", $self->get_species(), "\n");
					$self->set_name($self->get_name()."|".$sib->get_name()); #$self gets sibs name joined to its name 
					#	$self->get_tree()->delete_node($sib->get_node_key()); #delete sib
					$self->get_tree()->del_node($sib); 
					#@siblings = $self->get_parent()->get_children();
				}
				return;
			}
		}
	}
}

=head2 function node_info()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub node_info {
	my $self = shift;
	print "__ NODE " . $self->get_node_key() . " __\n";
	print "Name: " . $self->get_name() . "\n";
	print "Species: " . $self->get_species() . "\n";
	if ($self->get_parent() ne undef) {
		print "Parent Num: " . $self->get_parent()->get_node_key() . "\n";
	} else {
		print "NO PARENT\n";
	}
	print "Children Nums: ";
	foreach my $chil ($self->get_children()) {
		print $chil->get_node_key() . ", ";
	}
	print "\n";
	print "Is Leaf: " . $self->is_leaf() . "\n";
	print "Leaf species in subtree: " . $self->get_attribute("leaf_species_count") . "\n";
	print "\n\n";
}

=head2 function recursive_subtree_node_list()

  Synopsis:	my @subnodes = $node->recursive_subtree_node_list();
  Arguments:	none
  Returns:	a list of nodes which are sub-nodes of node $node
  Side effects:	none
  Description:	

=cut

sub recursive_subtree_node_list { 
	my $self = shift;
	my $list_ref = shift;
	foreach my $c ($self->get_children()) {
		push @$list_ref, $c;
		$c->recursive_subtree_node_list($list_ref);
	}
	return @$list_ref;
}

=head2 function get_attribute()

  Synopsis:	my $foo = $node->get_attribute("foo");
  Arguments:	the name of the attribute
  Returns:	the value of the attribute named foo.
  Side effects:	none
  Description:	used for temporary storage of information relating to a 
                node.

=cut

sub get_attribute { 
	my $self=shift;
	my $name = shift;
	return $self->{attribute}->{$name};
}

=head2 function set_attribute()

  Synopsis:	$node->set_attribute("foo", "bar");
  Arguments:	the name of the attribute and the value of the attribute
  Returns:	nothing
  Side effects:	stores the value of the attribute named foo 
  Description:	

=cut

sub set_attribute { 
	my $self=shift;
	my $name = shift;
	$self->{attribute}{$name}=shift;
}

=head2 function delete_attribute()

  Synopsis:	$node->delete_attribute("foo");
  Arguments:	the name of the attribute
  Returns:	nothing
  Side effects:	removes the attribute named foo and its value
  Description:	

=cut

sub delete_attribute { 
	my $self = shift;
	my $name = shift;
	delete($self->{attribute}->{$name});
}





=head2 function  recursive_set_leaf_count()

  Synopsis:	my $leaf_count = recursive_set_leaf_count($a_node);
  Arguments:	ref to node object.
  Returns:	the number of leaves in subtree, including this node, 
                i.e. it is 1 for leaves.
  Side effects:	sets the leaf_count attribute in each node of the 
                subtree.
  Description:	
  See also:     $tree->get_orthologs()

=cut

sub recursive_set_leaf_count{
	my $self = shift;
	my $leaf_count = 0;
	my @children = $self->get_children();
	if (@children) {
		foreach my $n (@children) {
			$leaf_count += recursive_set_leaf_count($n);
		}		
	} else {	
		$leaf_count = 1;
	}
	$self->set_attribute("leaf_count", $leaf_count);
	#	print("node name: ", $self->get_name(), "  leaf_count: ", $leaf_count);
	return $leaf_count;
}


=head2 function  recursive_set_leaf_species_count()

  Synopsis:	my $leaf_species_hash_ref = $a_node->
                    recursive_set_leaf_species_count();
  Arguments:	Optionally a ref. to a hash with the species and counts 
                for the whole tree.
  Returns:	ref to hash whose keys are leaf species in subtree
  Side effects:	sets the leaf_species_count attribute in each node of 
                the subtree, to number of distinct species in leaves 
                of $a_node, so leaves have leaf_species_count set to 1.
  Description:	
  See also:     $tree->get_orthologs()

=cut

sub recursive_set_leaf_species_count{
	my $self = shift;
	my $root_species_hash_ref = shift; # reference to a hash with species/count pairs for (typically) the root, so can calculate species count for complement
	my $comp_species_hash_ref = {};
	my $species_hash_ref = {};
	my @children = $self->get_children();
	if (@children) {							#non-leaf case
		foreach my $n (@children) {
			my $sub_node_species_hash_ref = $n->recursive_set_leaf_species_count($root_species_hash_ref);
			foreach my $s (keys %$sub_node_species_hash_ref) {
				$species_hash_ref->{$s}++;
			}
		}		
	} else {											# leaf case

# print STDERR "in Node::recursive_set_leaf_species_count, std. species: ", $self->get_standard_species(), "\n";
		$species_hash_ref->{$self->get_standard_species()}++;
	}

# print STDERR "node name, subtree species: ", $self->get_name(), "  ", join(";", keys %$species_hash_ref), "\n";

	$self->set_attribute("leaf_species_count",  scalar(keys %$species_hash_ref));


	if (defined $root_species_hash_ref) {
		foreach (keys %$root_species_hash_ref) {
			my $this_species_leaf_count = (defined $species_hash_ref->{$_})? $species_hash_ref->{$_}: 0; # leaves in subtree w THIS species
			my $this_species_comp_leaf_count = $root_species_hash_ref->{$_} - $this_species_leaf_count; # leaves in rest of tree w THIS species
			if ($this_species_comp_leaf_count > 0) { 
				$comp_species_hash_ref->{$_} = $this_species_comp_leaf_count; 
			} elsif ($this_species_comp_leaf_count < 0) {
				die "In recursive_set_leaf_species_count. Count in complement of subtree is negative. \n";
			}
			#	print "species:  $_  ", $root_species_hash_ref->{$_}, "   ", $this_species_leaf_count, "   ", $comp_species_hash_ref->{$_}, "\n";
		}
		$self->set_attribute("comp_leaf_species_count", scalar(keys %$comp_species_hash_ref));
	}


	return $species_hash_ref;
}

=head2 function recursive_set_min_dist_to_leaf()

  Synopsis:     $min_distance_to_leaf = 
                   recursive_set_min_dist_to_leaf($a_node)
  Arguments:	ref to node object.
  Returns:	The minimum length (sum of branch lengths) of paths 
                from this node to leaves in its subtree
  Side effects:	sets the min_dist_to_leaf attribute in this node and 
                each node of the subtree.
  Description:	Note that this only looks in the subtree. There may 
                be a shorter path to a leaf by sometimes moving toward 
                the root. Use recursive_propagate_mdtl after calling 
                recursive_set_min_dist_to_leaf to get the true min 
                dist to leaf for each node.

=cut

sub recursive_set_min_dist_to_leaf{
	my $self = shift;
	my $min_dist_to_leaf = 1e400; # +infinity, effectively
	$self->set_attribute("near_leaf_path_direction", "both");
	my $near_leaf_path_next_node;	# ref to child through which short path to leaf goes
	my @children = $self->get_children();
#	print("node species, nchildren:  ", $self->get_species(), "  ", scalar(@children), "\n");
	if (@children) {							# non-leaf case	
		my $short_path_child;
		foreach my $c (@children) {				
			$c->recursive_set_min_dist_to_leaf(); # set mdtl attribute in child node (and recursively in whole subtree)
			my $dist_to_leaf_through_child = $c->get_attribute("min_dist_to_leaf") + $c->get_branch_length();			
		#	print("self, child species, min dtltc: ", $self->get_species(), " " , $c->get_species(), "  ", $dist_to_leaf_through_child, "\n");
			if ( $dist_to_leaf_through_child < $min_dist_to_leaf) {
				$min_dist_to_leaf = $dist_to_leaf_through_child;
				$short_path_child = $c;					
			}			
		}
		$short_path_child->set_attribute("near_leaf_path_direction", "down"); # direction of traversal of parent-child branch, on shortest path from parent to leaf
		$self->set_attribute("near_leaf_path_next_node", $short_path_child);
	} else {											# leaf case
		$min_dist_to_leaf = 0;
		# ?? $self->set_attribute("near_leaf_path_next_node", undef)
	}
	$self->set_attribute("min_dist_to_leaf", $min_dist_to_leaf);
}

=head2 function  recursive_propagate_mdtl()

  Synopsis:	my $min_distance_to_leaf = 
                   recursive_propoagate_mdtl($a_node);
  Arguments:	ref to node object.
  Returns:	Nothing.
  Side effects:	sets the min_dist_to_leaf attribute in this node and 
                each node of the subtree.
  Description:	Recursively propagates min distance to leaf (mdtl) 
                through tree, starting with tree which has 
                min_dist_to_leaf attribute set at each node to the 
                min distance through the node's subtree. So the root 
                starts with the correct mdtl since all leaves are in 
                its subtree; we want to propagate that downward through 
                tree so all min_dists_to_leaf values consider distances 
                to all the leaves, not just those in a subtree wrt to 
                particular root.

=cut

sub recursive_propagate_mdtl{
		my $self = shift;
		my $parent= $self->get_parent();
	#	print("node species: ", $self->get_species(), "  mdtl: ", $self->get_attribute("min_dist_to_leaf"), "\n");
		if ($parent) {
				my $mindtl_thru_parent = $parent->get_attribute("min_dist_to_leaf") + $self->get_branch_length();
				if ($mindtl_thru_parent < $self->get_attribute("min_dist_to_leaf")) {
						$self->set_attribute("min_dist_to_leaf", $mindtl_thru_parent);
						$self->set_attribute("near_leaf_path_direction", "up");
						$self->get_attribute("near_leaf_path_next_node")->set_attribute("near_leaf_path_direction", "both");
						$self->set_attribute("near_leaf_path_next_node", $parent);
				}
		}
		my @children = $self->get_children();
		foreach my $c (@children) {
				$c->recursive_propagate_mdtl();
		}
}



# using min_dist_to_leaf and near_leaf_path_direction
# return node s.t. root should be placed along branch to parent node
# should be called for same node as recursive_propagate_mdtl


=head2 function  recursive_find_point_furthest_from_leaves()

  Synopsis:     ($out_node, $dist) = 
                   (recursive_find_point_furthest_from_leaves($in_node)
  Arguments:	ref to node object defining the subtree within which 
                this subroutine will work.
  Returns:	A list of a node and a distance. The point furthest 
                from leaves will lie between $out_node and its parent,  
                and its distance from leaves is $dist.
  Side effects:	None.
  Description:	Subroutines recursive_set_min_dist_to_leaf and 
                recursive_propagate_mdtl should have been called 
                already, to set attributes min_dist_to_leaf, 
                near_leaf_path_direction, and near_leaf_path_next_node. 
                Nodes with near_leaf_path_direction eq "both" may have 
                (a long the branch to the parent) a local maximum of 
                the distance to leaves.
                So check all such branches and return the global 
                maximizing point, specified as the node below the 
                branch, and the distance of that point from the 
                nearest leaf.

=cut

sub recursive_find_point_furthest_from_leaves{
		my $self = shift;
		my $parent_direction = $self->get_attribute("near_leaf_path_direction");
		my $p_mdtl = $self->get_attribute("min_dist_to_leaf");
		my @subtree_best_info = (undef,  0.0); # list of node, and min dist to leaf from any point between node and parent
		foreach my $c ($self->get_children) {
				my @both_branch_best_info;
				if ($c->get_attribute("near_leaf_path_direction") eq "both") { 
						my $c_mdtl = $c->get_attribute("min_dist_to_leaf");
						my $cp_dist = $c->get_branch_length();
						my $cp_mdtl = 0.5*($p_mdtl + $c_mdtl + $cp_dist); # distance above child node is $cp_mdtl - $c_mdtl;
						@both_branch_best_info = ($c, $cp_mdtl);
				}
				my @child_subtree_best_info = $c->recursive_find_point_furthest_from_leaves();
				
				if ($both_branch_best_info[1] > $child_subtree_best_info[1]) {
						@child_subtree_best_info = @both_branch_best_info;
				}
				if ($child_subtree_best_info[1] > $subtree_best_info[1]) {
						@subtree_best_info = @child_subtree_best_info ;
				}
		}
		return @subtree_best_info;
}
																			

=head2 function  recursive_set_max_dist_to_leaf_in_subtree()

  Synopsis:	my $max_leaf_leaf_pathlength_through_node_in_subtree = 
                   recursive_set_min_dist_to_leaf_in_subtree($a_node);
  Arguments:	ref to node object.
  Returns:      The maximum length of leaf to leaf paths through this 
                node which lie entirely in this subtree (i.e. it can't 
                visit parent) and which traverse each branch at most 
                once (can't double back).
  Side effects:	sets the attributes dist_to_leaf_longest,  
                dist_to_leaf_next_longest,  and  lptl_child for this 
                node (and, recursively, its child nodes). 
                dist_to_leaf_longest   is the length of longest path 
                downward throught the tree to a leaf. 
                dist_to_leaf_next_longest is the 
                length of next longest path, considering only first 
                moving to any of the children, and then taking longest 
                path downward through the tree to a leaf. (The second  
                longest path could start by going to same child as the 
                longest, but that is excluded here, because we are 
                interested in finding the longest leaf to leaf path by 
                putting together the longest and next_longest, and no 
                doubling back is allowed.)
                lptl_child  is the child node object which lies on the
                longest path downward throught the tree to a leaf.
  Description:	The idea here is to find for each node the length of 
                the longest path lying in the node's subtree which 
                starts at a leaf, goes up through the subtree to the 
                node, then back down (no doubling back allowed) to a 
                leaf. If we call this for es a tree's root node (and 
                for any choice of root), then the longest leaf to leaf
                path will necessarily have been found by this procedure 
                and we will have its length. We just need to look at 
                all the (...???)

=cut

sub recursive_set_max_dist_to_leaf_in_subtree{
		my $self = shift;
		# each node will have attributes dist_to_leaf_longest, dist_to_leaf_next_longest, lptl_child

		my $dist_to_leaf_longest = 0.0;
		my $dist_to_leaf_next_longest = 0.0;
		my @children = $self->get_children();
		if (@children) {
				foreach my $c (@children) {
						$c->recursive_set_max_dist_to_leaf_in_subtree();
						my $dtll_child = $c->get_attribute("dist_to_leaf_longest") + $c->get_branch_length();
						if ($dtll_child > $dist_to_leaf_longest) {
								$dist_to_leaf_next_longest = $dist_to_leaf_longest;
								$dist_to_leaf_longest = $dtll_child;
								$self->set_attribute("lptl_child", $c);
						} elsif ($dtll_child > $dist_to_leaf_next_longest) {
								$dist_to_leaf_next_longest = $dtll_child;
						}
				}
		}
		$self->set_attribute("dist_to_leaf_longest", $dist_to_leaf_longest); 
		$self->set_attribute("dist_to_leaf_next_longest", $dist_to_leaf_next_longest);
#		print("species: ", $self->get_species(), "  dtllongest: ", 	$self->get_attribute("dist_to_leaf_longest"), "\n");
		return $self->get_max_leaf_leaf_pathlength_in_subtree_thru_node();
}

# Returns: The length of longest leaf to leaf path which goes through this node, but no higher in tree
sub get_max_leaf_leaf_pathlength_in_subtree_thru_node{
		my $self = shift;	return $self->get_attribute("dist_to_leaf_longest") + $self->get_attribute("dist_to_leaf_next_longest");
}




=head2 function  recursive_set_dl_dlsqr_sums_down()

  Synopsis:	$anode->recursive_set_dl_dlsqr_sums_down();
  Arguments:	none.
  Returns:	nothing.
  Side effects:	Sets several attributes, n_leaf_down, 
                sum_d_leaf_top_down, etc.  
  Description:	For anode, (and recursively for nodes in its subtree), 
                finds
      1) the number of leaf nodes in the subtree; ( n_leaf_down)
      2) the sum of the distances from $anode to the leaves in its 
         subtree; ( sum_d_leaf_bottom_down )
      3) the sum of the squares of the distances from $anode to the 
         leaves in its subtree; (sum_d_leaf_sqr_bottom_down )
      4) the sum of the distances from $anode's parent downward through 
         $anode to the leaves in $anode's subtree; 
         ( sum_d_leaf_top_down )
      5) the sum of the squares of the distances from $anode's parent 
         downward through $anode to the leaves in $anode's subtree; 
         ( sum_d_leaf_sqr_top_down)
     These are stored in attributes, and together with other attributes
     set in recursive_set_dl_dlsqr_sums_up,
     this information is used in min_leaf_dist_variance_point

  Author:       Tom York (tly2@cornell.edu)

=cut

#set the sum of distances to leaves (in subtree), and sum of their squares
sub recursive_set_dl_dlsqr_sums_down{
		my $self = shift;
		my @children = $self->get_children();
		if (@children) {						#non-leaf case
				my $sum_dl = 0.0;
				my $sum_dlsqr = 0.0;
				my $n_leaves = 0;
				foreach my $c (@children) {
					$c->recursive_set_dl_dlsqr_sums_down();
					my $c_n_leaves = $c->get_attribute("n_leaf_down");
					$sum_dl += $c->get_attribute("sum_d_leaf_top_down");
					$sum_dlsqr += $c->get_attribute("sum_d_leaf_sqr_top_down");
					$n_leaves += $c_n_leaves;
				}
				$self->set_attribute("sum_d_leaf_bottom_down", $sum_dl);
				$self->set_attribute("sum_d_leaf_sqr_bottom_down", $sum_dlsqr);
				$self->set_attribute("n_leaf_down", $n_leaves);
			#	print("in rec...down. node: \n");
#				$self->print_node(); 
#				print("parent defined?: [", defined $self->get_parent(), "]\n");
				if (defined $self->get_parent()) { # adding on branch up to parent
					my $dp = $self->get_branch_length();
					my $psum = $sum_dl + $n_leaves*$dp;
					my $psumsqr = $sum_dlsqr + 2*$dp*$sum_dl + $n_leaves*$dp*$dp;
					$self->set_attribute("sum_d_leaf_top_down", $psum);
					$self->set_attribute("sum_d_leaf_sqr_top_down", $psumsqr);
				}		
			} else {									# leaf case
				$self->set_attribute("sum_d_leaf_bottom_down", 0);
				$self->set_attribute("sum_d_leaf_sqr_bottom_down", 0);
				$self->set_attribute("sum_d_leaf_top_down", $self->get_branch_length);
				$self->set_attribute("sum_d_leaf_sqr_top_down", $self->get_branch_length**2);
				$self->set_attribute("n_leaf_down", 1);
			}
	}

#put in the upward sum of distances to leaves, etc. for children of node

=head2 function  recursive_set_dl_dlsqr_sums_up()

  Synopsis:	$anode->recursive_set_dl_dlsqr_sums_up();
  Arguments:	none.
  Returns:	nothing.
  Side effects:	Sets several attributes, n_leaf_up, sum_d_leaf_top_up, 
                etc.  
  Description:	For $anode, (and recursively for nodes in its subtree), 
                stores various info for the complement, C, of $anode's
                subtree, i.e. the part of the tree not in $anodes 
                subtree. 
      1) the number of leaf nodes in C, the complement of $anode's 
         subtree; ( n_leaf_up)
      2) the sum of the distances from $anode's parent to the leaves 
         in C; ( sum_d_leaf_top_up )
      3) the sum of the squares of the distances from $anode's parent 
         to the leaves in C; ( sum_d_leaf_sqr_top_up)
      4) the sum of the distances from $anode to the leaves in C; 
         ( sum_d_leaf_bottom_up )
      5) the sum of the squares of the distances from $anode to the 
         leaves in C; (sum_d_leaf_sqr_bottom_up )
     These are stored in attributes, and together with other attributes  
     set in recursive_set_dl_dlsqr_sums_down, this information is used 
     in min_leaf_dist_variance_point.

  Author:      Tom York (tly2@cornell.edu)

=cut

sub recursive_set_dl_dlsqr_sums_up{
		my $self = shift;
		my @children = $self->get_children();
		if (@children) {						#non-leaf case
				for (my $i=0; $i < @children; $i++) {
						my $child = shift @children; # shift one child out of @children array
						my $sum_dl = 0.0;
						my $sum_dlsqr = 0.0;
						my $n_leaves = 0;
						if (defined $self->get_parent()) { # branch up to parent
								$sum_dl = $self->get_attribute("sum_d_leaf_bottom_up");
								$sum_dlsqr = $self->get_attribute("sum_d_leaf_sqr_bottom_up");
								$n_leaves = $self->get_attribute("n_leaf_up");
						}
						foreach my $c (@children) { # loop over the other children
								my $c_n_leaves = $c->get_attribute("n_leaf_down");
								$sum_dl += $c->get_attribute("sum_d_leaf_top_down");
								$sum_dlsqr += $c->get_attribute("sum_d_leaf_sqr_top_down");
								$n_leaves += $c_n_leaves;
						}
						$child->set_attribute("sum_d_leaf_top_up", $sum_dl);
						$child->set_attribute("sum_d_leaf_sqr_top_up", $sum_dlsqr);
						$child->set_attribute("n_leaf_up", $n_leaves);
						my $dc = $child->get_branch_length();
						my $csum = $sum_dl + $n_leaves*$dc; # adding on branch from child to self
						my $csumsqr = $sum_dlsqr + 2*$dc*$sum_dl + $n_leaves*$dc*$dc;
						$child->set_attribute("sum_d_leaf_bottom_up", $csum);
						$child->set_attribute("sum_d_leaf_sqr_bottom_up", $csumsqr);
						$child->recursive_set_dl_dlsqr_sums_up();
						push @children, $child; #put the child back into @children array at other end
				}
		}
}

# just delete the attributes used in finding the min leaf dist variance point
sub recursive_delete_dl_dlsqr_attributes{
	my $self = shift;
	$self->delete_attribute("sum_d_leaf_bottom_up");
	$self->delete_attribute("sum_d_leaf_bottom_down");
	$self->delete_attribute("sum_d_leaf_top_up");
	$self->delete_attribute("sum_d_leaf_top_down");
	$self->delete_attribute("sum_d_leaf_sqr_bottom_up");
	$self->delete_attribute("sum_d_leaf_sqr_bottom_down");
	$self->delete_attribute("sum_d_leaf_sqr_top_up");
	$self->delete_attribute("sum_d_leaf_sqr_top_down");
	foreach my $c ($self->get_children()) {
		$c->recursive_delete_dl_dlsqr_attributes();
	}
}

# returns distance above the node of the point which minimizes variance of distances to leaves

=head2 function  min_leaf_dist_variance_point()

  Synopsis:	$anode->min_leaf_dist_variance_point();
  Arguments:	none.
  Returns:	A list ($da, $var). $da is the distance above $anode, 
                which of all points along the branch (from $anode to 
                its parent) minimizes the variance in the distances 
                from the point to the leaves; $var is that minimal 
                variance.
  Side effects:	none.
  Description:	Phylo::Tree::min_leaf_dist_variance_point() calls this 
                for each node to find the tree's overall min variance 
                point.
                This routine can find that the optimum along a branch is
                either at the bottom, ($da = 0), the top 
                ($da = branch length), or somewhere in between (the more 
                interesting case).
  Author:       Tom York (tly2@cornell.edu)

=cut

sub min_leaf_dist_variance_point{
		my $self = shift;
		my $dist_above = 0.0;
		my $dist_var; 
		my $bl = $self->get_branch_length();
		my $nlu = $self->get_attribute("n_leaf_up");
		my $nld = $self->get_attribute("n_leaf_down");
		my $nl = $nlu + $nld;
		my $sum_d_tu = $self->get_attribute("sum_d_leaf_top_up");
		my $sum_d_td = $self->get_attribute("sum_d_leaf_top_down");
		my $sum_d_bu = $self->get_attribute("sum_d_leaf_bottom_up");
		my $sum_d_bd = $self->get_attribute("sum_d_leaf_bottom_down");

		my $sum_dsqr_tu = $self->get_attribute("sum_d_leaf_sqr_top_up");
		my $sum_dsqr_td = $self->get_attribute("sum_d_leaf_sqr_top_down");
		my $sum_dsqr_bu = $self->get_attribute("sum_d_leaf_sqr_bottom_up");
		my $sum_dsqr_bd = $self->get_attribute("sum_d_leaf_sqr_bottom_down");

		my $avg_dist_tu = $sum_d_tu/$nlu;
		my $avg_dist_bd = $sum_d_bd/$nld;
		
		if ($avg_dist_tu  >  $avg_dist_bd + $bl) { # opt at top of branch
				$dist_above = $bl;
				$dist_var = ($sum_dsqr_tu + $sum_dsqr_td - ($sum_d_tu + $sum_d_td)**2/$nl)/$nl;
		} elsif ($avg_dist_bd  >  $avg_dist_tu + $bl) { # opt at bottom of branch
				$dist_above = 0.0;
				$dist_var = ($sum_dsqr_bu + $sum_dsqr_bd - ($sum_d_bu + $sum_d_bd)**2/$nl)/$nl;
		} else {										# optimum is somewhere along the branch (not at its ends)
				$dist_above = 0.5*($avg_dist_tu + $bl - $avg_dist_bd);
				my $var_down = $sum_dsqr_bd/$nld - ($sum_d_bd/$nld)**2;
				my $var_up = $sum_dsqr_tu/$nlu - ($sum_d_tu/$nlu)**2;
				$dist_var = ($var_down*$nld + $var_up*$nlu)/($nld + $nlu);
		}
		return ($dist_above, $dist_var);
}


#sub get_dl_variance{ # variance of distances from a node to leaves in its subtree
#		my $self = shift;
#		my $sum_dl = $self->get_attribute("sum_d_leaf");
#		my $sum_dlsqr = $self->get_attribute("sum_d_leaf_sqr");
#		my $n_leaves =	$self->get_attribute("n_leaf");
#		return ($sum_dlsqr - $sum_dl**2/$n_leaves)/$n_leaves;
#}

# just grab the first leaf you find. i.e look at first child of first child of ... until you get to a leaf, which is returned
sub recursive_get_a_leaf{
		my $self = shift;
		my @children = $self->get_children();
		if (@children) {
				my $achild = shift @children;
				return $achild->recursive_get_a_leaf;
		}
		return $self;
}


=head2 function compare_subtrees

  Synopsis:	$node1->compare_subtrees($node2), or 
                $node1->compare_subtrees($node2, "species");
  Arguments:	A node object, and optionally .
  Returns:	1 if subtrees below $node1 and $node2 are topologically 
                the same when regarded as rooted trees, 0 otherwise.
  Side effects:	None.
  Description:	Copies subtrees into new trees; collapses them, gets 
                implicit names, then recursively compares trees using 
                implicit names. If the second argument is "species", 
                then gets implicit species, and compares using them.

=cut

sub compare_subtrees{
	my $self = shift;
	my $other_node = shift;
	my $compare_field = shift; # optional argument to allow comparing by species

# print STDOUT "in compare_subtrees. compare_field: $compare_field \n";
	# copy the subtrees into temporary trees, which can 
	# be manipulated (in this case collapsed) without changing the original trees.
	#
	my $tree1 = $self->copy_subtree();
	my $tree2 = $other_node->copy_subtree();

	$tree1->collapse_tree();
	$tree2->collapse_tree();

	my $root1 = $tree1->get_root();
	my $root2 = $tree2->get_root();

	# get the implicit names for each node in both trees
	#
	if (lc $compare_field eq "species") {
		$root1->recursive_implicit_species();
		$root2->recursive_implicit_species();
	} else {
		$root1->recursive_implicit_names();
		$root2->recursive_implicit_names();
	}

	# recursively compare the trees
	#
	return $root1->recursive_compare($root2, $compare_field);

}

=head2 function quasiRF_distance

  Synopsis:	 $node1->quasiRF_distance($node2), or 
                 $node1->quasiRF_distance($node2, "species");
  Arguments:	 A node object, whose subtree is the speci
  Returns:	 Compares the subtrees with roots $node1 and $node2. If 
                 they are topologically the same, 0 is returned. 
                 Otherwise returns a "distance" describing how different
                 the two subtrees are.
  Side effects:	 None.
  Description:	 Copies subtrees into new trees; collapses them, gets 
                 implicit names or species. For each node in subtree1 
                 add branch length to distance if a node with the same 
                 implicit name is not present in subtree2. 
                 This is somewhat like the Robinson-Foulds distance, 
                 but is not symmetric (hence not a true distance), as 
                 the topologies of both subtrees are used, but only the 
                 subtree1 branch lengths are used.
                 Think of it as a measure of how much subtree1 much be 
                 changed to reach the topology of subtree2.
                 We are typically going to use it to compare an ortholog
                 tree  with a species tree, in which case the implicit
                 species should be used in the comparison, i.e. it 
                 should be called with the optional 2nd arg having 
                 value "species"

=cut

sub quasiRF_distance{
# Q: what about the case where the sets of leaves are not the same? What should happen then?
	my $tree1 = shift->copy_subtree();
	my $tree2 = shift->copy_subtree();
	my $compare_field = shift;  
	$tree1->collapse_tree();
	$tree2->collapse_tree();

	$tree1->quasiRF_distance($tree2, $compare_field); 
	#		print STDOUT "distance: ", $tree1->get_root()->get_attribute("qRF_distance"), "<br>\n";
	return ($tree1->get_root()->get_attribute("qRF_distance"), $tree1);
}

# This just looks at the subtree_leaves_match attribute, which needs to have already been
# set by quasiRD_distance. recursive_quasiRF_distance sets the qRF_distance attribute for every
# node in the subtree
sub recursive_quasiRF_distance{
	my $self = shift; 	
	my $qRFdist = 0.0;						# if $self is leaf then $qRFdist will remain 0

	foreach my $c ($self->get_children()) {
		$qRFdist += $c->recursive_quasiRF_distance() + 
			($c->get_attribute("subtree_leaves_match") eq "true")? 0.0: $c->get_branch_length();
		
	}
	$self->set_attribute("qRF_distance", $qRFdist);
	return $qRFdist;
}


=head2 function robinson_foulds_distance

  Synopsis:	$node1->robinson_foulds_distance($node2);
  Arguments:	A node object.
  Returns:	Compares the subtrees with roots $node1 and $node2. 
                Returns the Robinson-Foulds distance describing how 
                different the two subtrees are.
  Side effects:	None.
  Description:	Copies subtrees into new trees; collapses them, gets
                implicit names. Pairs of nodes with the same implicit 
                name contribute abs(bl1 - bl2) to the distance, nodes 
                in either tree with no matching node (same implicit 
                name) in the other tree contribute their branch length. 
                This is the Robinson-Foulds distance between the two 
                subtrees with the rest of both trees ignored.

=cut

sub robinson_foulds_distance{
## should also check that 
	my $self = shift;
	my $other_node = shift;
	my $tree1 = $self->copy_subtree();
	my $tree2 = $other_node->copy_subtree();

	$tree1->collapse_tree();
	$tree2->collapse_tree();

	my $root1 = $tree1->get_root();
	my $root2 = $tree2->get_root();

print("in robinson-foulds, root bls: ", $root1->get_branch_length(), "   ", $root2->get_branch_length(), "\n");

	# get the implicit names for each node in both trees
	#
	$root1->recursive_implicit_names();
	$root2->recursive_implicit_names();

	if ($root1->get_name() ne $root2->get_name()) {
		print("In robinson_foulds_distance. root implicit names are different: ", $root1->get_name(), "  ", $root2->get_name(), " \n");
		die("robinson_foulds_distance requires trees have same set of leaf names. \n");
	}

	my $distance = 0.0;

	# set up the hash for tree1 nodes, with name as key
		my %n_bl_1= ();	
	my $nhr1 = $tree1->{node_hash};
	foreach my $n1 (values ( %$nhr1)) {
		$n_bl_1{ $n1->get_name()} = $n1->get_branch_length(); 
	}

	# set up the hash for tree2 nodes, with name as key
	my %n_bl_2 = ();
	my $nhr2 = $tree2->{node_hash};	
	foreach my $n2 (values ( %$nhr2)) {
		$n_bl_2{ $n2->get_name()} = $n2->get_branch_length(); 
	}

	my $bl2; my $bl1;
	foreach my $n1 (values (%$nhr1)) {			
		if (exists $n_bl_2{$n1->get_name()}) { # no node with this implicit name in tree2; add branch length to total
			$distance += 0.5*abs($n1->get_branch_length() -  $n_bl_2{$n1->get_name()});
		} else {
			$distance += $n1->get_branch_length();
		}
	}
	foreach my $n2 (values (%$nhr2)) {			
		if (! exists $n_bl_1{$n2->get_name()}) { # no node with this implicit name in tree2; add branch length to total
			$distance += 0.5*abs($n2->get_branch_length() - $n_bl_1{$n2->get_name()});
		}
	}
	return $distance;
}

=head2 function determine_species_from_name

  Synopsis:	$node1->determine_species_from_name()
  Arguments:	Optionally a string.
  Returns:	A string containing a species name obtained from the 
                node name, or from the optional string argument 
                instead if present.
  Side effects:	None.
  Description:	Starting with the node's name (or the argument if 
                present), obtain a species string to return as 
                follows:
	        1) At ->Arabidopsis
	        2) SGN-U followed by digits, get species from digits 
                   (each species has its range of values)
	        3) Bradi -> Brachypodium
                4) LOC_Os -> Rice (Oryza sativa)
                5) 1234_Eggplant.x3 -> Eggplant.x3

=cut

sub determine_species_from_name{
	my $self = shift;
	my $str = shift;
	my $species = undef;
	if (!$str) {	$str = $self->get_name(); }

	#	print STDERR "string to get species from: ", $str, "\n";
	if ($str =~ /^At/i) {					# At.... is Arabidopsis
		$species = "Arabidopsis";
	}

	# for $str of form SGN-U followed by digits,eliminate the SGN-U:
	elsif ($str =~ /^SGN-{0,1}U(\d+)/i) { # should we require SGN to be initial?

		#	print STDERR "SGN branch or ..species_name. \n";
		$str =~ s/SGN-{0,1}U(\d+)/$1/i; 

		# and get species based on number
		if (($str <= 205568) && ($str >= 196015)) {
			$species = "pepper";
		}
		if ( ($str <= 207409) && ($str >= 205569)) {
			$species = "eggplant";
		}
		if ( ($str <= 212544)  && ($str >= 207410)) {
			$species = "petunia";
		}
		if (($str <= 299123) && ($str >= 268052)) {
			$species = "potato";
		}
		if (($str <= 347124) && ($str >=312296)) {
			$species = "tomato";
		}
		if (($str <= 414796) && ($str >=406937)) {
			$species = "sweet_potato";
		}
		if (($str <= 362845) && ($str >=347125)) {
			$species = "coffee";
		}
		if (($str <= 388243) && ($str >= 362846)) {
			$species = "tobacco";
		}
		if (($str <= 400909) && ($str >= 388244)) {
			$species = "snapdragon";
		}
	} elsif ($str =~ /^Bradi/i) {
		$species = "brachypodium";   #  "Brachypodium_distachyon";
	} elsif ($str =~ /^LOC_Os/i) {
		$species = "rice";
	} elsif ($str =~ /(\d+)\_(.*)/) { # is >=1 digits, t
		$species = $2;
	} else {
		#	print STDERR ("in determine species, no leading digits.  name: $name,  id: $id,  species $species  \n");
		$species = $str;						# just use whole string
	}
	#	print STDERR ("Species: ", $str, "   ", $species, "\n");
	return $species;
}

=head2 recursive_subtree_newick

  Usage:        my $newick = $node->recursive_subtree_newick()
  Desc:         generates a newick string representing the tree structure 
               below this node.
  Side Effects:
  Example:

=cut

sub recursive_subtree_newick{		#recursive_generate_newick does the same thing & is more general (using make_newick_attributes() )
	my $self = shift;
	my $s = shift;
	if($self->is_leaf()){ $s .= $self->get_name . "[species=" . $self->get_species . "]"; }
	my @children = $self->get_children();
	my $first = 1;
	if (@children) {
		$s .= "(";
		foreach my $c (@children) {
			 if ($first) {
			 	$first = 0;
			 } else {
			 	$s .= ",";
			 }
			$s = $c->recursive_subtree_newick($s);
		}
		$s .= ")";
	}
	$s .= ":" . $self->get_branch_length() unless($self->is_root());
return $s;
}


=head2 function delete_self

  Synopsis:	$node->delete_self();
  Arguments:	A node object.
  Returns:	nothing if deletion succeeded, 1 if failed (because 
                node was root).
  Side effects:	Deletes the node.
  Description:	Sets any children of the node as children of its parent, 
                and the parent as parent of the children, adds node's 
                branch length to childrens branch length, and deletes 
                the node.
  See also:     Tree::delete_node, Tree::del_node, which check the 
                node exists, then if it call this subroutine, and then 
                Tree::recalculate_tree_data().

=cut

sub delete_self{
	my $self = shift; 

	# if the node is the root node, disallow delete
	#
#print "in delete self. key, is_root, parent: ", $self->get_node_key(), "  ", $self->is_root(), "  ", $self->get_parent(), '   ', $self->get_name(), "\n";
	if ($self->is_root()) { 
		warn "CXGN::Phylo::Node::delete_self: You are attempting to delete the root node of the tree. key: ", $self->get_node_key(), "\n";
		return 1;
	}

	# Recalculate the branch lengths for the children of the deleted node.
	# the new branch length is the children's branch length plus this node''s 
	# branch length.
	# For each child of the node to be deleted, set the parent to the 
	# parent of the deleted node.
	# Make each child node a child of the node's parent.
	#
	my @children = $self->get_children();
	my $branch_length = $self->get_branch_length();
	foreach my $c (@children) {
		$c->set_branch_length($c->get_branch_length()+$branch_length);
		$c->set_parent($self->get_parent());
		$self->get_parent()->add_child_node($c);
	}

	# remove the node from it's parent's children list
	#
	$self->get_parent()->remove_child($self);

	# delete the node
	#
	$self->set_children(undef);
	$self->set_parent(undef);
	$self->set_label(undef);
	$self->set_tree(undef);

	$self = undef;								# really, really delete the node
}





#returns a list of the subtrees with subtree_leaves_match eq true, and which have quasiRF_distance <= the argument
sub recursive_get_ortho_subtrees{
	my $self = shift;
	my $qRFd_max = shift; 
	my @conforming_nodes = ();
	if (!defined $qRFd_max) {
		$qRFd_max = 0;
	}
	my $implspec = $self->get_implicit_species();

	if ($self->get_attribute("subtree_leaves_match") eq "true" # require subtree and a subtree of species tree to match species set of leaves
			and $self->get_attribute("qRF_distance") <= $qRFd_max) { # subtree is sufficiently close to conforming to topology
		if (!$self->is_leaf()) {
			push @conforming_nodes, $self;
		#	$self->set_hilited(1);
		}
	} else {
		foreach my $c ($self->get_children()) {
			@conforming_nodes = (@conforming_nodes, $c->recursive_get_ortho_subtrees($qRFd_max));
		}
	}
	return @conforming_nodes;
}

# divide a tree into subtrees with <= $max_leaves leaves, by pushing 
# a copy of the subtree
# onto list of small trees if small enough, and if too big, then calling this
# function of each child. (Doesn't seem to be very useful)
sub recursive_divide_subtree_into_small_trees{
	my $self = shift;
	my $max_leaves = shift;
#	print "subtree leaves: ", $self->get_attribute("leaf_count"), "\n";
	my $small_tree;
	my $small_trees_array = shift || [];
	if ($self->get_attribute("leaf_count") <= $max_leaves) {
		push @$small_trees_array, $self->copy_subtree(); #store a tree which is a copy of the subtree with root at this node
	} else {
		my @children = $self->get_children();
		foreach (@children) {
			#	if ($_->get_attribute("leaf_count") <= $max_leaves) {
			#			$small_tree = $_->copy_subtree(); 
			#			push @$small_trees_array, $small_tree;
			#		} else {
			$_->recursive_divide_subtree_into_small_trees($max_leaves, $small_trees_array);
			#	}
		}
	}
	return $small_trees_array;
}


# Another attempt at breaking up big trees in a good way - not too successful.

=head2 function recursive_set_levels_above_distinct_species_subtrees

 Synopsis:     my $levels_above = $a_node->
                  recursive_set_levels_above_distinct_species_subtrees()
 Arguments:    None.
 Returns:      The number of levels $a_node is above an ortholog group 
               candidate subtree (distinct species tree with > 1 leaf); 
               returns $big_levels (a large number) if there is no 
               ortho group candidate subtree in the subtree below 
               $a_node.
 Description:  Recursively looks in $a_node's subtree for subtrees 
               with >1 leaves, and all leaves having distinct species; 
               such trees get their levels_above_... field set to 0, 
               otherwise it gets set to the number of branches above 
               such a subtree, or to $big_levels if $a_nodes subtree 
               doesnt contain such a subtree.
  Author:      Tom York (tly2@cornell.edu)

=cut

sub recursive_set_levels_above_distinct_species_subtree{
	my $self = shift;
	my $levels_above_distinct_species_subtree = undef;
	my $big_levels = 10000000;		# a number bigger than the depth of any reasonable tree
	#	print($self->get_name(), "   ", $self->get_attribute("leaf_species_count"), "   ", $self->get_attribute("leaf_count"), "\n");
	if ($self->get_attribute("leaf_species_count") == $self->get_attribute("leaf_count") && ($self->get_attribute("leaf_count") > 1)) {	
		# distinct species subtree - more than 1 leaf, and all leaves have distinct species
		$levels_above_distinct_species_subtree = 0; # this IS a distinct species subtree

	} else {											
		# leaf, or subtree with more leaves than species - check the children
		my $min_child_levels_above = $big_levels; 
		foreach my $c ($self->get_children()) {
			my $child_levels_above = $c->recursive_set_levels_above_distinct_species_subtree();
				$min_child_levels_above = $child_levels_above if($child_levels_above < $min_child_levels_above);
		}
		# if $min_child_levels_above got set (to something < $big_levels) then there is an orthcand in the subtree. 
		$levels_above_distinct_species_subtree = ($min_child_levels_above == $big_levels)? $big_levels: $min_child_levels_above + 1; 
	}
	print "setting levels above for node: ", $self->get_name(),  "   to: ", $levels_above_distinct_species_subtree, "\n";
	$self->set_attribute("levels_above_distinct_species_subtree",  $levels_above_distinct_species_subtree);
	return $levels_above_distinct_species_subtree; 
}



=head2 function recursive_ortholog_group_candidate_subtrees

  Synopsis:	my $levels_above = $a_node->
                  recursive_ortholog_group_candidate_subtrees(
                  $ortho_cand_array, $desired_levels_above)
  Arguments:	A reference to an array in which the candidate trees 
                will be stored, and optionally the number of levels to 
                keep above the distinct species subtrees (default = 0).
  Returns:	The number of levels $a_node is above an ortholog group 
                candidate subtree (distinct species tree with > 1 leaf); 
                returns $big_levels (a large number) if there is no 
                ortho group candidate subtree in the subtree below 
                $a_node.
  Description:	Recursively looks in $a_node's subtree for subtrees 
                with >1 leaves, and all leaves having distinct species; 
                such trees get their levels_above_... field set to 0, 
                otherwise it gets set to the number of branches above 
                such a subtree, or to $big_levels 
                if $a_nodes subtree doesn't contain such a subtree.
  Author:       Tom York (tly2@cornell.edu)

=cut


sub recursive_find_ortholog_group_candidate_subtrees{
	my $self = shift;
	my $ortho_cand_subtree_array = shift || [];
	my $desired_levels_above = shift;
	$desired_levels_above = 0 unless($desired_levels_above > 0);
	
	my $levels_above_distinct_species_subtree = undef;
	if ($self->get_attribute("levels_above_distinct_species_subtree") <= $desired_levels_above) {	
		push @$ortho_cand_subtree_array, $self->copy_subtree();
	} else {											# $self subtree not all orthologs, look in child subtrees
		foreach my $c ($self->get_children()) {
			$c->recursive_find_ortholog_group_candidate_subtrees($ortho_cand_subtree_array, $desired_levels_above);
		}
	}
}


# set speciation field in node and its subtree
sub recursive_set_speciation{
my $self = shift;
my $spec_tree = shift;
$self->set_attribute("speciation", $self->speciation_at_this_node($spec_tree));
foreach ($self->get_children()){
	$_->recursive_set_speciation($spec_tree);
}
}

# $a_node->speciation_at_this_node($spec_tree)
# $spec_tree is a species tree.
# returns 1 if speciation at this node would be consistent with the species tree.
sub speciation_at_this_node{
	my $self = shift;
	my $spec_tree = shift;				# this has to have the species bit patterns set
	my @children = $self->get_children();
	my $nchild = scalar @children;;
	my $or = int 0; 
	#	print "$or \n";
	return 0 if($nchild < 2);
	foreach my $c ($self->get_children()) {
		my $isbp = $c->get_attribute("species_bit_pattern");
		#	print "or, isbp or&isbp: ", $or, "  ", $isbp, "  ", $or & $isbp, "\n";
		if (($or & $isbp) != 0) {		# no speciation because there is at least 1 species occurring in > 1 child subtree
			#	print "in speciation_at_this_node. returning 0\n";
			return int 0;
		}					
		$or |= $isbp;
	}
	# speciation not ruled out; check against species tree
	if ($nchild == 2) {						# bifurcation. 
		my $bp1 = $children[0]->get_attribute("species_bit_pattern");
		my $bp2 = $children[1]->get_attribute("species_bit_pattern");
#		print "In Node::speciation_at_this_node; child bit patterns: $bp1, $bp2\n";
		return $spec_tree->get_root()->recursive_compare_species_split($bp1, $bp2); # see if the two child species sets are consistent with any of the nodes in species tree

	} elsif ($nchild == 3) {			# trifurcation
	#	print "in speciation_at_this_node. nchild: $nchild \n";

		my $c1 =  $children[0];  my $bp1 = $c1->get_attribute("species_bit_pattern");
		my $c2 =  $children[1];  my $bp2 = $c2->get_attribute("species_bit_pattern");
		my $c3 =  $children[2];  my $bp3 = $c3->get_attribute("species_bit_pattern");
		#		print "trifurcation; 3 bit patterns:  $bp1  $bp2  $bp3  \n";
		#root on child0 branch
		my $res1 = $spec_tree->get_root()->recursive_compare_species_split($bp1, $bp2 | $bp3);
		my $res2 = $spec_tree->get_root()->recursive_compare_species_split($bp2, $bp3 | $bp1);	
		my $res3 = $spec_tree->get_root()->recursive_compare_species_split($bp3, $bp1 | $bp2);
	#	print "c1:   ", $c1->get_name(), "  c2:  ", $c2->get_name(),"  c3:  ", $c3->get_name(), "\n";
#		print "res1/2/3:  $res1  $res2  $res3  \n";
		die"In speciation_at_this_node. trifurcation case. Problem deciding how to resolve. \n" if($res1 + $res2 + $res3 > 1);
		if ($res1) {
			$self->binarify_with_specified_resolution([$c1], [$c2, $c3]);
		} elsif ($res2) {
			$self->binarify_with_specified_resolution([$c2], [$c3, $c1]);
		} else {
			$self->binarify_with_specified_resolution([$c3], [$c1, $c2]);
		}
		# recalculate implicit species - needed?
		return ($res1 + $res2 + $res3);
		# recalculate implicit species - needed?

	} elsif ($nchild == 4) {			# trifurcation
		my $c1 =  $children[0];  my $bp1 = $c1->get_attribute("species_bit_pattern");
		my $c2 =  $children[1];  my $bp2 = $c2->get_attribute("species_bit_pattern");
		my $c3 =  $children[2];  my $bp3 = $c3->get_attribute("species_bit_pattern");
		my $c4 =  $children[3];  my $bp4 = $c4->get_attribute("species_bit_pattern");
		#		print "trifurcation; 3 bit patterns:  $bp1  $bp2  $bp3  \n";
		#root on child0 branch
		my $res1 = $spec_tree->get_root()->recursive_compare_species_split($bp1,        $bp2 | $bp3 | $bp4);
		my $res2 = $spec_tree->get_root()->recursive_compare_species_split($bp2,        $bp1 | $bp3 | $bp4);
		my $res3 = $spec_tree->get_root()->recursive_compare_species_split($bp3,        $bp2 | $bp1 | $bp4);
		my $res4 = $spec_tree->get_root()->recursive_compare_species_split($bp4,        $bp2 | $bp3 | $bp1);

		my $res5 = $spec_tree->get_root()->recursive_compare_species_split($bp1 | $bp2,        $bp3 | $bp4);
		my $res6 = $spec_tree->get_root()->recursive_compare_species_split($bp1 | $bp3,        $bp2 | $bp4);
		my $res7 = $spec_tree->get_root()->recursive_compare_species_split($bp1 | $bp4,        $bp3 | $bp2);

		die"In speciation_at_this_node. trifurcation case. Problem deciding how to resolve. \n" if($res1 + $res2 + $res3 + $res4 + $res5 + $res6 + $res7 > 1);
		if ($res1) {
			$self->binarify_with_specified_resolution([$c1], [$c2, $c3, $c4]);
		} elsif ($res2) {
			$self->binarify_with_specified_resolution([$c2], [$c3, $c1, $c4]);
		} elsif ($res3) {
			$self->binarify_with_specified_resolution([$c3], [$c1, $c2, $c4]);
		} elsif ($res4) {
			$self->binarify_with_specified_resolution([$c4], [$c3, $c1, $c2]);
		} elsif ($res5) {
			$self->binarify_with_specified_resolution([$c1, $c2], [$c3, $c4]);
		} elsif ($res6) {
			$self->binarify_with_specified_resolution([$c1, $c3], [$c2, $c4]);
		} elsif ($res7) {
			$self->binarify_with_specified_resolution([$c1, $c4], [$c3, $c2]);
		}
		# recalculate implicit species - needed?
		return ($res1 + $res2 + $res3 + $res4 + $res5 + $res6 + $res7);
		# recalculate implicit species - needed?
	} else {											# > 4 multifurcation - can't handle it yet!
		die "In speciation_at_this_node. Multifurcation (>4 children) not implemented. \n";
	}
	die"In speciation_at_node. Shouldn't get here?? \n";
}

# $species_tree_node->recursive_compare_species_split($a1, $a2)
# to check whether a node with child species bit patterns  $a1 and $a2 
# is consistent with any of the nodes in the species tree subtree with root
# at $species_tree_node. Called by speciation_at_this_node for  ortholog finding
sub recursive_compare_species_split{
	my $self = shift;							# a node of species tree, typically
	my $a1 = shift;
	my $a2 = shift;

	if($a1 == 0 or $a2 == 0){ return 0; }; # one subtree has no species found in species tree 
	my @children = $self->get_children();
#	print "ZZZ [", scalar @children, "][", $self->get_attribute("species_bit_pattern"), "] &nbsp";

	return int 0 if(scalar @children < 2); # if reach leaf of species tree, no speciation.
	my $b1 = $children[0]->get_attribute("species_bit_pattern");
	my $b2 = $children[1]->get_attribute("species_bit_pattern");
	if (($a1 & ~$b1) == 0) {	# a1 (gene tree) species set is subset of b1 species set		
		if (($a2 & ~$b2) == 0) {
			return int 1;
		} elsif (($a2 & ~$b1) == 0) {
			return $children[0]->recursive_compare_species_split($a1, $a2);
		} else {
			return int 0;
		}
	} elsif (($a1 & ~$b2) == 0) {
		if (($a2 & ~$b1) == 0) {
			return int 1;
		} elsif (($a2 & ~$b2) == 0) {
			return $children[1]->recursive_compare_species_split($a1, $a2);
		} else {
			return int 0;
		}
	} else {
		return 0;
	}
}

# starting at a leaf go to parent node; if it is speciation, add leaves in OTHER child subtrees
# to list of orthologs, keep going up looking for speciation nodes until reach root.
# returns a list of names of all the leaves which are orthologs
sub collect_orthologs_of_leaf{
	my $self = shift;							# the leaf to start at
	my @ortholog_array;
	if ($self->get_attribute("species_bit_pattern") == 0){ return @ortholog_array; }
	my $prev_parent = $self;
	my $parent = $self->get_parent();
#	return @ortholog_array;
#	print  "XXX: [", $parent->get_attribute("speciation"), "]&nbsp";
	while (1) {
		if ($parent->get_attribute("speciation")) {
			#print  join(";", $parent->get_implicit_names()), "\n";
			#	foreach ($parent->get_children()) { 
			#			}
			foreach ($parent->get_children()) { # all children
				next if($_ eq $prev_parent); # except one with $self in its subtree	
				my @imp_names = (@{$_->get_implicit_names()});
				foreach my $n (@imp_names) {
					$n =~ s/(.*)?\|/$1/;
				}
				#print STDERR "implicit names: ", join(" ", @imp_names), "\n";
				@ortholog_array = (@ortholog_array, @imp_names) if ($self->get_attribute("species_bit_pattern") > 0);
			}
		}
		last if($parent->is_root());
		$prev_parent = $parent;
		$parent = $prev_parent->get_parent();
	}
	return @ortholog_array;
}

sub recursive_collect_max_speciation_nodes{
# start from top, work down subtree until find a node with speciation==1
# add node to array and don't go further down into that subtree

	my $self = shift;
	my $spec_node_array = shift; 
	if($self->get_attribute("speciation") == 1){
		push @$spec_node_array, $self;
		return;
	}
	foreach($self->get_children()){
		$_->recursive_collect_max_speciation_nodes($spec_node_array);
	}
}

# just recursively set_hilited for each speciation node.
sub recursive_hilite_speciation_nodes{
	my $self = shift;
# return;
	$self->set_hilited($self->get_attribute("speciation"));
	foreach ($self->get_children()) {
		$_->recursive_hilite_speciation_nodes()
	}
	return;
}


sub recursive_set_branch_length{
my $self = shift;
my $bl = shift || 1.0;
$self->set_branch_length($bl);
my @children = $self->get_children();
foreach (@children){
$_->recursive_set_branch_length($bl);
}

}

# The idea here is to recursively remove circular references 
# which prevent trees from being garbage collected.
sub recursive_decircularize{
  my $self = shift;
  $self->set_parent(undef);
  $self->set_tree(undef);
  foreach ($self->get_children()) {
    $_->recursive_decircularize()
  }
}

1;

# Species_name_map is now in a separate file, Species_name_map.pm
