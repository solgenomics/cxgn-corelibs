package CXGN::Image::GDImage;
use strict;
=head1 NAME

CXGN::Graphics::GDImage.pm

=cut

=head1 SYNOPSIS

An extender (not wrapper yet) for the GD image object, provides a general base of abstract tools like conversions of whole images to greyscale, levels operations (Photoshop-style), merging of color indices, and anything you would like to add. 

=cut

=head1 USAGE

use GD; 

use CXGN::Graphics::GDImage;

my $imgh = CXGN::Graphics::GDImage->new();

$imgh->{image} = GD::Image->newFromPng("/document/img/external.png");
OR
$imgh->{image} = GD::Image->new(640, 480);

Afterwards, you can work on the image directly from the handle, or do:

my $image = $imgh->{image};

$image->colorAllocate(245, 245, 245);

$image->....etc...;

$imgh->{image} = $image;  #important: if you pop out the image, pop it back in before doing a handle operation

$imgh->greyscale();  

print $imgh->{image}; 

=cut

=head1 AUTHOR

Christopher Carpita <csc32@cornell.edu>

=cut

=head2 new

Creates a handle, does NOT create the GD image, YOU have to do that
with $self->{image} = GD::Image->new();

=cut

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	$self->{image} = 0;	#set this manually from calling script!
	return $self;
}

=head2 greyscale

Converts the image on the handle to greyscale

=cut

sub greyscale {
	my $self = shift;
	my $im = $self->{image};
	my $max_index = $im->colorsTotal;
	my $trans_index = $im->transparent;
	my $i = 0;
	while ($i < $max_index) {
		if($i==$trans_index) { $i++; next }
    	my ($r, $g, $b) = $im->rgb($i);
		my $avg = ($r + $g + $b)/3;
		$im->colorDeallocate($i);
		$im->colorAllocate($avg, $avg, $avg);
		$i++;
	}
	$self->{image} = $im;
}

sub adjust_brightness {
	my $self = shift;
	my $delta = int( shift );
	if(!$delta) { return }
	unless($delta<=100 && $delta>=-100) { die "Provided adjustment must be in the range [-100, 100]" }
	my $im = $self->{image};
	my $max_index = $im->colorsTotal;
	my $trans_index = $im->transparent;
	my $i = 0;
	while ($i < $max_index) {
		if($i==$trans_index) { $i++; next }
    	my ($r, $g, $b) = $im->rgb($i);
		if($delta <= 0) {
			foreach ($r, $g, $b) {
				$_ = int(((100 + $delta)/100)*$_);
			}
		}
		elsif($delta > 0) {
			foreach ($r, $g, $b) {
				$_ = int(255 - ((100 - $delta)/100)*(255-$_));
			}
		}
		$im->colorDeallocate($i);
		$im->colorAllocate($r, $g, $b);
		$i++;
	}
	$self->{image} = $im;
}

sub adjust_contrast {
	my $self = shift;
	my $delta = int( shift );
	my $midpoint = int( shift );
	$midpoint ||= 127;
	if(!$delta) { return }
	unless($midpoint >= 0 && $midpoint <= 255) { die "Provided midpoint must be in the range [0, 255]" }
	my $im = $self->{image};
	my $max_index = $im->colorsTotal;
	my $trans_index = $im->transparent;
	my $i = 0;
	while ($i < $max_index) {
		if($i==$trans_index) { $i++; next }
    	my ($r, $g, $b) = $im->rgb($i);
		foreach($r, $g, $b) {
			my $distance = abs($_ - $midpoint);
			my $adjusted_dist = int(((100 + $delta)/100)*$distance);
			if($_ > $midpoint) { $_ = _min($midpoint + $adjusted_dist, 255) }
			else { $_ = _max($midpoint - $adjusted_dist, 0) }
		}
		$im->colorDeallocate($i);
		$im->colorAllocate($r, $g, $b);
		$i++;
	}
	$self->{image} = $im;
}

=head2  invert

Inverts the image by mirroring the index color values around the midpoint.  You can provide an alternate midpoint as a parameter.

Usage: $imgh->invert(145.5);

=cut

sub invert {
	my $self = shift;
	my $midpoint = ( shift );
	$midpoint ||= 127.5;
	unless($midpoint >= 0.5 && $midpoint <= 254.5) { die "Provided midpoint must be in the range [0.5, 254.5]; Default is 127.5 (straight-up inversion)" }
	my $im = $self->{image};
	my $max_index = $im->colorsTotal;
	my $trans_index = $im->transparent;
	my $i = 0;
	while ($i < $max_index) {
		if($i==$trans_index) { $i++; next }
    	my ($r, $g, $b) = $im->rgb($i);
		foreach($r, $g, $b) { 
			$_ = int($midpoint - ($_ - $midpoint));
			if($_ < 0) { $_ = 0; }
			if($_ > 255) { $_ = 255; }
		}
		$im->colorDeallocate($i);
		$im->colorAllocate($r, $g, $b);
		$i++;
	}
	$self->{image} = $im;
}

sub adjust_hue {
	my $self = shift;
	my $delta_red = int( shift );
	my $delta_green = int( shift );
	my $delta_blue = int( shift );

	foreach($delta_red, $delta_green, $delta_blue) { 
		if($_ >100 || $_ < -100){
			die "Provided adjustment must be in the range [-100, 100]";
		}
	}
	my $im = $self->{image};
	my $max_index = $im->colorsTotal;
	my $trans_index = $im->transparent;
	my $i = 0;
	while ($i < $max_index) {
		if($i==$trans_index) { $i++; next }
    	my ($r, $g, $b) = $im->rgb($i);
		if($delta_red <= 0) {
			$r = int(((100 + $delta_red)/100)*$r);
		}
		elsif($delta_red > 0) {
			$r = int(255 - ((100 - $delta_red)/100)*(255-$r));
		}
		if($delta_green <= 0) {
			$g = int(((100 + $delta_green)/100)*$g);
		}
		elsif($delta_green > 0) {
			$g = int(255 - ((100 - $delta_green)/100)*(255-$g));
		}
		if($delta_blue <= 0) {
			$b = int(((100 + $delta_blue)/100)*$b);
		}
		elsif($delta_blue > 0) {
			$b = int(255 - ((100 - $delta_blue)/100)*(255-$b));
		}
		$im->colorDeallocate($i);
		$im->colorAllocate($r, $g, $b);
		$i++;
	}
	$self->{image} = $im;
}

sub adjust_hue_absolute {
	my $self = shift;
	my ($set_r, $set_g, $set_b) = @_;
	$self->color_balance(100, $set_r, $set_g, $set_b);
}

=head2 make_color_transparent()

Provide (red:0-255, green:0-255, blue:0-255, tolerance:0-255) to set a particular olor (or very close colors) to be the transparent index.

ONLY use this for very small images, as pixel-by-pixel setting of indices is required

Usage: $imgh->make_color_transparent(255, 255, 255, 10);

=cut

sub make_color_transparent {
	my $self = shift;
	my ($r, $g, $b, $tolerance) = @_;
	$tolerance ||= 0;	
	
	my $im = $self->{image};
	my $max_index = $im->colorsTotal;
	my $trans_index = $im->transparent;

	my $i = 0;
	my @indices_to_merge = ();
	while($i < $max_index) {
		my ($red, $green, $blue) = $im->rgb($i);
		if( ( (($red <= ($r + $tolerance)) && ($red >= ($r-$tolerance))) ) 
		 && ( (($green <= ($g + $tolerance)) && ($green >= ($g-$tolerance))) )
		 && ( (($blue <= ($b + $tolerance)) && ($blue >= ($b-$tolerance))) ) ) 
		 { push(@indices_to_merge, $i) }
		 $i++;
	}	
	my $x = 0;
	my $y = 0;
	#$indices_to_merge[0] will be our merged index, and we will set it to be the transparent pixel
	my ($max_x, $max_y) = $im->getBounds();
	while($x < $max_x){
		while($y < $max_y) {
			my $index = $im->getPixel($x, $y);
			$im->setPixel($x, $y, $indices_to_merge[0]) if grep { $_ == $index } @indices_to_merge;
			$y++;
		}
		$y = 0;
		$x++;
	}
	$im->transparent($indices_to_merge[0]);
	$self->{image} = $im;
}	

sub color_balance {
	my $self = shift;
	my $partial_factor = shift;
	my ($abs_r, $abs_g, $abs_b) = @_;

	foreach($abs_r, $abs_g, $abs_b) {
		if(defined $_){
			unless ($_ <= 255 && $_ >= 0) { die "Provided absolute color values must be in range (0-255] "; }
		}
	}
	$partial_factor ||= 100;
	unless ($partial_factor > 0 && $partial_factor <= 100) { die "Provided parameter 'partial_factor' must be in range (0, 100]" }

	
	#time-intensive-step:
	$self->_get_image_info;
	
	my ($avg_i, $avg_r, $avg_g, $avg_b) = ($self->{average_intensity}, $self->{average_red}, $self->{average_green}, $self->{average_blue});

	my ($balance_point_r, $balance_point_g, $balance_point_b);
#	die "Abs: $abs_r, $abs_g, $abs_b";
	(defined $abs_r) ? {$balance_point_r = $abs_r} : {$balance_point_r = $avg_i};
	(defined $abs_g) ? {$balance_point_g = $abs_g} : {$balance_point_g = $avg_i};
	(defined $abs_b) ? {$balance_point_b = $abs_b} : {$balance_point_b = $avg_i}; 
		
	my ($dr, $dg, $db) = map{ $partial_factor/100 * $_ } ($balance_point_r - $avg_r, $balance_point_g - $avg_g, $balance_point_b - $avg_b);
	my $im = $self->{image};
	my $max_index = $im->colorsTotal;
	my $trans_index = $im->transparent;

	my $i = 0;
	while($i < $max_index) {
		if($i == $trans_index) { $i++; next }
		my ($r, $g, $b) = $im->rgb($i);
		$r += $dr; 
		$g += $dg; 
		$b += $db;
		foreach ($r, $g, $b) {
			if($_ < 0) { $_ = 0 }
			if($_ > 255) { $_ = 255 }
			$_ = int($_);
		}
		$im->colorDeallocate($i);
		$im->colorAllocate($r, $g, $b);
		$i++;
	}	
}

sub auto_levels {
	my $self = shift;
	$self->_get_image_info();
	$self->auto_level_color("red", @_);	
	$self->auto_level_color("green", @_);	
	$self->auto_level_color("blue", @_);	
}

sub auto_level_color {
	my $self = shift;
	if(!exists $self->{index}) {$self->_get_image_info();}
	my $color = shift;
	my $im = $self->{image};
	my @color_accept = qw|red green blue|;
	unless ( grep { $_ eq $color} @color_accept ){
		die "No viable color provided";
	}
	#none of these are required:
	#you can define the points directly, define the threshold for boundaries (auto 5% of pixels from left or right side of intensity spectrum), or just let the color adjustment occur automatically.
	my ($mid_pt, $left_pt, $right_pt, $left_thresh, $right_thresh) = @_;

	$left_thresh ||= 5; # percent of pixels to cross from left side (0) to find left_pt
	$right_thresh ||= 5; #percent of pixels to cross from right side (255) to find right_pt

	my @ordered_indices = $self->_get_ordered_index($color);
	my $running_total_left = 0;
	my $running_total_mid = 0;
	my $running_total_right = 0;
	my $left_bound_count = ($left_thresh/100) * $self->{visible_pixel_count};
	my $right_bound_count = ($right_thresh/100)* $self->{visible_pixel_count};
	my $mid_bound_count = $self->{visible_pixel_count} / 2;
	
	if(!defined $left_pt || $left_pt < 0 || $left_pt > 255){
		foreach my $index (@ordered_indices) {
			$running_total_left += $self->{index}->{$index}->{count};
			if($running_total_left > $left_bound_count) {
				$left_pt = $self->{index}->{$index}->{$color}; #rgb value
				last;
			}
		}
	}
	if(!defined $mid_pt || $mid_pt < 1 || $mid_pt > 254){
		foreach my $index (@ordered_indices) {
			$running_total_mid += $self->{index}->{$index}->{count};
			if($running_total_mid > $mid_bound_count) {
				$mid_pt = $self->{index}->{$index}->{$color}; #rgb value
				last;
			}
		}
	}
	my @reverse_indices = reverse @ordered_indices;
	if(!defined $right_pt || $right_pt < 0 || $right_pt > 255){
		foreach my $index (@reverse_indices) {
			$running_total_right += $self->{index}->{$index}->{count};
			if($running_total_right > $right_bound_count) {
				$right_pt = $self->{index}->{$index}->{$color}; #rgb value
				last;
			}
		}
	}
	#ok, we have mid_pt, left_pt, and right_pt now.  Time to do some expansion math!  
	#hardcoded bounds
	if($right_pt < 220) { $right_pt = 220; }
	if($left_pt > 30) { $left_pt = 30; }
	if($mid_pt > 140) { $mid_pt = 140;}
	if($mid_pt < 110) { $mid_pt = 110;}

	my $i = 0;
	while($i < $im->colorsTotal) {
		if($i == $im->transparent) { $i++; next }
		my ($r, $b, $g) = $im->rgb($i);
		my $value;
		if($color eq "red") { $value = $r }
		elsif($color eq "green") { $value = $g }
		elsif($color eq "blue") { $value = $b }

		if($value <= $left_pt) { $value = 0; }
		elsif($value >= $right_pt) { $value = 255; }
		elsif($value <= $mid_pt) {
			my $dm = $mid_pt - $value;
			my $alpha = $dm / ($mid_pt - $left_pt); # 1 for left_pt, 0 for mid_pt, 0.5 for half way inbetween
			my $dv = ($left_pt) * $alpha; # distance value will move LEFT
			$value -= $dv;
		}
		elsif($value > $mid_pt) {
			my $dm = $value - $mid_pt;
			my $alpha = $dm / ($right_pt - $mid_pt);
			my $dv = (255 - $right_pt) * $alpha;
			$value += $dv;
		}
		$value = int($value);
		
		if($color eq "red") { $r = $value }
		elsif($color eq "green") { $g = $value }
		elsif($color eq "blue") { $b = $value }
		$im->colorDeallocate($i);
		$im->colorAllocate($r, $g, $b);
		$i++;
	}
}

sub _get_ordered_index {
	my $self = shift;
	my $color = shift;
	my $im = $self->{image};
	my @color_accept = qw|red green blue|;
	unless (grep { $_ eq $color} @color_accept ){
		die "No viable color (red, green, or blue) provided";
	}
	my %indices;	
	my $i = 0;
	while ( $i < $im->colorsTotal() ) {
		my ($r, $g, $b) = $im->rgb($i);
		if($i == $im->transparent) { $i++; next } 
		if($color eq "red"){
			$indices{$i} = $r;
		}
		elsif($color eq "green"){
			$indices{$i} = $g;
		}
		elsif($color eq "blue"){
			$indices{$i} = $b;
		}
		$i++;
	}
	return sort { $indices{$a} <=> $indices{$b} } keys %indices;
}

=head2 _get_image_info

Goes pixel-by-pixel to find index proportions, to be used for auto_levels, auto_contrast, etc.  Also finds average color intensities, and whole-averaged intensity for the image

This should be able to handle large images, since it reads individual pixels and doesn't write to them

=cut

sub _get_image_info {
	my $self=shift;
	my $im = $self->{image};
	my $max_ind = $im->colorsTotal;
	my $trans_ind = $im->transparent;
	my ($max_x, $max_y) = $im->getBounds;
	
	my ($x, $y) = (0, 0);

	while ($x < $max_x) {
		while ($y < $max_y) {
			my $index = $im->getPixel($x, $y);
			if(! exists $self->{index}->{$index} ) {
				my ($r, $g, $b) = $im->rgb($index);
				$self->{index}->{$index}->{count} = 0;
				$self->{index}->{$index}->{red} = $r;
				$self->{index}->{$index}->{green} = $g;
				$self->{index}->{$index}->{blue} = $b;
			}	
			$self->{index}->{$index}->{count}++;
			$y++;
		}
		$y = 0;
		$x++;
	}

	my $num_pixels = $max_x * $max_y;	
	my ($avg_r, $avg_g, $avg_b, $avg_i) = (0, 0, 0, 0);
	while(my($index, $indref) = each %{$self->{index}}) {
		my $proportion = ($indref->{count} / $num_pixels);
		$indref->{proportion} = $proportion;
		$avg_r += $indref->{red} * $proportion;
		$avg_g += $indref->{green} * $proportion;
		$avg_b += $indref->{blue} * $proportion;
		$avg_i += ($indref->{red} + $indref->{green} + $indref->{blue})/3 * $proportion;
	}
	$self->{transparent_pixel_count} = $self->{index}->{$trans_ind}->{count};	
	$self->{pixel_count} = $num_pixels;
	$self->{visible_pixel_count} = $self->{pixel_count} - $self->{transparent_pixel_count};
	$self->{transparent_index} = $trans_ind;

	$self->{average_intensity} = $avg_i;
	$self->{average_red} = $avg_r;
	$self->{average_green} = $avg_g;
	$self->{average_blue} = $avg_b;
}

sub _max {
	if(!@_) { return }
	@_ = map { int($_) } @_;
	my $max = $_[0];
	foreach(@_) { if ($_ > $max) { $max = $_ } }
	return $max;
}

sub _min {
	if(!@_) { return }
	@_ = map { int($_) } @_;
	my $min = $_[0];
	foreach(@_) { if ($_ < $min) { $min = $_ } }
	return $min;
}

1;

