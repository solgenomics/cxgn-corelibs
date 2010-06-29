 
=head1 Package CXGN::Phylo::Label

A class to draw labels. 

Labels are drawn relative to a reference point. The label is drawn either on the left or on the right (resp top or bottom) of the reference point, depending on the label position property and the label orientation property. Labels can have links to urls, can be highlighted, and drawn in different draw and background colors.

=cut

use GD;

package CXGN::Phylo::Label;

=head2 function new()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub new { 
    my $class = shift;
    my $args = {};
    my $self=bless $args, $class;

    $self->set_name(shift);
my $n_leaves = shift || 1; 
    $self->set_hilite_color(255,255,255); # i.e. white, the regular non-hilited bg color
    $self->set_line_color(100, 100, 100);
    $self->set_text_color(0, 0, 0);
    $self->set_label_spacer(8);
    $self->align_left();
    $self->set_link("");
    $self->set_font(GD::Font->Small());
$self->set_shown_name_style("short"); 


    return $self;
}

=head2 function set_name_style()

  Synopsis:	 
  Arguments:	 "short" or "long" to specify whether to show whole label name
  Returns:	
  Side effects:	 Controls the name returned by 
  Description:	 Labels style is by default short, i.e. if a leaf represents a collapsed subtree, and 
therefore has multiple names joined together (e.g. AT1G73130.1|AT2G16575.1|AT1G17780.2|AT1G17780.1),
then the short name would be "AT1G73130.|etc."

=cut
sub set_shown_name_style{
	my $self = shift;
	my $style = shift;
	$self->{shown_name_style} = $style;
}

sub get_shown_name_style{
	my $self = shift;
	return $self->{shown_name_style};
}

sub get_shown_name {
#return short or long form of name as specified by shown_name_style
    my $self = shift;
    my $name = $self->get_name();
    # print STDERR "AAAin Label::get_shown_name. [$name] \n";
    my $species = "";
    if ($self->get_shown_name_style() eq "short") {
	if ($name =~ /^(.*)(\[.*\])/) { $name = $1; $species = $2 } # split  name and species
	$name =~ s/^\s+//; # remove any initial whitespace
	# print STDERR "BBBin Label::get_shown_name. [$name] \n";

	my $n_separator = ($name =~ tr/\t//); #count tabs
		
	if ($name =~ /^([^\t]+)\t/) { # shorten name
	    $name = $1 . " + " . $n_separator . " more";
	    # print STDERR "CCCin Label::get_shown_name. [$name] \n";
	    $name .= " " if($species);
	}
	# if ($species) {
	$name .= $species;	
	# }
    }
    
    else { $name =~ s/\t/ / } # tab -> space
    return $name; 
}

=head2 function get_name()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_name { 
	my $self=shift;
	return $self->{name};
}

=head2 function set_name()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_name { 
	my $self=shift;
	$self->{name}=shift;
}

=head2 function set_onmouseover()

  Synopsis:	$a_label->set_onmouseover($javascript);
  Arguments:	$javascript -> js code to set onMouseOver tag to
  Returns:	nothing
  Side effects:	nothing
  Description: Sets the javascript code for onMouseOver to $javascript

=cut
sub set_onmouseover{
    my $self=shift;
    my $script=shift;
    $self->{onmouseover}=$script;
}

=head2 function get_onmouseover()

  Synopsis:	$a_label->get_onmouseover($title,$content,$beginning_js)
  Arguments:
  Returns:	javascript code that needs to be put into the onMouseOver
  Side effects:	nothing
  Description:

=cut      
sub get_onmouseover{
    my $self=shift;
    return $self->{onmouseover};
}
=head2 function set_onmouseout()
Synopsis: $a_label->set_onmouseout($javascript)
Arguments: $javascript: code you want to go into the onmouseout js tag
=cut
sub set_onmouseout{
    my $self=shift;
    $self->{onmouseout}=shift;
}
=head2 function get_onmouseout()
Synopsis: $a_label->get_onmouseout()
Returns: javascript code set for onMouseOut
=cut
sub get_onmouseout{
    my $self=shift;
    return $self->{onmouseout};
}

=head2 function is_hidden()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub is_hidden { 
    my $self=shift;
    return $self->{hidden};
}

=head2 function set_hidden()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_hidden { 
    my $self=shift;
    $self->{hidden}=shift;
}

=head2 function get_hilite()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_hilite { 
    my $self=shift;
    return $self->{hilite};
}

=head2 function set_hilite()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_hilite {	# now being used!
	my $self=shift;
	my $label_hilite = shift;
	$self->{hilite}=$label_hilite;
}

=head2 function get_reference_point()

  Synopsis:	
  Arguments:	
  Returns:	the point of reference that the label is attached to.
  Side effects:	
  Description:	

=cut

sub get_reference_point { 
    my $self=shift;
    return @{$self->{reference_point}};
}

=head2 function set_reference_point()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_reference_point { 
    my $self=shift;
    @{$self->{reference_point}}=@_;
}

=head2 function set_align_right()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub align_right {
    my $self=shift;
    $self->{label_side}="right";
}

=head2 function align_left()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub align_left { 
    my $self=shift;
    $self->{label_side}="left";
}

sub align_center { 
    my $self = shift;
    $self->{label_side}="center";
}

=head2 function get_label_side()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_label_side { 
    my $self = shift;
    return $self->{label_side};
}


=head2 function get_enclosing_rect()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_enclosing_rect { 
    my $self=shift;
    $self->calc_coords();
    return map (int($_), @{$self->{enclosing_rect}});
}

=head2 function set_enclosing_rect()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_enclosing_rect { 
    my $self=shift;
    @{$self->{enclosing_rect}}=@_;
}



=head2 function get_link()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_link { 
    my $self=shift;
    return $self->{link};
}

=head2 function set_link()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_link { 
    my $self=shift;
    $self->{link}=shift;
}

=head2 function get_hilite_color() 

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_hilite_color {  
    my $self=shift;
    return @{$self->{hilite_color}};
}

=head2 function set_hilite_color()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_hilite_color { 
    my $self=shift;
     @{$self->{hilite_color}}= @_;
}

sub get_bg_color{ # bg color is white, unless label is hilited, in which case bg color is hilite color.
	my $self = shift;
	return ($self->get_hilite())? $self->get_hilite_color(): (255, 255, 255);
}

=head2 function get_line_color()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_line_color { 
    my $self=shift;
    return @{$self->{line_color}};
}

=head2 function set_line_color()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_line_color { 
    my $self=shift;
    @{$self->{line_color}}=@_;
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

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_font { 
    my $self=shift;
    $self->{font}=shift;
}

=head2 function get_text_color()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_text_color { 
    my $self=shift;
    return @{$self->{text_color}};
}

=head2 function set_text_color()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_text_color { 
    my $self=shift;
    @{$self->{text_color}}= @_;
}

sub get_tooltip {
	my $self = shift;
	return $self->{tooltip} if $self->{tooltip};
	return "";
}

sub set_tooltip {
	my $self = shift;
	$self->{tooltip} = shift;
}


=head2 function render()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub render { 
    my $self = shift;
    my $image = shift;


    my ($x, $y, $a, $b) = $self->get_enclosing_rect();
    my $line_color = $image->colorResolve($self->get_line_color());
    my $bg_color = $image->colorResolve($self->get_bg_color());
    my $text_color = $image->colorResolve($self->get_text_color());
    $image->filledRectangle($x, $y, $a, $b, $bg_color);

    #print STDERR "Rendering label: ".$self->get_name()." Location: $x, $y. \n";
    $image->string($self->get_font(),  $x, $y, $self->get_shown_name(),$text_color);
}

sub calc_coords { 
    my $self = shift;
    $self->calculate_label_width();
    $self->calculate_label_height();
    my ($rx, $ry) = $self->get_reference_point();
    my ($x, $y, $a, $b);
    if ($self->get_label_side() eq "right" && $self->get_orientation() eq "horizontal") { 
	$x = $rx - $self->get_label_width() - $self->get_label_spacer();
	$y = $ry - $self->get_label_height()/2;
	$a = $x + $self->get_label_width();
	$b = $y + $self->get_label_height();
	#print STDERR "before: calculated label coords: $x, $y, $a, $b\n";
    }
    if ($self->get_label_side() eq "left" && $self->get_orientation() eq "horizontal") { 
	$x = $rx +$self->get_label_spacer();
	$y = $ry - $self->get_label_height()/2;
	$a = $x +$self->get_label_width();
	$b = $y +$self->get_label_height();
	#print STDERR "after:calculated label coords: $x, $y, $a, $b\n";
    }
    if ($self->get_label_side() eq "center" && $self->get_orientation() eq "horizontal") { 
	$x = $rx - $self->get_label_width()/2;
	$y = $ry - $self->get_label_height()/2;
	$a = $x + $self->get_label_width();
	$b = $y + $self->get_label_height();
    }
    # (vertical not yet supported.)

    $self->set_enclosing_rect($x, $y, $a, $b);
}

sub set_orientation_vertical { 
    my $self = shift;
    print STDERR "vertical orientation not yet supported.\n";
}

sub set_orientation_horizontal { 
    my $self = shift;
    $self->{orientation}="horizontal";
}

=head2 function get_label_width()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_label_width { 
    my $self=shift;
    return $self->{label_width};
}

=head2 function set_label_width()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_label_width { 
    my $self=shift;
    $self->{label_width}=shift;
}

sub calculate_label_width { 
    my $self =shift;
    $self->set_label_width( $self->get_font()->width()* length($self->get_name()) );
}

=head2 function get_label_height()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_label_height { 
    my $self=shift;
    return $self->{label_height};
}

=head2 function set_label_height()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_label_height { 
    my $self=shift;
    $self->{label_height}=shift;
}

sub calculate_label_height { 
    my $self = shift;
    $self->set_label_height($self->get_font()->height());
}
    
sub get_orientation { 
    my $self = shift;
    # only horizontal supported at this time.
    return "horizontal";
}

=head2 function get_label_spacer()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_label_spacer { 
    my $self=shift;
    return $self->{label_spacer};
}

=head2 function set_label_spacer()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_label_spacer { 
    my $self=shift;
    $self->{label_spacer}=shift;
}



=head2 function get_html_image_map()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_html_image_map {
    my $self = shift;
    my $s = "";
    if ($self->get_link()) { 
		$s = "<area shape=\"rect\" onmouseover=\"".$self->get_onmouseover()."\" onmouseout=\"".$self->get_onmouseout()."\" coords=\"".(join ",", $self->get_enclosing_rect())."\" href=\"".$self->get_link()."\" alt=\"\" title=\"".$self->get_tooltip."\"/>\n";
    }
    return $s;
}

sub copy { 
    my $self = shift;


}


1;
