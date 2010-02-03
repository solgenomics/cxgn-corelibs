
=head1 NAME

CXGN::Sunshine::Node - a class to represent a locus in a network

=head1 DESCRIPTION

This node object essentially contains functionality to draw itself. In the sunshine browser, connections to other nodes are maintained using the L<Graph> module. Each node has a unique key which is also stored in the Graph.

=head1 AUTHOR(S)

Lukas Mueller <lam87@cornell.edu>

=head1 METHODS

This class implements the following methods:

=cut

use strict;

package CXGN::Sunshine::Node;

#use CXGN::Phenome::Locus;

use GD;
use CXGN::Sunshine::ImageElement;

use base qw |  CXGN::Sunshine::ImageElement |;


=head2 new

 Usage:        my $n = CXGN::Sunshine::Node->new($unique_id)
 Desc:         creates a new node with unique id $unique_id 
 Ret:          a CXGN::Sunshine::Node object
 Args:         undef for a new node
 Side Effects:
 Example:

=cut

sub new { 
    my $class = shift;
    my $unique_id= shift;
    my $self = $class->SUPER::new(@_);
    $self->set_unique_id($unique_id);
    $self->set_bgcolor(255, 255, 255);
    $self->set_fgcolor(0, 0, 0);
    $self->set_font(GD::Font->Small);
    return $self;
}

=head2 accessors get_unique_id, set_unique_id

 Usage:        REMOVE THESE AFTER TESTING...
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_unique_id {
  my $self = shift;
  return $self->{unique_id}; 
}

sub set_unique_id {
  my $self = shift;
  $self->{unique_id} = shift;
}

=head2 accessors get_level, set_level

 Usage:        $n->set_level(3)
 Desc:         stores the level of this node for a
               certain layout
 Property
 Side Effects:
 Example:

=cut

sub get_level {
  my $self = shift;
  return $self->{level}; 
}

sub set_level {
  my $self = shift;
  $self->{level} = shift;
}


=head2 layout

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub layout {
    my $self = shift;
#     $self->set_enclosing_rect(
# 			      $self->get_X()-int($self->get_width()/2), 
# 			      $self->get_Y()-int($self->get_height()/2), 
# 			      $self->get_X()+int($self->get_width()/2), 
# 			      $self->get_Y()+int($self->get_height()/2)
# 			      );
			      
}




=head2 render

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub render {
    my $self = shift;
    my $image = shift;
    
    $self->layout();

    print STDERR "Rendering node ".$self->get_name()."\n";
    my $margin = 5;

    my $fgcolor = $image->colorAllocate($self->get_fgcolor());

    if (@{$self->get_hilite()}==3) { 
	$fgcolor = $image->colorAllocate($self->get_hilite());
    }

    my $bgcolor = $image->colorAllocate($self->get_bgcolor());
    $self->set_width($self->get_font()->width() * length($self->get_name())+ 2*$margin);
    $self->set_height($self->get_font()->height() + 2* $margin);

    print STDERR "Width: ".$self->get_width()."\n";
    print STDERR "Heigh: ".$self->get_height()."\n";

    $image->filledRectangle($self->get_enclosing_rect(), $bgcolor);

    
    $image->rectangle($self->get_enclosing_rect(), $fgcolor );

    $image->string($self->get_font(),
		   $self->get_X()-int($self->get_width()/2)+$margin,
		   $self->get_Y()-int($self->get_height()/2) + $margin,
		   $self->get_name(),
		   $image->colorAllocate(0,0,0) #$fgcolorcolor
		   );

    

    
		   
    
}


=head2 get_image_map

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_image_map {
    my $self = shift;
    
    my $s= "";
    print STDERR "Generating image map for node ".$self->get_name()."\n";
     if ($self->get_url()) { 
	 my $coords = join(", ", ($self->get_enclosing_rect()));
	 my $url = $self->get_url();
	 $s .= qq { <area shape="rect" coords="$coords" href="$url" alt="click" />\n };
 
     }

    return $s;

}



# =head2 add_edge

#  Usage:
#  Desc:
#  Ret:
#  Args:
#  Side Effects:
#  Example:

# =cut

# sub add_edge {
#     my $self = shift;
#     my $edge = shift;
    
#     if (exists($self->{edges}->{$edge->get_name()})) { 
# 	die "All edges must have unique names. ";
#     }
    
#     $self->{edges}->{$edge->get_name()}=$edge;
    
# }

# =head2 get_edges

#  Usage:
#  Desc:
#  Ret:
#  Args:
#  Side Effects:
#  Example:

# =cut

# sub get_edges {
#     my $self = shift;
#     return values(%{$self->{edges}});
# }

# =head2 get_edge_by_name

#  Usage:
#  Desc:
#  Ret:
#  Args:
#  Side Effects:
#  Example:

# =cut

# sub get_edge_by_name {
#     my $self = shift;
#     my $edge_name = shift;
#     return $self->{edges}->{$edge_name};
# }




return 1;
