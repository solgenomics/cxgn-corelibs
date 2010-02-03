=head1 NAME

Phylo - packages for parsing, manipulating, analyzing and drawing trees

=head1 SYNOPSYS

There are four main types of classes: 

=over 5

=item o
 
Parsers, which take a string and produce a Tree object. The parsers should all inherit from the Abstract_tree_parser class. Currently, a parser for Newick formatted trees is available.

=item o 

the Tree and Node classes, defining the trees.

=item o

the Layout classes, which do the tree layout. The layout class should inherit from the Layout class. This is not an abstract class, but the one that lays out the tree in a standard way (from left to right). Subclasses can then take this layout and manipulate it to generate trees with other orientations, etc.

=item o

the Renderer classes, which render an actual image of the tree. The renderer classes should inherit from the Abstract_tree_renderer class.

=back

=head1 AUTHORS

Lukas Mueller (lam87@cornell.edu)

=head1 PACKAGES AND FUNCTIONS

A complete list of packages and functions is given below.

=cut 

use strict;
use GD;
use URI::Escape;

1;

=head1 Package CXGN::Phylo::File

This package reads files of different formats and returns the trees as strings.

=head2 function new()

  Synopsis:	my $file = CXGN::Phylo::File->new( file=> "mytree.tre", type=> "tre")
  Arguments:	a file name
  Returns:	a CXGN Phylo::File object
  Side effects:	opens the file and reads the contents. The contents can be read using the 
                get_tree_string() function.
  Description:	

=cut





package CXGN::Phylo;

=head1 Package CXGN::Phylo::Node

This class deals with the node of a tree. root nodes, intermediate nodes and leaf notes are all represented by the same Node class.

=cut

=head1 LICENSE


Copyright (c) 2002-2006 Sol Genomics Network and Cornell University.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut


