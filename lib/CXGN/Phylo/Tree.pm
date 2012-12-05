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

# <<<<<<< HEAD
use CXGN::Phylo::Layout;
use CXGN::Phylo::Renderer;

sub new {
  my $class = shift;
  my $self  = bless {}, $class;    # ->SUPER::new(@_);
 my $arg           = shift;
#print STDERR "class: $class;  arg: [$arg]\n";
  $self->set_root( CXGN::Phylo::Node->new() ); # initialize the root node
  $self->init($arg);		# initialize some fields with defaults

#print STDERR "ref(self) in Tree constructor: ", ref($self), "\n";
#print STDERR "ref(root) in Tree constructor: ", ref($self->get_root()), "\n";

  $self->set_layout( CXGN::Phylo::Layout->new($self) );
  $self->set_renderer( CXGN::Phylo::PNG_tree_renderer->new($self) );

print STDERR 'bottom of Tree->new; ref($self): ', ref($self), "\n" if(ref($self) ne 'CXGN::Phylo::Tree');
  return $self;
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
    my $new  = $self->get_root()->copy_subtree();
    $new->update_label_names();
    return $new;
}

sub _tree_from_newick {
    my $newick_string = shift;
    $newick_string =~ s/\s//g;      # remove whitespace from newick string
    $newick_string =~ s/\n|\r//g;
    if ( $newick_string =~ /^\(.*\)|;$/ ) {
        my $parser = CXGN::Phylo::Parse_newick->new( $newick_string, $do_parse_set_error );
        print "parsing tree in Tree::_tree_from_newick\n";
        my $tree = $parser->parse( CXGN::Phylo::Tree->new("") );
        return $tree;
    } elsif ($newick_string) {
        print STDERR "String passed not recognized as newick\n";
        return undef;
    }
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

sub decircularize {
    my $self = shift;
    $self->get_root()->recursive_decircularize();
    $self->set_renderer(undef);
    $self->set_layout(undef);
}

1;

