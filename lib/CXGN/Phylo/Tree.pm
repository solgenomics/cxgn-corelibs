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

use strict;
use warnings;

use base 'CXGN::Phylo::PlainTree';

1;

