=head1 NAME

CXGN::Phylo::Layout - calculates the layout of a tree.

=head1 DESCRIPTION

The Layout class calculates the layout of a tree.
The layout object is then passed to a Renderer object, which
will render the tree.

These classes are used by the tree object L<CXGN::Phylo::Tree> to layout the tree.

The layout can be subclassed to achieve different tree layouts, such as in the examples below (rendering the tree from right to left instead of left to right, etc. The CXGN::Phylo::Tree object can then be made to use the alternate layout classes by using the set_layout() accessor in L<CXGN::Phylo::Tree>. The default layout for a Tree is CXGN::Phylo::Layout, which lays out the tree from left to right (the root is left and the labels are on the right).

This can be combined with alternate renderers (L<CXGN::Phylo::Renderer>) to achieve a large number of different tree output options. Note that it will not be possible to combine every Layout with any Renderer.

=head1 AUTHOR(S)

Lukas Mueller <lam87@cornell.edu>

=head1 METHODS

This class implements the following methods:

=cut

package CXGN::Phylo::Layout;

=head2 constructor new()

 Usage:        my $lo = CXGN::Phylo::Layout->new($tree);
 Desc:         creates a new layout object
 Args:         a CXGN::Phylo::Tree object
 Side Effects: lays out the tree object
 Example:

=cut

sub new { 
    my $class = shift;
    my $tree = shift;
    my $args = {};
    my $self = bless $args, $class;

    # initialize object properties
    #
    $self->set_tree($tree);
    $self->set_top_margin(10);
    $self->set_right_margin(10);
    $self->set_bottom_margin(10);
    $self->set_left_margin(10);
    $self->set_label_margin(0);
    $self->set_vertical_gap(0);
    $self->set_horizontal_scaling_factor(0);
    $self->set_image_width(100);
    $self->set_image_height(100);
    return $self;
}

=head2 accessors get_tree(), set_tree()

  Synopsis:	my $tree = $layout -> get_tree();
                $layout -> set_tree($tree);
  Property:     the tree this layout object works on
  Side effects:	
  Description:	

=cut

sub get_tree { 
    my $self=shift;
    return $self->{tree};
}

sub set_tree { 
    my $self=shift;
    $self->{tree}=shift;
}

=head1 Functions controlling the the size and margins


=head2 accessors get_image_width(), set_image_width()

  Synopsis:	$lo->set_image_width(400);
  Property:     the width of the final image in pixels
  Side effects:	
  Description:	

=cut

sub get_image_width { 
    my $self=shift;
    return $self->{image_width};
}

sub set_image_width { 
    my $self=shift;
    $self->{image_width}=shift;
}


=head2 accessors get_image_height(), set_image_height()

  Synopsis:	$lo->set_image_height(300);
  Property:     the height of the final image in pixels
                [integer]
  Side effects:	
  Description:	

=cut

sub get_image_height { 
    my $self=shift;
    return $self->{image_height};
}

sub set_image_height { 
    my $self=shift;
    $self->{image_height}=shift;
}

=head2 accessors get_top_margin(), set_top_margin()

  Synopsis:	$lo->set_top_margin(10);
  Property:     the margin at the top of the image
                in pixels [integer]
  Side effects:	
  Description:	

=cut

sub get_top_margin { 
    my $self=shift;
    return $self->{top_margin};
}

sub set_top_margin { 
    my $self=shift;
    $self->{top_margin}=shift;
}

=head2 accessors get_left_margin(), set_margin_left()

  Synopsis:     $lo->set_left_margin(20);
  Property:     the margin at the left of the image
                in pixels, integer. 
  Side effects:	
  Description:	

=cut

sub get_left_margin { 
    my $self=shift;
    return $self->{left_margin};
}

sub set_left_margin { 
    my $self=shift;
    $self->{left_margin}=shift;
}

=head2 accessors get_right_margin(), set_right_margin()

  Synopsis:	 $lo->set_right_margin(10);
  Property:	 the right margin in pixels [integer]
  Description:	

=cut

sub get_right_margin { 
    my $self=shift;
    return $self->{right_margin};
}

sub set_right_margin { 
    my $self=shift;
    $self->{right_margin}=shift;
}

=head2 accessors get_bottom_margin(), set_bottom_margin()

  Synopsis:     $lo->set_bottom_margin(10);	
  Property:     the bottom margin in pixels [integer]
  Side effects:	
  Description:	

=cut

sub get_bottom_margin { 
    my $self=shift;
    return $self->{bottom_margin};
}

sub set_bottom_margin { 
    my $self=shift;
    $self->{bottom_margin}=shift;
}

=head2 accessors get_label_margin(), set_label_margin()

  Synopsis:	$lo->set_label_margin(10)
  Property:     the margin between the label and the leaf node
                in pixels [integer]
  Side effects:	
  Description:	

=cut

sub get_label_margin { 
    my $self=shift;
    return $self->{label_margin};
}

sub set_label_margin { 
    my $self=shift;
    $self->{label_margin}=shift;
	#	print STDERR "in set_label_margin. label margin set to: [", $self->get_label_margin(), "]\n";
}


=head1 Functions and properties used by the layout() function. 

These should probably not be called directly, unless this class is sub-classed and layout() overridden.

=head2 accessors get_vertical_gap(), set_vertical_gap()

  Synopsis:	my $vertical_gap = $lo->get_vertical_gap();
  Property:     the vertical gap between leaf nodes.
  Side effects:	
  Description:	

=cut

sub get_vertical_gap { 
    my $self=shift;
    return $self->{vertical_gap};
}

sub set_vertical_gap { 
    my $self=shift;
    $self->{vertical_gap}=shift;
}

=head2 accessor get_horizontal_scaling_factor(), set_horizontal_scaling_factor()

  Synopsis:	$lo->set_horizontal_scaling_factor(2);
  Property:     the horizontal scaling factor [real]
  Side effects:	
  Description:	determines how the tree will be scaled horizontally,
                in a conversion from branch length units to pixels.

=cut

sub get_horizontal_scaling_factor { 
    my $self=shift;
    return $self->{horizontal_scaling_factor};
}

sub set_horizontal_scaling_factor { 
    my $self=shift;
    $self->{horizontal_scaling_factor}=shift;
}

=head2 function layout()

 Usage:        $lo->layout()
 Desc:         does the layout calculation
 Ret:          nothing
 Args:         none
 Side Effects: 
 Example:

=cut

sub layout {
	my $self = shift;

	# if labels are shown, calculate the longest label
	my $longest_label = 0;				# in pixels
	foreach my $n ($self->get_tree()->get_leaf_list()) { 
		my $label = $n->get_label()->get_shown_name();
		next if($n->get_hidden or !$n->is_leaf() or $n->get_hide_label()); # in these cases the label will not be shown, so don't consider its length.
		if (length($label) > $longest_label) { 
		#	print STDERR "in layout. new longest label: ", $label, "\n";
			$longest_label= length($label);
		}
	}
#print STDERR "in layout. [", $longest_label, "][", $self->get_tree()->get_renderer()->get_font_width(), "]\n";
	$self->set_label_margin($longest_label*$self->get_tree()->get_renderer()->get_font_width());

	# perform some tree calculations
	# -- get the distances from root, used for horizontal layout
	my $bltype = "branch_length";
#$bltype = "square_root";
	#$bltype = "proportion_different";
	#$bltype = "equal";
	$self->get_tree()->shown_branch_length_transformation_reset($bltype); # branch_length");
	#	$self->get_tree()->get_root()->calculate_distances_from_root(0.0, $bltype);

	# -- get the leaf list, used for vertical layout
	$self->get_tree()->get_leaf_list();

	$self->_layout_horizontal();
	$self->_layout_vertical();
}

=head2 function _layout_horizontal()

 Usage:        $lo->_layout_horizontal()
 Desc:         helper function for layout, which lays out the tree
               in the horizontal dimension
 Ret:          nothing
 Args:         none
 Side Effects: sets layout coordinates in the node objects
 Example:

=cut

sub _layout_horizontal { 
	my $self = shift;

	# calculate the distance of each node to the root
#	$self->get_tree()->get_root()->calculate_distances_from_root();
	my $longest = $self->get_tree()->calculate_longest_root_leaf_length();

#print STDERR "AAAAA in _layout_horizontal. longest: $longest  , image width: ", $self->get_image_width(), "\n";
	$longest = 1.0 if($longest<=0);
	$self->get_tree()->set_longest_root_leaf_length($longest);
	#  $self->set_horizontal_scaling_factor($self->get_image_width()/$largest);  # is this used??? yes, in renderer
	$self->set_horizontal_scaling_factor($self->get_image_width()/$longest); # is this used??? yes, in renderer

	# calculate all the horizontal coordinates for each node recursively
	$self->recursive_horizontal_coords($self->get_tree()->get_root());
}

=head2 function _layout_vertical()

  Synopsis:	helper function to layout() that lays out the vertical
                dimension of the tree
  Arguments:	none
  Returns:	nothing
  Side effects:	sets all the node coordinates, starting from the leaf nodes.
                The leaf nodes are spread evenly across the image height, all
                other node positions are calculated by recursing through the 
                tree and taking the average of the vertical coordinates of the
                corresponding children  nodes. Takes into account the margins as 
                set by set_top_margin() and set_bottom_margin().
  Description:	

=cut

sub _layout_vertical { 
    my $self = shift;
    
    # get the total leaf count
    my $total_leaves = $self->get_tree()->get_leaf_count();
    my $image_height = $self->get_image_height();
    if ($total_leaves < 1) { return; }
    my $vertical_gap = ($image_height - $self->get_top_margin() - $self->get_bottom_margin()) / ($total_leaves);
    
    # the leaf nodes should be easy.
    # traverse the tree, find all the leaves, and set the vertical
    # coordinate in the leaves to an increasing value with step $vertical_gap.
    my @leaves = $self->get_tree()->get_leaf_list();    
    for (my $i=0; $i<@leaves; $i++) { 
	$leaves[$i]->set_Y($self->get_top_margin()+($i)*$vertical_gap);
    }

    $self->set_vertical_gap($vertical_gap);
    # for the remaining nodes, we just take the average of the coords for the
    # first and the last child.
    $self->_recursive_vertical_coords($self->get_tree()->get_root());

}

sub _recursive_vertical_coords { 
    my $self = shift;
    my $node = shift;

    if ($node->is_leaf() || $node->get_hidden()) { return $node->get_vertical_coord(); }
 
    # calculate average over all children
    # if not is not hidden.
    my $coord;
    my @children = $node->get_children();
    my $total = 0;
    foreach my $c (@children) {
	$total += $self->_recursive_vertical_coords($c);
    }
    
    $coord = $total/@children;

    $node -> set_Y($coord);

#    print STDERR "CHILD: ".$node->get_name()." COORD: ".$node->get_vertical_coord()."\n";
    return $coord;
}


sub recursive_horizontal_coords { 
    my $self =  shift;
    my $node = shift;

    # if the tree is undefined or all the branch lengths are zero, or 
    # the root node is hidden, we should not be doing this...
    #
#print STDERR "in recursive_horizontal_coords. [", $self->get_tree()->get_longest_root_leaf_length(), "]\n";
    if ($self->get_tree()->get_longest_root_leaf_length() == 0) { return; }

    my @children = $node->get_children();

    # if the node is hidden, don't proceed with the children! (all sub-children
    # will be hidden too!)
    #
    if (!$node->get_hidden()) { 
			foreach my $c (@children) { 
				$self->recursive_horizontal_coords($c);
			}
    }
# print "dist from root, longest dist from root: " , $node->get_dist_from_root(), "   ", $self->get_tree()->get_longest_root_leaf_length(), "\n";
		my $normalized_dist_from_root = $node->get_dist_from_root()/($self->get_tree()->get_longest_root_leaf_length()); #between 0 and 1.

#print STDERR "in rec.horiz.coords. [", $self->get_image_width(), "][",	$self->get_left_margin(), "][", 
		#$self->get_right_margin(), "][", $self->get_label_margin(), "]\n";
		my $available_width = ($self->get_image_width()-$self->get_left_margin()-$self->get_right_margin()-$self->get_label_margin());
#print STDERR "in rec.horiz.coords. [", $normalized_dist_from_root, "][", $available_width, "][", $self->get_left_margin(), "]\n";
    $node->set_X($self->get_left_margin()+$normalized_dist_from_root*$available_width);
		#    print STDERR "HORIZONTAL COORD: ".$node->get_X()."\n";
	}


=head1 Package CXGN::Phylo::Layout_left_to_right;

This is just a subclass of Layout which does not perform any additional calculations.

=cut

package CXGN::Phylo::Layout_left_to_right;

use base qw/ CXGN::Phylo::Layout /;


=head1 Package CXGN::Phylo::Layout_right_to_left

Subclass of Layout. It performs the same calculations as layout, and then transforms
the resulting coordinates such that the tree will be displayed in a flipped orientation.

=cut

package CXGN::Phylo::Layout_right_to_left;

use base qw/ CXGN::Phylo::Layout /;

sub new { 
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}

sub layout { 
    my $self = shift;
    $self->SUPER::layout(@_);
    $self->flip_coordinates_horizontally($self->get_tree()->get_root());

}

sub flip_coordinates_horizontally { 
    my $self = shift;
    my $node = shift;
    my ($x, $y) = ($node->get_X(), $node->get_Y());
    $node->set_X($self->get_image_width()-$x);
    $node->set_Y($y);
    $node->get_label()->align_left();
    foreach my $c ($node->get_children()) { 
	$self->flip_coordinates_horizontally($c);
    }
}
	

=head1 Package CXGN::Phylo::Layout_top_to_bottom

Subclass of Layout. It performs the same calculations as layout, and then transforms
the resulting coordinates such that the tree will be displayed in a flipped orientation.

=cut

package CXGN::Phylo::Layout_top_to_bottom;

use base qw/ CXGN::Phylo::Layout /;

sub new { 
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}

sub layout { 
    my $self = shift;
    my ($width, $height) = ($self->get_image_width(),$self->get_image_height());
    $self->set_image_width($height);
    $self->set_image_height($width);
    $self->SUPER::layout(@_);
    $self->flip_coordinates_90_degrees($self->get_tree()->get_root());
    $self->set_image_width($width);
    $self->set_image_height($height);
 
}

sub flip_coordinates_90_degrees { 
    my $self = shift;
    my $node = shift;
    my ($x, $y) = ($node->get_X(), $node->get_Y());
    $node->set_X($y);
    $node->set_Y($x);
    $node->get_label()->align_right();
    foreach my $c ($node->get_children()) { 
	$self->flip_coordinates_90_degrees($c);
    }
}




=head1 Package CXGN::Phylo::Layout_bottom_to_top

Subclass of Layout. It performs the same calculations as layout, and then transforms
the resulting coordinates such that the tree will be displayed in a flipped orientation.

=cut

package CXGN::Phylo::Layout_bottom_to_top;


1;
