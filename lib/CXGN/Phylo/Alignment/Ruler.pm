package CXGN::Phylo::Alignment::Ruler;
use base qw( CXGN::Phylo::Alignment::ImageObject);
use strict;
use GD;
use CXGN::Tools::Param qw/hash2param/;

=head1 Package Alignment::Ruler

This class is inherited from ImageObject.  Its special attributes include label_side, unit, label_spacing and tick_spacing.  The ruler is horizontal only.

=cut

=head2 Constructor new()

  Synopsis:     my $ruler = Alignment::Ruler->new(
						  left_margin=>$x, 
						  top_margin=>$y, 
						  length=>$z,
						  height=>$h,
						  start_value=>$a, 
						  end_value=>$b
						 );
  Returns:      a Alignment::Ruler object

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $self = $class->SUPER::new(@_);

    #set defaults
    $self->{label_side} = "up";
	$self->{show_unit} = 1;
    return $self;
}

=head2 Setters and getters

set_labels_up(), set_labels_down(), set_unit("aa"), get_unit(), set_label_spacing, get_label_spacing, set_spacing (equates label and tick), get_spacing, set_tick_spacing, get_tick_spacing

=cut

sub set_labels_up {
    my $self = shift;
    $self->{label_side} = "up";
}

sub set_labels_down {
    my $self = shift;
    $self->{label_side} = "down";
}

sub set_unit {
    my $self = shift;
    $self->{unit} = shift;
}

sub get_unit { 
    my $self = shift;
    return $self->{unit};
}

sub hide_unit {
	my $self = shift;
	$self->{show_unit} = 0;
}

sub show_unit { 
	my $self = shift;
	$self->{show_unit} = 1;
}

sub set_label_spacing {
  my $self = shift;
  $self->{label_spacing} = shift;
}

sub get_label_spacing {
  my $self = shift;
  return $self->{label_spacing};
}

sub set_tick_spacing {
  my $self = shift;
  $self->{tick_spacing} = shift;
}

sub get_tick_spacing {
  my $self = shift;
  return $self->{tick_spacing};
}

sub set_spacing {
	my $self = shift;
	$self->{tick_spacing} = $self->{label_spacing} = shift;
}

sub get_spacing {
	my $self = shift;
	if($self->{tick_spacing} == $self->{label_spacing}){
		return $self->{tick_spacing};
	}
	else {
		warn "\nTick and label spacing not equal, returned -1";
		return -1;
	}
}	

=head2 Image display sub render()

Synopsis: $ruler->render($img) where $img is a image object

Description: draws ruler line, ticks (goes to near the bottom of the image), label and unit, 

=cut

sub default_spacing {
	my $self = shift;
	
	my $range = $self->{end_value} - $self->{start_value};
	my %tick_hash = ( 10=>1, 16=>2, 25=>5, 50=>10, 100=>20, 150=>25, 300=>50, 600=>100 );
	my @limits = keys %tick_hash;
	@limits = sort { $a <=> $b } @limits;
	foreach(@limits){
		if($range <= $_){
			$self->{tick_spacing} = $tick_hash{$_};
			last;
		}
	}
	if(!$self->{tick_spacing} || $range/$self->{tick_spacing} > 10){  #too many ticks!  tick-spray, bitch...
		$self->{tick_spacing} = ((int (($range + 1) / 1000))+ 1) * 100;
	}
	$self->{label_spacing} = $self->{tick_spacing};
	return $self->{tick_spacing};
}

sub render {
	my $self = shift;
	my $image = shift;
	my $alignment = shift;

	$self->layout_color(120, 120, 120);
	$self->layout_label_color(120, 120, 120);

	my $color = $image->colorResolve($self->{color}[0], $self->{color}[1], $self->{color}[2]);

	#####################Draw ruler line
	$image->line($self->{left_margin}, $self->{top_margin}, $self->{left_margin} + $self->{width} - $self->{label_spacer}, $self->{top_margin}, $color);
	
	$self->default_spacing();

	#####################Determine the scaling factor.  Increment label spacing  by 10 until the longest label is shorter than label spacing 
	$self->_calculate_scaling_factor();

# 	if ($self->{scaling_factor})  { 
# 		#otherwise this is an infinite loop....
# 		while (($self->{label_spacing} * $self->{scaling_factor}) < ($self->{font}->width() * length ($self->{end_value})+2)) { $self->{label_spacing} +=10; }
# 	}
   	my $range = $self->{end_value} - $self->{start_value};

	my $tick_number = int(($range+1)/$self->{tick_spacing});    
	for (my $i = 0; $i <= $tick_number; $i++) {
		my $x = $self->{left_margin} + (($i*$self->{tick_spacing})*$self->{scaling_factor});
		$image->dashedLine($x, $self->{top_margin}-2, $x, $self->{height}+2, $color); #draw the tick
		if ( $i*$self->{tick_spacing} % $self->{label_spacing} == 0) {#Draw tick label
			my $tick_label = $i*$self->{tick_spacing} + $self->{start_value} - 1;
			my $horizontal_adjust = $self->{font}->width * length ($tick_label)/2;
			my $tick_label_x = $x - $horizontal_adjust;
			if($self->{tick_spacing}==1){
				$tick_label_x -= $self->{scaling_factor}/2;
				if($i==0) { #don't display last label in this case
					$tick_label_x = -1000;
				}
			}
			my $tick_label_y;
			if ($self->{label_side} eq 'down'){
				$tick_label_y = $self->{top_margin} + 1;
			}
			else {
				$tick_label_y = $self->{top_margin} - 1 - $self->{font}->height;
			}
			$image->string($self->{font}, $tick_label_x, $tick_label_y, $tick_label, $color);
		}
	}
	
	#print STDERR "Top Margin: " . $self->{top_margin} . "\n";
	#Write unit
	$self->hide_unit() unless $self->get_unit();
	if($self->{show_unit}){
		my $unit_label = "[".$self->{unit}."]";
		my $unit_label_x = $self->{left_margin} + ($self->{width}- $self->{font}->width() * length($unit_label))/2;
		my $unit_label_y;
		if ($self->{label_side} eq 'down'){
			$unit_label_y = $self->{top_margin} + 1 + $self->{font}->height;
		}
		else {
			$unit_label_y = $self->{top_margin} - 1 - $self->{font}->height*2;
		}
		$image->string($self->{font}, $unit_label_x, $unit_label_y, $unit_label, $color);    
	}

	#Draw Navigation Arrows
	$self->_draw_nav_arrows($image, $alignment);
	$self->_draw_nav_zoomout($image, $alignment);
}

sub _draw_nav_arrows {
	my $self = shift;
	my $image = shift;
	my $alignment = shift;
	my ($r, $g, $b) = ($self->{color}[0], $self->{color}[1], $self->{color}[2]);
#	$b = (255 - 0.4*(255-$b));	
	$g = (255 - 0.8*(255-$g));	
	$b = 0.4*$b;
	$r = 0.4*$r;

	my $color = $image->colorResolve($r, $g, $b);

	my ($lb, $rb) = ($self->{start_value}, $self->{end_value});
	my $max_rb = $alignment->get_seq_length();
	unless($rb==$max_rb){
		my $poly = GD::Polygon->new();
		my $refx = $self->{width} + $self->{left_margin} - $self->{label_spacer} + 4;
		$poly->addPt($refx, $self->{top_margin}+4);
		$poly->addPt($refx+7, $self->{top_margin}+11);
		$poly->addPt($refx, $self->{top_margin}+18);
		$image->filledPolygon($poly, $color);
	}
	unless($lb==1){
		my $poly = GD::Polygon->new();
		my $refx = $self->{left_margin}-4;
		$poly->addPt($refx, $self->{top_margin}+4);
		$poly->addPt($refx-7, $self->{top_margin}+11);
		$poly->addPt($refx, $self->{top_margin}+18);
		$image->filledPolygon($poly, $color);
	}
}

sub _get_nav_arrow_imap {
	my $self = shift;
	my $alignment = shift;
	my $param_hash = shift;
	my ($spacing, $lb, $rb) = ($self->{tick_spacing}, $self->{start_value}, $self->{end_value});
	my $range = $rb - $lb;
	my $max_rb = $alignment->get_seq_length();

	my $mapstring = "";
	unless($rb==$max_rb){
		my $refx = $self->{width} + $self->{left_margin} - $self->{label_spacer} + 4;
		my $jump = 3*($range+1)/4;
		my $right_start = int($lb + 3*($range+1)/4);
		my $right_end = $right_start + $range;
		if ($right_end > $max_rb){
			my $pull = $right_end - $max_rb;
			$right_end -= $pull;
			$right_start -= $pull;
		}
		
		my $rightcoords = join "," , ($refx, $self->{top_margin}+4, $refx+7, $self->{top_margin}+18);
		my $righturl = "show_align.pl?" . hash2param($param_hash, {start_value=>$right_start, end_value=>$right_end});
		
		$mapstring .= "<area shape='rect' coords='$rightcoords' href='$righturl' >\n";
	}	
	unless($lb==1){
		my $refx = $self->{left_margin}-4;
		my $left_start = int($lb - 3*($range+1)/4);
		my $left_end = $left_start + $range;
		if($left_start < 1){
			my $push = 1 - $left_start;
			$left_start += $push;
			$left_end += $push;
		}
		my $leftcoords = join "," , ($refx-7, $self->{top_margin}+4, $refx, $self->{top_margin}+18);
		my $lefturl = "show_align.pl?" . hash2param($param_hash, {start_value=>$left_start, end_value=>$left_end});
	
		$mapstring .= "<area shape='rect' coords='$leftcoords' href='$lefturl' >\n";
	}
	return $mapstring;
}

sub _draw_nav_zoomout {
	my ($self, $image, $alignment) = @_;
	my ($spacing, $lb, $rb) = ($self->{tick_spacing}, $self->{start_value}, $self->{end_value});
	my $range = $rb - $lb;
	my $max_rb = $alignment->get_seq_length();
	
	my ($r, $g, $b) = ($self->{color}[0], $self->{color}[1], $self->{color}[2]);
#	$b = (255 - 0.4*(255-$b));	
#	$g = 0.4*$g;	
	$g = (255 - 0.8*(255-$g));	
	$b = 0.4*$b;
	$r = 0.4*$r;

	my $color = $image->colorResolve($r, $g, $b);
	my $Z = 9; #use a multiple of 3, please!

	unless($lb==1 && $rb==$max_rb){
		my $refx = $self->{left_margin}+20;
		my $refy = $self->{top_margin} - $self->{font}->height*2;
	
		## Draw X
		$image->line($refx, $refy, 		$refx + $Z, $refy + $Z,	$color);
		$image->line($refx + $Z, $refy,	$refx, $refy + $Z, 		$color);
	
		## Draw Arrowheads on X tips
		#upper-left
		$image->line($refx, $refy, 		$refx, $refy + $Z/3,	$color);
		$image->line($refx, $refy, 		$refx + $Z/3, $refy,	$color);
		#lower-left
		$image->line($refx, $refy + $Z,	$refx, $refy + 2*$Z/3,		$color);
		$image->line($refx, $refy + $Z,	$refx + $Z/3, $refy + $Z,	$color);
		#lower-right
 		$image->line($refx + $Z, $refy + $Z,	$refx + $Z, $refy + 2*$Z/3,		$color);
 		$image->line($refx + $Z, $refy + $Z,	$refx + 2*$Z/3, $refy + $Z,		$color);
		#upper-right
		$image->line($refx + $Z, $refy,	$refx + 2*$Z/3, $refy,		$color);
		$image->line($refx + $Z, $refy,	$refx + $Z, $refy + $Z/3,	$color);

		my $disp_label = "Zoom Out";
		$image->string($self->{font}, $refx + $Z + 5, $refy - 2, $disp_label, $color);

		$self->{nav_zoomout_coords} = join "," ,  ($refx, $refy, $refx + $Z + 5 + $self->{font}->width*length($disp_label), $refy+$Z);
	}
}

sub _get_nav_zoomout_imap {
	my $self = shift;
	my $alignment = shift;
	my $param_hash = shift;
	my ($spacing, $lb, $rb) = ($self->{tick_spacing}, $self->{start_value}, $self->{end_value});
	my $range = $rb - $lb;
	my $max_rb = $alignment->get_seq_length();
	my $max_range = $max_rb - 1;
	my $fasta_temp_file = $alignment->get_fasta_temp_file();
	my $type = $alignment->{type};
	my $title = $alignment->{name};

	unless($lb==1 && $rb==$max_rb){
		my $coords = $self->{nav_zoomout_coords};
	
		#Determines standard level of de-magnification:
		my $new_range = $range * 3;
		
		my ($start, $end);
		if($new_range > $max_range){
			$start = 1;
			$end = $max_rb;
		}
		else {
			my $new_start = $lb - ($new_range-$range)/2;	
			my $new_end = $rb + ($new_range-$range)/2;
			if($new_start < 1){
				my $push = $lb - $new_start;
				$new_start = 1;
				$new_end += $push;
				$new_end = $max_rb if($new_end > $max_rb);
			}
			if($new_end > $max_rb){
				my $pull = $new_end - $max_rb;
				$new_end = $max_rb;
				$new_start -= $pull;
				$new_start = 1 if ($new_start < 1);
			}
			$start = int($new_start);
			$end = int($new_end);
		}
		my $url = "show_align.pl?" . hash2param($param_hash, {start_value=>$start, end_value=>$end});
	
		return  "<area shape='rect' coords='$coords' href='$url' >\n";
	}
	return "";
}

=head3 get_imagemap_string

 Overrides ImageObject subroutine to provide an image map string for 
 navigating the alignment.
 
 IMPORTANT: This must be used AFTER the ruler is rendered.  Alternatively, you
 			can define the start_value and end_value and then run this sub

=cut

sub get_imagemap_string {
	my $self = shift;
	my $alignment = shift;
	my $param_hash = shift;
	return unless ($alignment);

	my ($spacing, $lb, $rb) = ($self->{tick_spacing}, $self->{start_value}, $self->{end_value});
	my $range = $rb - $lb;
	return unless ($lb && $rb);
	if(!$spacing) { $spacing = $self->default_spacing() }


	my $mapstring = $self->_get_nav_arrow_imap($alignment, $param_hash);
	$mapstring .= $self->_get_nav_zoomout_imap($alignment, $param_hash);	
	
	return $mapstring if ($spacing < 5);  #no more zoom left in her, just return arrow nav maps

	my $maphashref = $self->_build_navblock_hash(); 
	my %maphash = %$maphashref;
	$self->_calculate_scaling_factor() unless ($self->{scaling_factor});
	while(my ($key, $value) = each %maphash){
		my ($lb, $rb) = $key =~ /(.*),(.*)/;
		my ($next_start, $next_end) = $value =~ /(.*),(.*)/;	
		my $x_left = ($lb-$self->{start_value})*$self->{scaling_factor}+$self->{left_margin};
		my $x_right = ($rb-$self->{start_value}+1)*$self->{scaling_factor} + $self->{left_margin};
		my $y_top = $self->{top_margin};
		my $y_bottom = $self->{height};
		my @coords = map { int($_) } ($x_left, $y_top, $x_right, $y_bottom);	
		my $coords = join (",", @coords);
		$next_start = int($next_start);
		$next_end = int($next_end);
		my $title = "Zoom into range $next_start-$next_end";
		my $url = "show_align.pl?" . hash2param($param_hash, {start_value => $next_start, end_value => $next_end});
		$mapstring .= <<HTML;
		<area 	shape="rect"
				coords="$coords"
				href="$url" 
				title="$title">
HTML
	}
	
		
	return $mapstring;
}

sub _build_navblock_hash {
	my $self = shift;	
	my ($spacing, $lb, $rb) = ($self->{tick_spacing}, $self->{start_value}, $self->{end_value});
	$spacing = $self->default_spacing() unless ($spacing);	
	my $range = $rb - $lb;
	my $blocksize = $spacing/4;
	my $debugstring = "\nBlocksize: $blocksize | Range: $range | Spacing: $spacing\n";	
	
	#The Carpita-NavBlock Algorithm
	# 1. Find the Stop-Block #, the last full block of the ruler (block = tick-spacing/4)
	# 2. Take the previous odd # N.
	# 3. The first value of a hash is '(N-2),(N)' => '(N-3),RB [special constant]'
	# 4. The next value is n=N-2: '(n-2),(n)' => '(n-3),(n+1)', continue to build values f(n-2)
	# 5. When n==3, the last hash value is 'LB,3' => 'LB,4'
	# 6. For each hash pair "a,b" => "x,y" 
	#     --> transform to -->  
	#      "a*blocksize + left-bound	, 	
	#				left-bound + blocksize*b - 1"
	#						=>
	#      "x*blocksize + left-bound [unless 'LB', then fill in left-bound]		,
	#				y*blocksize [unless 'RB', then fill in right-bound]"
	#
	# * Each left-side of the hash defines the horizontal coordinates for the image map
	#	when multiplied by the scaling factor
	# * The right-side of the hash defines the physical region of the alignment
	#	to which we navigate (link) in the imagemap
	# * Pretty cool. 

	#Step 1: Find the stop block
	my $stopblock = int($range/$blocksize);  #easy enough

	#Step 2: Find N
	my $N;
	(!($stopblock % 2)) ? ($N = $stopblock - 1) : ($N = $stopblock - 2);
	
	#Step 3: Initialize hash w/ first value
	my $initkey = ($N - 2) . ",RB";
	my $initvalue = ($N - 3) . ",RB";
	my %maphash = ( $initkey => $initvalue );
	
	#Step 4: Iterate
	my $n = $N - 2;
	while($n > 3) {
		my $key = ($n - 2) . "," . ($n);
		my $value = ($n - 3) . "," . ($n + 1);
		$maphash{$key} = $value;
		$n = ($n - 2); 
	}
		
	#Step 5: Enter last hash value
	my $lastkey = "LB,3";
	my $lastvalue = "LB,4";
	$maphash{$lastkey} = $lastvalue;

	#Step 6: Transform the hash
	my %transformed = ();
	$debugstring .= "Hash and transform:\n";
	while(my ($key, $value) = each %maphash){
	
		$debugstring .= "$key => $value  \t\t--->\t\t";

		my ($a, $b) = $key =~ /(.*),(.*)/;
		my ($x, $y) = $value =~ /(.*),(.*)/;
		my ($transkey_left, $transkey_right);

		my ($transval_left, $transval_right);
		($a eq 'LB') ? ($transkey_left = $lb) : ($transkey_left = $a*$blocksize + $lb);
		($b eq 'RB') ? ($transkey_right = $rb) : ($transkey_right = $b*$blocksize + $lb);
		my $transkey = $transkey_left . "," . $transkey_right;	

		($x eq 'LB') ? ($transval_left = $lb) : ($transval_left = $x*$blocksize + $lb);
		($y eq 'RB') ? ($transval_right = $rb) : ($transval_right = $y*$blocksize + $lb - 1);
		my $transvalue = $transval_left . "," . $transval_right;
	
		$debugstring .= " $transkey => $transvalue\n";
		$transformed{$transkey} = $transvalue;
	}

#	die $debugstring;
	
	return \%transformed;
}

1;


