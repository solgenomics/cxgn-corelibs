
use strict;

package CXGN::Sunshine::ImageElement;

sub new { 
    my $class = shift;
    my $self = bless {}, $class;

    $self->set_bgcolor(255,255,255);
    $self->set_fgcolor(0, 0, 0);
    return $self;
}

=head2 accessors get_name, set_name

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_name {
  my $self = shift;
  return $self->{name}; 
}

sub set_name {
  my $self = shift;
  $self->{name} = shift;
}


=head2 get_X, set_X

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_X {
  my $self=shift;
  return $self->{X};

}


sub set_X {
  my $self=shift;
  $self->{X}=int(shift);
}

=head2 get_Y, set_Y

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_Y {
  my $self=shift;
  return $self->{Y};

}

sub set_Y {
  my $self=shift;
  $self->{Y}=int(shift);
}



=head2 get_url

 Usage:        my $url =  $e -> get_url()
 Desc:         accessors for the url propery
 Ret:          a url [string]
 Args:
 Side Effects:
 Example:

=cut

sub get_url {
  my $self=shift;
  return $self->{url};

}

sub set_url {
  my $self=shift;
  my $url = shift;
  $url =~ s/\\//g; 
  $self->{url}=$url;
  print STDERR " **** SET URL $url\n";
}



=head2 get_tooltip

 Usage:
 Property:
 Args:
 Side Effects:
 Example:

=cut

sub get_tooltip {
  my $self=shift;
  return $self->{tooltip};

}

sub set_tooltip {
  my $self=shift;
  $self->{tooltip}=shift;
}

=head2 accessors get_bgcolor, set_bgcolor

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_bgcolor {
  my $self = shift;
  return @{$self->{bgcolor}};
}


sub set_bgcolor {
  my $self = shift;



  @{$self->{bgcolor}} = (shift, shift, shift);
}

=head2 accessors get_fgcolor, set_fgcolor

 Usage:
 Desc:

 Property
 Side Effects:
 Example:

=cut

sub get_fgcolor {
  my $self = shift;
  return @{$self->{fgcolor}};
}

sub set_fgcolor {
  my $self = shift;
  @{$self->{fgcolor}}  = (shift, shift, shift);
}

=head2 accessors get_font, set_font

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_font {
  my $self = shift;
  return $self->{font}; 
}

sub set_font {
  my $self = shift;
  $self->{font} = shift;
}

=head2 accessors get_font_size, set_font_size

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_font_size {
  my $self = shift;
  return $self->{font_size}; 
}

sub set_font_size {
  my $self = shift;
  $self->{font_size} = shift;
}

=head2 accessors get_enclosing_rect

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_enclosing_rect {
  my $self = shift;
  return ($self->get_X()-int($self->get_width()/2), 
	  $self->get_Y()-int($self->get_height()/2),
	  $self->get_X()+int($self->get_width()/2),
	  $self->get_Y()+int($self->get_height()/2));
}

# sub set_enclosing_rect {
#   my $self = shift;
#   my $upper_left_x = shift;
#   my $upper_left_y = shift;
#   my $lower_right_x = shift;
#   my $lower_right_y = shift;

#   @{$self->{enclosing_rect}} = ($upper_left_x, $upper_left_y, $lower_right_x, $lower_right_y);

#   $self->set_width($lower_right_x - $upper_left_x);
#   $self->set_height($lower_right_y - $upper_left_y);
#   $self->set_X(int(($lower_right_x + $upper_left_x) /2));
#   $self->set_Y(int(($lower_right_y + $upper_left_y) /2));


# }

=head2 accessors get_width, set_width

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_width {
  my $self = shift;
  return $self->{width}; 
}

sub set_width {
  my $self = shift;
  $self->{width} = shift;
  #$self->set_enclosing_rect($self->get_X()-int($self->{width}/2), $self->get_Y(), $self->get_X()+int($self->{width}/2));
  
}

=head2 accessors get_height, set_height

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_height {
  my $self = shift;
  return $self->{height}; 
}

sub set_height {
  my $self = shift;
  $self->{height} = shift;
#  my ($ux, $uy, $lx, $y) = $self->get_enclosing_rect();
#  $self->set_enclosing_rect($ux, $self->get_Y()-int($self->{height}/2), $lx, $self->get_Y()+int($self->{height}/2));
}


=head2 accessors get_hilite, set_hilite

 Usage:        $ie -> set_hilite([255, 0, 0]);
 Desc:
 Property:     an arrayref specifying the color
 Side Effects: the element will be hilited using color
 Example:

=cut

sub get_hilite {
  my $self = shift;
  if (! exists($self->{hilite})) { 
      $self->{hilite}= [];
  }
  return $self->{hilite}; 
}

sub set_hilite {
  my $self = shift;
  $self->{hilite} = shift;
}


return 1;
