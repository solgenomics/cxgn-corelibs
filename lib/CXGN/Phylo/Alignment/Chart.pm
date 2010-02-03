package CXGN::Phylo::Alignment::Chart;
use base qw( CXGN::Phylo::Alignment::ImageObject);
use GD;
use strict;

=head1 Package CXGN::Phylo::Alignment::Chart

Inherit from ImageObject.  Its special attributes include id and similarity_hash.  The keys of the hash is position and the vaule is a percentage.

=cut

=head2 Constructer new()

  Synopsis:     my $chart= CXGN::Phylo::Alignment::Chart->new(
                                                 left_margin=>$x, 
						 top_margin=>$y, 
						 length=>$z,
						 height=>$h,
						 start_value=>$start_value, 
						 end_value=>$end_value
                                                 id=>id,
                                                 similarity_hash=>$similarity_hash_ref
                                                 );
  Returns:      a Alignment::Chart object

=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $self = $class->SUPER::new(@_);
	
	$self->{id} = $args{id};
	$self->{similarity_hash} = $args{similarity_hash};
	$self->{conservation_hash} = $args{conservation_hash};
	$self->{type_hash} = $args{type_hash};
	$self->{hide} = 'no';
	$self->set_conservation_color(-1, -1, -1);
	$self->set_hilite_color(-1, -1, -1);

	$self->{color} = [110, 110, 180];
	$self->{type_color} = [180, 120, 60];
	$self->{hilite_color} = [180, 50, 50];
	$self->{conservation_color} = [100, 50, 120];

	$self->{coverage_label} = "Coverage %";
	$self->{conservation_label} = "Base Conservation";
	$self->{type_label} = "Type Conservation";
	$self->{full_cons_label} = "Full Conservation";

	return $self;
}

=head2 Setters and getters

set_id(), get_id(), set_similarity_hash(), get_similarity_hash()

Nothing special

=cut

sub get_longest_label_width {
	my $self = shift;
	my $max = 0;
	foreach(qw(coverage_label conservation_label full_cons_label type_label)){
		my $label = $self->{$_};
		$max = length($label) if (length($label)>$max);
	}
	return $self->{font}->width()*$max;
}


sub set_id {
  my $self = shift;
  $self->{id} = shift;
}

sub get_id {
  my $self = shift;
  return $self->{id};
}

sub get_orientation {
	my $self = shift;
	return $self->{orientation};
}

sub set_orientation {
	my $self = shift;
	my $o = lc ( shift );
	die "Orientation must be set 'd(own)' or 'u(p)'" unless $o =~ /^(u|d)/;
	$self->{orientation} = $o;
}

sub get_conservation_color {
	my $self = shift;
	return @{$self->{conservation_color}};
}

sub set_conservation_color {
	my $self = shift;
	@{$self->{conservation_color}} = @_;
}

sub get_hilite_color {
	my $self = shift;
	return @{$self->{hilite_color}};
}

sub set_hilite_color {
	my $self = shift;
	@{$self->{hilite_color}} = @_;
}

sub set_similarity_hash {
  my $self = shift;
  $self->{similarity_hash} = shift;
}


sub get_similarity_hash {
  my $self = shift;
  return $self->{similarity_hash};
}

=head2 Image displaying sub

render()

=cut

=head 3 render()

Synopsis: $chart->render($img) where $img is an image object

Description: it draws a base line and a 100% line from start_value to end_value.  Then it get all the hash elements whose keys are in the reange from strt_value to end_value and draw a rectangle reprensting the vlaue.

Returns:

=cut

sub render {
	my $self = shift;
	my $image = shift;
	
	my %coverage_hash = %{$self->{similarity_hash}};
	my %conservation_hash = %{$self->{conservation_hash}};
	my %type_hash = %{$self->{type_hash}};

	#Only has an effect if they haven't been set already:
	$self->layout_color(110, 110, 180);
	$self->layout_label_color(0, 0, 0);
	$self->layout_label_spacer(20);
	$self->layout_height(40);


	my $color = $image->colorResolve($self->{color}[0], $self->{color}[1], $self->{color}[2]);
	my $coverage_color = $color;
	my $conservation_color = $image->colorResolve($self->get_conservation_color);
	my $hilite_conservation_color = $image->colorResolve($self->get_hilite_color);

	my @cons_label_rgb = map { 0.7 * $_ } @{$self->{conservation_color}};
	my $cons_label_color = $image->colorResolve(@cons_label_rgb);
	my @label_rgb = map { 0.7 * $_ } ($self->{label_color}[0], $self->{label_color}[1], $self->{label_color}[2]);	
	my $label_color = $image->colorResolve(@label_rgb);
	
	my $seq_id = $self->{id};
	$self->_calculate_scaling_factor();

	$image->line(
		$self->{left_margin}, $self->{top_margin}, 
		$self->{left_margin} + $self->{width} - $self->{label_spacer}, $self->{top_margin}, 
		$color	); #Draw the 0% line

	$image->line(
		$self->{left_margin}, $self->{top_margin} + $self->{height}, 
		$self->{left_margin} + $self->{width} - $self->{label_spacer}, $self->{top_margin} + $self->{height}, 
		$color	); #Draw the 100% line
		  
	my ($i, $adjust_i);
	my @deferred_draw = (); #we want the 100% conserved rectangles to not be pixel-squished (over-drawn), so draw them last
	for ($i = $self->{start_value} - 1; $i < $self->{end_value}; $i++){

		(!defined $coverage_hash{$i}) and ($coverage_hash{$i} = 0);
		(!defined $conservation_hash{$i}) and ($conservation_hash{$i} = 0);
		(!defined $type_hash{$i}) and ($type_hash{$i} = 0);
		$adjust_i = $i - $self->{start_value} + 1; #adjust left margin according to start_value

		#Coverage exists and coverage % == conservation %
		if($coverage_hash{$i} && $coverage_hash{$i}==$conservation_hash{$i}){
			push(@deferred_draw, $i);
			next;
		}
		$self->_draw_data_point($image, $adjust_i, $coverage_hash{$i}, $conservation_hash{$i}, $type_hash{$i}, $coverage_color, $conservation_color);
	}
	my $max_adjust_i = $adjust_i;
	foreach(@deferred_draw){
		$adjust_i = $_ - $self->{start_value} + 1;
		$self->_draw_data_point($image, $adjust_i, $coverage_hash{$_}, $conservation_hash{$_}, $type_hash{$_}, $coverage_color, $hilite_conservation_color);
	}

	#add sequence name, first chop the sequence name to up to 30 characters. add '..' if the name is longer
	my $displayed_id; ;
	if ((length ($self->{id})) >= 30) {
		 $displayed_id = substr ($self->{id}, 0, 30);
		 $displayed_id .= '..';
	 }
	else {
		$displayed_id = $self->{id};
	}

	$self->{seq_line_width} ||= 0;

	$image->string(
		$self->{font}, 
		($max_adjust_i + 1) *$self->{scaling_factor}+ $self->{left_margin} + $self->{label_spacer}, 
		$self->{top_margin} - $self->{seq_line_width} / 2, 
		$self->{coverage_label}, 
		$coverage_color);
	
	
	my $type_color = $image->colorResolve(@{$self->{type_color}});
	$image->string(
		$self->{font}, 
		($max_adjust_i + 1) *$self->{scaling_factor}+ $self->{left_margin} + $self->{label_spacer}, 
		$self->{top_margin} - $self->{seq_line_width} / 2 + ($self->{font}->height() + 2), 
		$self->{type_label},
		$type_color) if ($self->{type} eq 'pep');


	$self->{conservation_label} = "AA Conservation" if ($self->{type} eq "pep");
	$image->string(
		$self->{font}, 
		($max_adjust_i + 1) *$self->{scaling_factor}+ $self->{left_margin} + $self->{label_spacer}, 
		$self->{top_margin} - $self->{seq_line_width} / 2 + 2*$self->{font}->height() + 2, 
		$self->{conservation_label}, 
		$conservation_color);
	

}

sub _draw_data_point {
	my $self = shift;
	my $orient = $self->get_orientation;
	my $image = shift;
	my ($x_coord, $coverage_value, $conservation_value, $type_value, $coverage_color, $conservation_color) = @_;

	my $type_color = $image->colorResolve(@{$self->{type_color}});
	if(defined $orient && $orient =~ /^d/i){
		$image->filledRectangle(
				$x_coord*$self->{scaling_factor}+$self->{left_margin}, $self->{top_margin},  
				($x_coord+1)*$self->{scaling_factor}+$self->{left_margin}, $self->{top_margin}+(($coverage_value/100)*$self->{height}), 
				$coverage_color	
		);
		$image->filledRectangle(
				$x_coord*$self->{scaling_factor}+$self->{left_margin}, $self->{top_margin},  
				($x_coord+1)*$self->{scaling_factor}+$self->{left_margin}, $self->{top_margin}+(($type_value/100)*$self->{height}), 
				$type_color	
		) if ($type_value>0);

		$image->filledRectangle(
				$x_coord*$self->{scaling_factor}+$self->{left_margin}, $self->{top_margin},  
				($x_coord+1)*$self->{scaling_factor}+$self->{left_margin}, $self->{top_margin}+(($conservation_value/100)*$self->{height}), 
				$conservation_color	
		) if ($conservation_value>0);

	}
	else {
		$image->filledRectangle(
				$x_coord*$self->{scaling_factor}+$self->{left_margin},   
					$self->{top_margin} + (((100-$coverage_value)/100)*$self->{height}),
				($x_coord+1)*$self->{scaling_factor}+$self->{left_margin},
                   $self->{top_margin} + $self->{height},
				$coverage_color
		);

		$image->filledRectangle(
				$x_coord*$self->{scaling_factor}+$self->{left_margin},   
					$self->{top_margin} + (((100-$type_value)/100)*$self->{height}),
				($x_coord+1)*$self->{scaling_factor}+$self->{left_margin},
                   $self->{top_margin} + $self->{height},
				$type_color
		) if ($type_value>0);

		$image->filledRectangle(
				$x_coord*$self->{scaling_factor}+$self->{left_margin},   
					$self->{top_margin} + (((100-$conservation_value)/100)*$self->{height}),
				($x_coord+1)*$self->{scaling_factor}+$self->{left_margin},
                   $self->{top_margin} + $self->{height},
				$conservation_color
		) if ($conservation_value>0);
	}
}


1;
