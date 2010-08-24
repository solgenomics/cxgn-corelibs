=head1 Package CXGN::Phylo::Text_tree_renderer

Abstract_tree_renderer - an interface to define tree renderers

=head1 DESCRIPTION

=head1 AUTHOR

Lukas Mueller (lam87@cornell.edu)

=cut

=head1 Package Abstract_tree_renderer

This class essentially defines an interface for tree renderers.
It contains two functions: new() and render(). 
Additional functions can be defined as necessary in the derived classes.

=cut 

package CXGN::Phylo::Abstract_tree_renderer;

use GD;
GD::Image->trueColor(1);

=head2 function new()

  Synopsis:	abstract class from which tree renderer can be implemented.
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub new { 
    my $class = shift;
    my $tree = shift;
    my $args = {};
    my $self = bless $args, $class;

    # THE FOLLOWING WAS MOVED TO THE TREE OBJECT:
    # set a default layout object, which is Layout
    # (the tree is rendered from left to right)
    #
    #my $layout_object = CXGN::Phylo::Layout->new($tree);
    #$self->set_layout($layout_object);
    
    $self->set_tree($tree);
    return $self;
}

sub set_tree { 
    my $self = shift;
    $self->{tree}=shift;
}

sub get_tree { 
    my $self = shift;
    return $self->{tree};
}

# =head2 function get_layout()

#   Synopsis:	
#   Arguments:	
#   Returns:	
#   Side effects:	
#   Description:	Accessor for the layout object for this renderer.

# =cut

# sub get_layout { 
#     my $self=shift;
#     return $self->{layout};
# }

# =head2 function set_layout()

#   Synopsis:	
#   Arguments:	an instance of a Layout object or a subclass thereof.
#   Returns:	
#   Side effects:	the layout function determines how the tree is laid out,
#                 the standard way is the root node is placed on the left
#                 and the children on the right. Other layout objects will
#                 lay out trees with other orientations.
#   Description:	setter function for the layout object for this renderer.

# =cut

# sub set_layout { 
#     my $self=shift;
#     $self->{layout}=shift;
# }


    

sub render { 
    die "You are attempting to use the abstract class Abstract_tree_renderer. Please subclass.\n";
}

package CXGN::Phylo::Text_tree_renderer;

use base qw/ CXGN::Phylo::Abstract_tree_renderer /;

sub new { 
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}

=head2 function render()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	a simple rendering of the tree, output to the STDOUT.

=cut

sub render { 
    my $self = shift;
    $self->get_tree()->get_root()->recursive_text_render();
}

=head1 Package CXGN::Phylo::PNG_tree_renderer

Renders tree as PNG

=cut

package CXGN::Phylo::PNG_tree_renderer;

use base qw/ CXGN::Phylo::Abstract_tree_renderer /;

=head2 function new()

  Synopsis:	
  Arguments:	a tree object
  Returns:	An instance of a PNG_tree_renderer object.
  Side effects:	Sets some defaults for drawing the tree.
                These can be overridden by calling the corresponding
                setter functions.
  Description:	

=cut

sub new { 
    my $class = shift;
    my $self = $class -> SUPER::new(@_);
    $self->set_font(GD::Font->Small());
	$self->set_transparent(0);

	$self->{bl_labels} = [];  #need to keep array of these for image map

    return $self;
}

=head2 function get_font()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_font { 
    my $self=shift;
    return $self->{font};
}

=head2 function set_font()

  Synopsis:	$r->set_font($font)
  Arguments:	a GD font
  Returns:	nothing
  Side effects:	$font will be used for rendering the tree labels
  Description:	

=cut

sub set_font { 
    my $self=shift;
    $self->{font}=shift;
}

=head2 function get_font_width

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_font_width { 
    my $self=shift;
    return $self->get_font()->width();
}

=head2 function get_font_height

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_font_height { 
    my $self=shift;
    return $self->get_font()->height();
}

=head2 function get_show_branch_length()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_show_branch_length { 
    my $self=shift;
    return $self->{show_branch_length};
}

=head2 function set_show_branch_length()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_show_branch_length { 
    my $self=shift;
    $self->{show_branch_length}=shift;
}

sub hide_alignment {
	my $self = shift;
	$self->{hide_alignment} = 1;
}

sub show_alignment {
	my $self = shift;
	$self->{hide_alignment} = 0;
}

sub set_transparent {
	my $self = shift;
	$self->{transparent} = shift;
}

sub get_transparent {
	my $self = shift;
	return $self->{transparent};
}

=head2 function render()

  Synopsis:	
  Arguments:    (optional) a boolean for printing labels for all nodes (default- label is printed only for leaves, unless get_hide_label() = true )	
  Returns:      a png image
  Side effects:	creates a GD::Image object and renders the tree on it.
  Description:	draws the tree

=cut

sub render { 
	my $self = shift;
	my $print_all_labels=shift;
#	GD::Image->trueColor(1);
	# initialize image   
	my $tree = $self->get_tree;
	my $layout = $tree->get_layout;	
	$layout->layout();
	my ($phylo_width, $phylo_height) = ($layout->get_image_width, $layout->get_image_height);
	

	my $image = GD::Image->new($phylo_width,$phylo_height, 1);
	my $white = $image->colorResolve(255,255,255);
#  	if($self->{transparent}){	
#  		$image->transparent($white);
#  	}
	$image->filledRectangle(0 , 0, $phylo_width, $phylo_height, $white);
	$tree->get_root()->recursive_propagate_properties();
	# get the font
	#
	my $font = GD::Font->Small();
	if ($layout->get_vertical_gap()<12) { 
		$font= GD::Font->Tiny();
	}
	$self->set_font($font);
	# percolate font information to all nodes
	foreach my $n ($tree->get_all_nodes()) { 
		$n->get_label()->set_font($self->get_font);
	}

	my $color = $image->colorResolve($tree->get_line_color());

	if ($tree->get_alignment && !$self->{hide_alignment}) {
		my $alignment = $tree->get_alignment;
		my $partition_width;
		if($alignment->{label_shown}){
			$partition_width = $phylo_width/3;
		}
		else {
			$partition_width = $phylo_width/2;
		}
		print STDERR "Showing Alignment...\n";
		
		#Calculate node coordinates:		
		$layout->set_image_width($partition_width);
		$layout->layout();

		#Set Alignment Image attributes


		$alignment->set_image($image);
		$alignment->set_display_type("alignment"); #alignment and ruler only
		$alignment->set_left_margin($partition_width+5);
		my $label_spacer = 5;
		my $gap = $label_spacer;
# 		if($alignment->{label_shown}){
# 			$gap = $alignment->_calculate_label_gap + $label_spacer;
# 		}
		$alignment->set_width($partition_width);
		$alignment->set_height($layout->get_image_height);
		$alignment->_add_ruler();
		$alignment->{width_adjustment} = 0;
		$alignment->_add_ruler();
		$alignment->{ruler}->set_width($partition_width-$gap);
		$alignment->{ruler}->set_label_spacer($label_spacer);
		$alignment->{ruler}->hide_unit();
		$alignment->{ruler}->set_top_margin($alignment->{ruler}->{font}->height());
			
		my %member_is_shown = ();
		#Position each alignment member
		foreach my $leaf ($tree->get_leaf_list()) {
			my $m = $leaf->get_alignment_member;
			next unless $m;
			$m->set_width($partition_width-$gap);
			$m->set_label_spacer($label_spacer);
			my $height = $layout->get_vertical_gap;
#			$height = 20 if($height>20);
			$m->set_height($height);
			$m->set_top_margin($leaf->get_Y);
			my $id = $m->get_id;
			$member_is_shown{$id} = 1;
		}

		foreach my $m (@{$alignment->{members}}){
			my $id = $m->get_id;
			$m->hide_seq unless $member_is_shown{$id};
		}
		
		#Render the alignment on the set image
		$alignment->render();	
	}
	$self->recursive_draw($tree->get_root(), $image, $color, "", $print_all_labels );
	return $image->png();
}



sub recursive_draw { 
	my $self = shift;
	my $node = shift;
	my $image = shift;
	my $color = shift;
	my $parent_hilited = shift;
	my $print_all_labels=shift;

	my $line_color = $color;

	my @children = $node->get_children();

	#print STDERR "Node: ".$node->get_name()." X: ".$node->get_X()." Y: ".$node->get_Y()."\n";

	# generate the color for the clickable area of the nodes
	#
	my $node_color = $image->colorResolve(150,150,250); # color for normal (non-hilited) nodes
    
	# get the hilite color for the hilited nodes
	#
#	print STDERR "name: ", $node->get_name(), "node implicit names:[", join(":", $node->get_implicit_names()), "] speciation:[", $node->get_attribute("speciation"), "]     ";
	if ($node->get_hilited() ){ #or $node->get_attribute("speciation") ) { 
		$color = $image->colorResolve($self->get_tree()->get_hilite_color()); # this is the color of the hilited subtree
		if (!$parent_hilited or $node->get_attribute("speciation")) {
			#Original Hilited Node
			my @hcolor = $self->get_tree()->get_hilite_color();
			my $max = 0;
			#Saturate the predominant color component
			foreach (@hcolor) {
				$max = $_ if $_>=$max;
			}
			foreach (@hcolor) {
				if ($_>=$max) {
					$_ = 255;
				} else {
					$_ *= 0.6;
				}
			}
			$node_color = $image->colorResolve(@hcolor); # color of root of hilited subtree (bright red)
		} else {
			$node_color = $color; # color of rest of hilited subtree (dull red)
		}
	}

	if ($node->is_root()) { 
		my @line_color = $node->get_line_color();
	#	print STDERR "line color: ", join(";", @line_color), "\n";
		$line_color = $image->colorResolve(@line_color) if (@line_color==3);
		my $model = $node->get_attribute("model");
		if ($model) {
			my $color_array = $self->get_model_color($model);
			$line_color = $image->colorResolve(@$color_array) if (ref($color_array) eq "ARRAY");
		}
		$line_color = $color if $node->get_hilited();		
		$self->connect_nodes(undef, $node, $image, $line_color); 
	}

	unless($node->get_hidden()){# (don't draw children of hidden nodes)
		foreach my $c (@children) {
			my @line_color = $c->get_line_color();
			$line_color = $image->colorResolve(@line_color) if (@line_color==3);
			my $model = $c->get_attribute("model");
			if ($model) {
				my $color_array = $self->get_model_color($model);
				$line_color = $image->colorResolve(@$color_array) if (ref($color_array) eq "ARRAY");
			}
			$line_color = $color if $node->get_hilited();	 
		#	print STDERR "line color: ", join(";", @line_color), "\n";
			$self->connect_nodes($node, $c, $image, $line_color);
			$self->recursive_draw($c, $image, $color,$node->get_hilited(), $print_all_labels);
		}
	}
	
	if (!($node->is_leaf() || ($node->is_hidden()))) {
	    $image -> filledRectangle(($node->get_X()-2), ($node->get_Y()-2), 
				      ($node->get_X()+2), ($node->get_Y+2), $node_color);
	} elsif ($node->is_leaf()) { 
	    $image -> filledArc(($node->get_X()), ($node->get_Y()), 7, 7, 0, 360, $node_color);
		#	my $label = $node->get_label;
		#		my $layout = $self->get_tree()->get_layout();
		#		my $begin_x = $label->{font}->width()*length($label->get_name()) + $node->get_X + 5;
		#		$begin_x = int($begin_x);
		#		$image->line($begin_x, $node->get_Y, $begin_x+50, $node->get_Y, $node_color);

	}
	
	# if the node is hidden, draw the hidden symbol
	#
	if ($node->get_hidden()) {
		$image -> rectangle(($node->get_X()-3), ($node->get_Y()-3),
												($node->get_X()+3), ($node->get_Y()+3), $color);

		$image -> line(($node->get_X()), ($node->get_Y()-2),
									 ($node->get_X()), ($node->get_Y()+2), $color);
		$image -> line(($node->get_X()-2), ($node->get_Y()),
									 ($node->get_X()+2), ($node->get_Y()), $color);
	}

	# draw the label if it it visible
	#
	if ( (!$node->get_hide_label() and $node->is_leaf()) || $print_all_labels ) { 	
	    $node->get_label()->set_reference_point(($node->get_X()), ($node->get_Y()));
	    if (!$node->is_leaf() && $node->get_children() % 2 > 0) { 
		$node->get_label()->set_reference_point(($node->get_X()), ($node->get_Y()-1-$node->get_label()->get_font()->height/2));
	    }
	    $node->get_label()->set_orientation_horizontal();
	    $node->get_label()->render($image);	
	}
}

=head2 function connect_nodes()

  Synopsis:	
  Arguments:	a parent node object, a child node object, a GD image object and a GD color
  Returns:	
  Side effects:	draws the connection between a parent and a child node.
  Description:	the default style is a connection that is broken into to perpendicular
                lines. This can be overridden in subclasses to draw different
                styles of trees

=cut

sub connect_nodes { 
    my $self = shift;
    my $p_node = shift;
    my $c_node = shift;
    my $image = shift;
    my $color = shift;
    
    if (!$p_node) { 
		$p_node=$c_node->copy();
		$p_node->set_X($self->get_tree()->get_layout()->get_left_margin());
    }
    $self->display_branch_length($image, $p_node, $c_node, $color);
	$image->setAntiAliased($color);
    $image -> line ($p_node->get_X(), $p_node->get_Y(), 
		    $p_node->get_X(), $c_node->get_Y(), $color);
    
    $image -> line ($p_node->get_X(), $c_node->get_Y(), 
		    $c_node->get_X(), $c_node->get_Y(), $color);
   
}

sub display_branch_length { 
    my $self = shift;

    # if we are supposed to display the branch lengths, we do so...
	return unless $self->get_show_branch_length();

    my $image = shift;
    my $p_node = shift;
    my $c_node = shift;
	my $color = shift;


	my $label_text = $c_node->get_branch_length();
	my $branch_length_label = CXGN::Phylo::Label->new($label_text);


		my @color = (200, 200, 200);
		my $blc_sum = 300; # the branch length color will be the branch color normalized s.t. sum of r,g and b = blc_sum; so make this smaller if branch lengths are too light to read easily
		if ($color) {
			@color = $image->rgb($color);
			my $bc_sum = ($color[0] + $color[1] + $color[2]);
			my $norm_factor = ($bc_sum == 0)? 1: $blc_sum/$bc_sum;
			$norm_factor = 1 if($norm_factor > 1);
			@color = map { $_*$norm_factor } @color; #branch color normalized to have sum of r,g,b=tsum
	
			my $model = $c_node->get_attribute("model");
			if ($model =~ /\w+/) {
				$branch_length_label->set_tooltip("Calculated by " . ucfirst($model) . " model");
			}
		}

	$branch_length_label->set_reference_point( 
		$self->get_blen_ref_pt($p_node, $c_node, $label_text) 
		);
	$branch_length_label->set_font(GD::Font->Tiny());
	$branch_length_label->set_hidden(0);
	$branch_length_label->align_center();
	$branch_length_label->set_text_color(@color);
	
	$branch_length_label->render($image);

	push(@{$self->{bl_labels}}, $branch_length_label);
}

sub get_blen_ref_pt {
	my $self = shift;
	my $p_node = shift;
	my $c_node = shift;
my $bl_scaled = ($c_node->get_transformed_branch_length($self->get_tree()->get_shown_branch_length_transformation()) * $self->get_tree()->get_layout()->get_horizontal_scaling_factor());
	return (
					$c_node->get_X()-$bl_scaled/2,
					$c_node->get_Y()-$self->get_font_height()/2
				 );
}


sub hilite_model {
	my $self = shift;
	my $model = shift;
	my $color_array = shift;
	$self->{model_colors}->{$model} = $color_array;
}

sub get_model_color {
	my $self = shift;
	my $model = shift;
	my $color_array = $self->{model_colors}->{$model};
	return unless (ref($color_array) eq "ARRAY");
	return $color_array if (@$color_array == 3);
}

=head2 function get_html_image_map()
    
 Synopsis:	my $image_map=$renderer->get_html_image_map($name, $temp_filename, $hilite_temp, $align_type );
 Arguments:	image_map name, filename
 Returns:	a html imagemap that can be used to embed links into the tree image.
 Side effects:	
 Description:	use $node->set_link($url) to set the link to $url.
    
=cut

sub get_html_image_map { 
#    print STDERR "PNG_tree_renderer: in: get_html_image_map()\n";
    my $self=shift;
    my $name =shift;
	my ($whole_temp, $hilite_temp, $align_type) = @_;
    my $map = $self->recursive_image_map_coords($self->get_tree()->get_root());
	my $tree = $self->get_tree();

	#Image Map portion for Alignment, if align temp file provided:	
	if($tree->get_alignment && $whole_temp){
		$hilite_temp = $whole_temp unless $hilite_temp;
		foreach my $l ($tree->get_leaf_list){
			my $m = $l->get_alignment_member();
			next unless $m;
			my $temp = "";
			my $title = "";
			($l->get_hilited)?($temp = $hilite_temp):($temp = $whole_temp);
			($l->get_hilited)?($title = "See alignment for highlighted region only"):($title = "See alignment for all visible members");

			($temp) = $temp =~ /([^\/]+)$/;
			my $coords = join ",", ($m->get_enclosing_rect);
			my $url = "/tools/align_viewer/show_align.pl?temp_file=$temp&type=$align_type&title=Selection%20From%20Tree";
			my $target = "_SGN_ALIGN_" . int(rand(999999999));
			$map .= "\n<area target=\"$target\" coords=\"$coords\" href=\"$url\" title=\"$title\" \\>";
		}
	}
	foreach my $bl_label (@{$self->{bl_labels}}){
		next unless $bl_label->get_tooltip();
		my $coords = join ",", ($bl_label->get_enclosing_rect);
		print STDERR "--------RENDERED.PM------". $bl_label->get_onmouesover()."------";
		$map .= "\n<area coords=\"$coords\" title=\"hey yo\" \\>";
	}

    my $maptag = qq( <map name="$name">\n$map</map>\n );
    return $maptag;
}

sub recursive_image_map_coords { 
    my $self = shift;
    my $node =shift;

	my $tooltip = $node->get_tooltip();
	$tooltip ||= "Node " . $node->get_node_key() . ": " . $node->get_label()->get_name();
    #print STDERR "RECURSIVE_IMAGE_MAP_COORDS\n";
    my $map = do { no warnings 'uninitialized';
		"<area shape=\"rect\" id = \"".$node->get_name()."\" coords=\""
		. int(($node->get_X())-3) . ",".int(($node->get_Y())-3).",".int(($node->get_X())+3).",".int(($node->get_Y())+3)
		. "\" href=\"".$node->get_link()
		."\" title=\"$tooltip\" onmouseover=\"".$node->get_onmouseover()."\" onmouseout=\"".$node->get_onmouseout()."\" alt=\"$tooltip\" />\n"};
 
    $map .= $node->get_label()->get_html_image_map();
    my @children = $node->get_children();
    foreach my $c (@children) { 
		#print STDERR "checking out the children...\n";
		$map .= $self->recursive_image_map_coords($c);
    }
    return $map;
}



package CXGN::Phylo::PNG_angle_tree_renderer;

use GD;

use base qw/ CXGN::Phylo::PNG_tree_renderer /;

sub new { 
    my $class = shift;
    my $self = $class -> SUPER::new(@_);
    return $self;
}

sub connect_nodes { 
    my $self = shift;
    my $p_node= shift;
    my $c_node = shift;
    my $image = shift;
    my $color = shift;

	
    if (!$p_node) { 
		$p_node=$c_node->copy();
		$p_node->set_X($self->get_tree()->get_layout()->get_left_margin());
    }
    $self->display_branch_length($image, $p_node, $c_node, $color);
	$image->setAntiAliased($color);
    $image->line ($p_node->get_X(), 
		    $p_node->get_Y(), 
		    $c_node->get_X(), 
		    $c_node->get_Y(),gdAntiAliased);
    
    
    
}

sub get_blen_ref_pt {
	my ($self, $p_node, $c_node, $text) = @_;

	my ($dx, $dy) = ($c_node->get_X() - $p_node->get_X(),  abs($c_node->get_Y()-$p_node->get_Y()));
	my $angle = atan2($dy, $dx);
	my $pi = 3.14159265359;
	my $max = $pi/2;
	my $halfw = (length($text)*$self->get_font()->width)/3;
	my $x_shift = -$halfw*($angle)/$max;
	
	my $flip = 1;
	$flip = -1 if ($c_node->get_Y() > $p_node->get_Y());


my $bl_scaled = ($c_node->get_transformed_branch_length($self->get_tree()->get_shown_branch_length_transformation()) * $self->get_tree()->get_layout()->get_horizontal_scaling_factor());

	return (
					$c_node->get_X() - $bl_scaled/2 + $x_shift,
					($c_node->get_Y()+$p_node->get_Y())/2 - $flip*$self->get_font_height()/2
				 );
}

package CXGN::Phylo::PNG_round_tree_renderer;
use GD;
use base qw/ CXGN::Phylo::PNG_tree_renderer /;
sub new { 
    my $class = shift;
    my $self = $class -> SUPER::new(@_);
    return $self;
}

sub connect_nodes { 
    my $self = shift;
    my $p_node= shift;
    my $c_node = shift;
    my $image = shift;
    my $color = shift;


    if (!$p_node) { 
	$p_node=$c_node->copy();
	$p_node->set_X($self->get_tree()->get_layout()->get_left_margin());
    }

    $self->display_branch_length($image, $p_node, $c_node, $color);

    $image->setAntiAliased($color);
    $image -> arc($c_node->get_X(),
		  $p_node->get_Y(),  
		  ($c_node->get_X()-$p_node->get_X())*2, 
		  ($p_node->get_Y()-$c_node->get_Y())*2, 
		  180, 
		  270, 
		  gdAntiAliased 
		  );    
}

sub get_blen_ref_pt {
	my ($self, $p_node, $c_node, $text) = @_;
	my ($dx, $dy) = ($c_node->get_X() - $p_node->get_X(),  abs($c_node->get_Y()-$p_node->get_Y()));
	my $angle = atan2($dy, $dx);
	my $pi = 3.14159265359;
	my $max = $pi/2;
	my $halfw = (length($text)*$self->get_font()->width)/2;
	my $x_shift = -$halfw*($angle)/$max;

	my $flip = 1;
	$flip = -1 if ($c_node->get_Y() > $p_node->get_Y());

	#Try putting at "center of mass" of right triangle:
	return ( $p_node->get_X()+($c_node->get_X() - $p_node->get_X())/3 +$x_shift,
			$c_node->get_Y()-($c_node->get_Y() - $p_node->get_Y())/3 - $flip*($self->get_font()->height()/2) );
}

1;
