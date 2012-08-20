package CXGN::Phylo::Tree;

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

use base 'CXGN::Phylo::BasicTree';
use base qw | CXGN::DB::Object |; # needed??

use CXGN::Phylo::Layout;
use CXGN::Phylo::Renderer;

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);
  $self->set_layout( CXGN::Phylo::Layout->new($self) );
  $self->set_renderer( CXGN::Phylo::PNG_tree_renderer->new($self) );
  return $self;
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
    my $self = shift;
    return $self->{layout};
}

sub set_layout {
    my $self = shift;
    $self->{layout} = shift;
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
    my $self = shift;
    return $self->{renderer};
}

sub set_renderer {
    my $self = shift;
    $self->{renderer} = shift;
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

sub render {
    my $self             = shift;
    my $print_all_labels = shift;
    $self->get_renderer()->render($print_all_labels);
}

sub standard_layout {
    my $self   = shift;
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
    my $self             = shift;
    my $file             = shift;
    my $print_all_labels = shift;    ## Boolean for printing non-leaf node labels
    $self->layout();
    my $png_string = $self->render($print_all_labels);
    if ( defined $file ) {
        open( my $T, ">$file" ) || die "PNG_tree_renderer: render_png(): Can't open file $file.";
        print $T $png_string;
        close $T;
    } else {
        return $png_string;
    }
}


1;
