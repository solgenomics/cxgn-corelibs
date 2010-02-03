package CXGN::Phylo::Alignment::Legend;
use base qw( CXGN::Phylo::Alignment::ImageObject);
use strict;
use GD;
use POSIX qw(ceil floor);

=head1 CXGN::Phylo::Alignment::Legend

This class is inherited from ImageObject.  It prints a legend of items (and colors) that have been explicitly set to this object.  Use to provide a legend for highlighted regions on members.  

=head1 Author

C. Carpita <ccarpita@gmail.com>

=head1 Methods

=cut

=head2 new()

  Synopsis:     my $legend = Alignment::Ruler->new(
						  left_margin=>$x, 
						  top_margin=>$y, 
						  width=>$w,
						  height=>$h,
						 );
  Returns:      An Alignment::Legend object

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $self = $class->SUPER::new(@_);

    #set defaults

	$self->{items} = [];
	#push standard item hashes:  { 	"name" => "Whatever", 
#									"color" => [100,140,90], 
#									"x" => [ added by layout() ], 
#									"y" => [ added by layout() ] }


	$self->{item_width} = 120;
	$self->{item_height} = 10;

	$self->{item_spacer} = 14;
	$self->{vertical_spacer} = 14;
	
	$self->{width} = 350;
	$self->{height} = 100;

    return $self;
}

sub add_item {
	my $self = shift;
	my ($name, $color, $url, $tooltip) = @_;
	die "Second argument must be array-ref of three digits [x,y,z]" unless (@$color==3);
	$tooltip =~ s/^null$//i;
	my $hashish = { "name" => $name, "color" => $color, "tooltip" => $tooltip, "url"=> $url };
	push(@{$self->{items}}, $hashish);
}

sub remove_item {
	my $self = shift;
	my $name = shift;
	my @newarray = ();
	foreach(@{$self->{items}}){
		push(@newarray, $_) unless ($_->{name} eq $name);
	}
	$self->{items} = \@newarray;
}

sub layout {
	my $self = shift;
	my $item_count = scalar @{$self->{items}};
	my $max_width = $self->{width};
	my $remaining = $max_width + 1;
	my $total_item_width = $self->{item_spacer} + $item_count*($self->{item_width}+$self->{item_spacer});
	$self->{num_rows} = ceil($total_item_width/$max_width);

	
	$self->{items_per_row} = ceil($item_count/$self->{num_rows});
	$self->{width} = $self->{items_per_row}*($self->{item_width} + $self->{item_spacer}) + $self->{item_spacer};
	$self->{height} = $self->{vertical_spacer}+$self->{num_rows}*($self->{item_height}+$self->{vertical_spacer});


	my $row = 1;
	my @item_array = @{$self->{items}};
	while($row <= $self->{num_rows}){
		my $col = 1;
		my $y = $self->{top_margin} + $self->{vertical_spacer} 
					+ ($row-1)*($self->{vertical_spacer}+$self->{item_height});
		while($col <= $self->{items_per_row}){
			my $x = $self->{left_margin} + $self->{item_spacer} 
					+ ($col-1)*($self->{item_width}+$self->{item_spacer});	
			my $item = shift @item_array;
			if($item){
				#Set *absolute* coordinates of item on image
				$item->{x} = $x;
				$item->{y} = $y;
			}
			$col++;
		}
		$row++;
	}
}

=head2 render()

Synopsis: $legend->render($img) where $img is a image object

Description: draws legend on the image

=cut

sub render {
	my $self = shift;
	my $image = shift;
	my $alignment = shift;
	my $sample_member = shift;

	$self->layout_color(140, 140, 180);
	$self->layout_label_color(100, 100, 100);

	my $color = $image->colorResolve($self->{color}[0], $self->{color}[1], $self->{color}[2]);
	my $label_color = $image->colorResolve($self->{label_color}[0], $self->{label_color}[1], $self->{label_color}[2]);
	#Draw surrounding box	
	
	$image->setStyle($color, gdTransparent);

	$image->rectangle(	$self->{left_margin}, $self->{top_margin}, 
						$self->{left_margin} + $self->{width}, $self->{top_margin} + $self->{height}, 
						gdStyled);

	my $show_base = 0;
	if(ref $sample_member){	
		$show_base = $sample_member->{show_base};
	}

	#Fix height and width of legend, and determine num_rows and items_per_row,
	#and determine (x,y) coords of all items
	$self->layout();

	foreach my $item (@{$self->{items}}) {
		my $item_color = $item->{color};
		if($show_base){ #colors are lightened if base shown, so legend color should match visual
			my @new_color = map{ 255 - (255-$_)*0.4  } @$item_color;
			$item_color = \@new_color;
		}
		$self->_draw_item(	$image, $color, $label_color, 
							$item->{x}, $item->{y}, $item->{name}, $item_color);
	}
}

sub _draw_item {
	my $self = shift;
	my $image = shift;
	my $color = shift;
	my $label_color = shift;
	my ($x, $y, $text, $hilite_color) = @_;
	
	my $h = $self->{item_height};
	my $string_space = $self->{item_width} - 12;
	my $char_num = int($string_space / ($self->{font}->width()));
	my $disp_text = substr($text, 0, $char_num);
	$disp_text .= "." if (length($disp_text) < length($text));
	my @hilite_color = @{$hilite_color};	
	#Draw filled rectangle
	my $fill_color = $image->colorResolve(@hilite_color);
	$image->rectangle($x, $y, $x+10, $y+$h, $color);
	$image->filledRectangle($x+1, $y+1, $x+9, $y+($h-1), $fill_color);	
	
	#Draw text next to rectangle
	$image->string($self->{font}, $x+18, $y-3, $disp_text, $label_color);
}

sub _get_item_enclosing_rect {
	my $self = shift;
	my ($x, $y) = @_;
	return ($x, $y, $x+$self->{item_width}, $y+$self->{item_height});
}

sub get_imagemap_string {
	my $self = shift;
	
	my $area_string = "";
	
	foreach my $item (@{$self->{items}}){
		
		my $coords = join ",", $self->_get_item_enclosing_rect($item->{x}, $item->{y});
		my $url = $item->{url};
		my $title = $item->{tooltip};
		chomp $title;
		$area_string .= <<HTML;
		<area 	shape="rect"
				target="_IPR"
				title="$title"
				coords="$coords"
HTML
		if($url){
				$area_string .= "href=\"$url\"";
		}
				
		$area_string .= ">";
	}
	return $area_string;
}

1;


