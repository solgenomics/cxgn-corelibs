
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

package CXGN::Phylo::Node;

# <<<<<<< HEAD
use strict;
use base 'CXGN::Phylo::BasicNode';

use CXGN::Page::FormattingHelpers qw/tooltipped_text/;
use CXGN::Phylo::Label;


sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);
  $self->set_label( CXGN::Phylo::Label->new() );
  $self->set_X(0);
  $self->set_Y(0);
  return $self;
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
    my $self       = shift;    # this is the node to be copied
    my $new_parent = shift;
    my $new_tree   = shift;

    my $new = CXGN::Phylo::Node->new();    # the copy

    if ($new_parent) {
        $new_parent->add_child_node($new);
    }

    $new->set_tree($new_tree);

$self->copy_fields($new);
  $new->set_label( $self->get_label()->copy() );
   $new->set_horizontal_coord( $self->get_horizontal_coord() );
     $new->set_vertical_coord( $self->get_vertical_coord() );

    return $new;
}


=head2 accessors get_hide_label(), set_hide_label()

  Synopsis:	$n->set_hide_label(1);
  Property:	a boolean value representing the hide state of the label
  Side effects:	labels with a true value will not be drawn.
  Description:	

=cut

sub get_hide_label {
    my $self = shift;
    return $self->get_label()->is_hidden();
}

sub set_hide_label {
    my $self = shift;
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
    return @{ $self->{line_color} };
}

sub set_line_color {
    my $self  = shift;
    my @color = shift;
    return unless ( @color == 3 );
    foreach (@color) {
        return unless ( $_ >= 0 && $_ <= 255 );
    }
    @{ $self->{line_color} } = @color;
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
    my $self = shift;
    return int( $self->{horizontal_coord} );
}

sub get_X {
    my $self = shift;
    return $self->{horizontal_coord};
}

sub set_horizontal_coord {
    my $self = shift;
    $self->{horizontal_coord} = shift;
    $self->get_label()->set_reference_point( $self->{horizontal_coord}, $self->get_Y() );
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
    my $self = shift;
    if ( !$self->{vertical_coord} ) {
        $self->{vertical_coord} = 0;
    }
    return int( $self->{vertical_coord} );
}

sub get_Y {
    my $self = shift;

    #my $Y = $self->get_vertical_coord();
    #return sqrt($Y);
    return $self->get_vertical_coord();
}

sub set_vertical_coord {
    my $self = shift;
    $self->{vertical_coord} = shift;
    $self->get_label()->set_reference_point( $self->get_X(), $self->{vertical_coord} );
}

sub set_Y {
    my $self = shift;
    $self->set_vertical_coord(shift);

}


=head2 function wrap_tooltip(){

  Synopsis:	$n->wrap_tooltip("At1g01010");
  Arguments:	text/variable to wrap in tooltip, tooltip itself
  Side effects:	NOT SURE YET. NEED TO TEST 
                CXGN::Phylo::Node::search searches the name property.
  Description:	//TODO//

=cut

sub wrap_tooltip {
    my $self    = shift;
    my $tooltip = shift;
    $self->{name} = shift;
    my $wrappedobj = tooltipped_text( $self->{name}, $tooltip );
    return $wrappedobj;
}

1;
