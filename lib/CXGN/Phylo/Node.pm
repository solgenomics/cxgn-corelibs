
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

#use CXGN::Phylo::PlainNode;
use base 'CXGN::Phylo::PlainNode';
#our @ISA = 'CXGN::Phylo::PlainNode';

1;
