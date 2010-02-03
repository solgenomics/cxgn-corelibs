#
# Lukas Mueller, July 2004.
#   

our $VERSION = "2.0";

=head1 NAME
    
Cview.pm - objects for the SGN chromosome viewer

=head1 SYNOPSIS

 my $map_image = CXGN::Cview::MapImage -> new($dbh, 500, 600);

 my $map = CXGN::Cview::MapFactory->new($dbh, { map_version_id=>55 });
 my $chr1 = $map->get_chromosome($chr_nr);
 $chr1->set_vertical_offset(50);
 $chr1->set_horizontal_offset(100);
 $chr1->set_height(300);
 $chr1->set_labels_left();
 $chr1->set_display_marker_offset();
 $chr1->set_hilite(50, 100);

 my @m1 = $chr1->get_markers();

 for (my $i=0; $i<@m1; $i++) {
    
    #$m1[$i]->hide();
    $m1[$i]->hide_label();
    if ($i % 5 ==0) { 
	$m1[$i]->hilite(); $m1[$i]->show_label();
    }
 } 

 # adding a ruler
 #
 my $ruler = CXGN::Cview::Ruler -> new (200, 20, 550, 0, $chr1->get_chromosome_length());
 $ruler -> set_labels_right();
 $map -> add_ruler($ruler);
 
 # adding a physical map
 #
 # (same as adding any chromosome, but specify an id for a physical map)


 # rendering the image
 #
 $map_image -> render_jpg();

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 Cview CLASSES

The Cview package defines several objects:

=over 5

=item 1)

A C<MapImage> object that is like a canvas to draw other objects on

=item 2) 

A C<CXGN::Chromosome> object that contains chromosome information, such as markers and links between chromosomes

=item 3) 

A C<CXGN::Marker> object that contains the marker information

=item 4) 

A C<CXGN::ChrLink> object that stores information about markers that are linked on different chromosomes

=item 5) 

A C<CXGN::Ruler> object that draws a ruler

=item 6) 

A C<CXGN::Chromosome::Physical> object, which inherits from chromosome and draws a physical map.

=item 7) 

A C<CXGN::Chromosome::IL> object, which inherits from chromosome, and draws an IL map.

=back

These objects can be placed on the MapImage at will and know how to render themselves using the render() function.

=head1 LICENSE

Copyright (c) 2002-2006 Sol Genomics Network and Cornell University.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

use strict;
use GD;

1;
