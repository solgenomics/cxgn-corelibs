package CXGN::Phylo::Alignment::ImageObject;

use strict;

=head1 Package CXGN::Phylo::Alignment::ImageObject

The base class for Member, Chart, and Ruler.

Its attributes include: left_margin, top_margin, length (pixel), height (pixel), color, label_color

=cut

=head2 Constructer new()

Usage:     my $img_obj = Alignment::ImageObject->new(
                                                         left_margin=>$x, 
                                                         top_margin=>$y, 
                                                         width  => $z,
                                                         height => $h,
                                                         start_value=>$start_value, 
                                                         end_value=>$end_value
                                                        );

Returns:      a Alignment::ImageObject object

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless {}, $class;
   
	foreach my $key (qw(left_margin top_margin width height label_width label_spacer type)){
		next unless (exists $args{$key});
		$self->{$key} = $args{$key};
	}
    
	$self->{start_value} = $args{start_value};
    $self->{end_value} = $args{end_value};

	$self->{font} = GD::Font->Small();
	#This enforces defaults in subclass, which should be made with layout() in the renderer:
	$self->set_color(-1, -1, -1);
	$self->set_label_color(-1, -1, -1);

    return $self;
}


=head2 Setters and getters

set_left_margin(), set_top_margin, set_color(), set_label_color(), set_width(), set_start_value

get_left_margin(), get_top_margin(), get_label_color(), set_label_color(), get_width(), get_start_value()

=cut

sub set_url {
    my $self = shift;
    $self->{url} = shift;
}

sub get_url {
    my $self = shift;
    return $self->{url};
}

sub set_tooltip {
	my $self = shift;
	$self->{tooltip} = shift;
}

sub get_tooltip {
	my $self = shift;
	return $self->{tooltip};
}

sub set_color {
    my $self = shift;
    ($self->{color}[0], $self->{color}[1], $self->{color}[2]) = @_;
}

sub set_label_color {
  my $self = shift;
  ($self->{label_color}[0], $self->{label_color}[1], $self->{label_color}[2]) = @_;
}

sub set_start_value {
  my $self = shift;
  $self->{start_value} = shift;
}

sub set_end_value {
  my $self = shift;
  $self->{end_value} = shift;
}
  
sub get_start_value {
  my $self = shift;
  return $self->{start_value};
}

sub get_end_value {
  my $self = shift;
  return $self->{end_value};
}

sub get_left_margin { 
    my $self = shift;
    if (!exists($self->{left_margin})) { $self->{left_margin} = 0; }
    return $self->{left_margin};
}

sub set_left_margin { 
    my $self = shift;
    $self->{left_margin} = shift;
}

sub get_top_margin { 
    my $self = shift;
    return $self->{top_margin};
}

sub set_top_margin { 
    my $self = shift;
    $self->{top_margin} = shift;
}

sub get_width { 
    my $self = shift;
    if (!exists($self->{width})) { $self->{width} = 0; }
    return $self->{width};
}


sub set_width { 
  my $self = shift;
  $self->{width} = shift;
}

sub get_height {
  my $self = shift;
  return $self->{height};
}

sub set_height {
  my $self = shift;
  $self->{height} = shift;
}

sub get_label_width {
	my $self = shift;
	my $lw = $self->{label_width};
	$lw||=0;
	return $lw;
}

sub set_label_width {
	my $self = shift;
	$self->{label_width} = shift;
}

sub get_label_spacer {
	my $self = shift;
	return $self->{label_spacer};
}

sub set_label_spacer {
	my $self = shift;
	$self->{label_spacer} = shift;
}

=head2 Layout Functions

 Used to set properties of image objects that have not been explicitly 
 or properly defined by the programmer.  Allows you to define defaults 
 immediately before rendering ImageObjects in any module that uses them.
 
 layout_width(), layout_height(), layout_top_margin(), layout_left_margin(), 
 layout_color(), layout_label_color(), layout_label_width()

=cut

sub layout_width {
	my ($self, $width) = @_;
	$self->{width} = $width unless ($self->{width} && $self->{width} > 0);
}

sub layout_height {
	my ($self, $height) = @_;
	$self->{height} = $height unless (defined $self->{height} > 0);
}

sub layout_label_width {
	my ($self, $label_width) = @_;
	$self->{label_width} = $label_width unless ($self->{label_width} > 0);
}

sub layout_label_spacer {
	my ($self, $spacer) = @_;
	$self->{label_spacer} = $spacer unless (defined $self->{label_spacer});
}

sub layout_top_margin {
	my ($self, $top_margin) = @_;
	$self->{top_margin} = $top_margin unless (defined $self->{top_margin});
}

sub layout_left_margin {
	my ($self, $left_margin) = @_;
	$self->{left_margin} = $left_margin unless defined $self->{left_margin};
}

sub layout_color {
	my ($self, @rgb) = @_;
	my $i = -1;
	while($i<=1){ #0..2
		$i++;
		my $component = $self->{color}[$i];
		next if ($component<=255 && $component>=0);
		$self->{color}[$i] = $rgb[$i];
	}
}

sub layout_label_color {
	my ($self, @rgb) = @_;
	my $i = -1;
	while($i<=1){ #0..2
		$i++;
		my $comp = $self->{label_color}[$i];
		next if ($comp<=255 && $comp>=0);
		$self->{label_color}[$i] = $rgb[$i];
	}
}

=head2 Subs for image display

set_enclosing_rect(), get_enclosing_rect, render(), get_imagemap_string()

=cut
 
sub set_enclosing_rect {
    my $self = shift;
    ($self->get_left_margin(), $self->get_top_margin(), $self->{width}, $self->{height}) = @_;
}

sub get_enclosing_rect {
    my $self = shift;
    return (
		$self->get_left_margin(), 
		$self->get_top_margin(), 
		$self->get_left_margin() + $self->get_width(), 
		$self->get_top_margin() + $self->get_height
		);#to include the label space, $x plus 150 [This is bad form! DEPRECATED.  Override in subclass --carpita]
}
  
sub render {
    my $self = shift;
   	die "You cannot call render() on the abstract ImageObject, subclass please!!!";
}

sub get_imagemap_string {
	my $self = shift;

	my $coords = join ",", ($self->get_enclosing_rect());
	my $string;
	if ($self->get_url()) {  
		my ($url, $id) = ($self->get_url, $self->get_id);
		$string = <<HTML;
<area 	shape="rect" 
		coords="$coords" 
		href="$url" 
		alt="$id"	>
HTML
	}
	return $string;
}

=head3 _calculate scaling_factor()

Synopsis:  $self->_calculate_scaling_factor()

Description: calculate the scaling factor, set the scaling_factor 
attribute and return the scaling factor. Private, should be 
called by the subclass renderer.
 scaling factor = (image pixels) / (sequence distance)

Returns:  a number, scaling factor.

=cut

sub _calculate_scaling_factor {
    my $self = shift;
    my $seq_dist = ($self->{end_value} - $self->{start_value}) + 1;
    if ($seq_dist ==0) { return 0; }
    $self->{scaling_factor} = ($self->get_width()-($self->get_label_width + $self->get_label_spacer))/$seq_dist;
    return $self->{scaling_factor};
}

1;
