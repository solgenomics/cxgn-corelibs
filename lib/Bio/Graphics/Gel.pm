package Bio::Graphics::Gel;
use strict;
use warnings;
use English;
use Carp;

use GD;
use POSIX qw/log10/;

use Bio::Graphics::Ruler qw/ruler/;

=head1 NAME

Bio::Graphics::GelImage - a L<GD> image that draws something that
looks like a gel image, without getting ethidium bromide all over your
hands.

=head1 SYNOPSIS

  my $gel = Bio::Graphics::Gel->new( 'In vitro'  => [ 1100, 1900, 2000 ],
                                     'In silico' => [ 1230, 12440 ],
                                     -title     => 'Restriction Fragments',
                                     -lane_width => 20, #in pixels
                                   );

  #write PNG data to STDOUT
  binmode STDOUT; #< required for dos-ish platforms
  print $gel->img->png;

=head1 DESCRIPTION

Class for making gel images in a variety of formats.

=head1 BASE CLASS(ES)

L<Bio::Root::Root>
L<GD::Image>

=cut

use base qw/Bio::Root::Root/;

=head1 SUBCLASSES

none yet

=head1 AUTHOR(S)

Robert Buels - rmb32 at cornell dot edu

=head1 METHODS


=head2 new

  Usage: my $gel = Bio::Graphics::Gel->new( mylane => [100,200,300] );
  Args : list of 'lane title' => [ frag size, frag size, frag size ],
         plus optional configuration parameters:
         -title        add this title to the gel image
         -lane_width   set the width of each lane on the gel,
                       defaults to 40 pixels
         -lane_length  set the length of each lane on the gel,
                       defaults to 200 pixels
         -lane_spacing pixels between lanes, default 3
         -padding      css-like string like '10 20 10 20' or an
                       arrayref like [10,20,10,20], with the order
                       being top,right,bottom,left
         -bandcolor    color in RGB like '255 0 0' or [255,0,0] for red,
                       sets the color of the bands on the gel,
         -gelcolor     same, but for the gel color,
         -bgcolor      same, but for the background color,
         -textcolor      same, but for the text color,
         -font_size    in points.  default 10
         -font_file    full path to TrueType font file to use,
                       default /usr/share/fonts/truetype/ttf-bitstream-vera/Vera.ttf
         -band_thickness  thickness in pixels of the bands.  default 1.
         -min_frag     set the 'end' of 'diffusion' on the gel to
                       correspond to fragments of this length.
                       defaults to the length of the smallest fragment
                       in any lane on the gel
         -max_frag     similar to -min_frag, except for the start of
                       diffusion
         -dilation     no default. if not set, this is calculated such
                       that the smallest-sized fragment is at the end of
                       the gel,
         -diff_limit   log10 of the largest length of fragment that can
                       diffuse in the gel, defaults to largest fragment
                       size (or -max_frag) times 1.3

  Ret  : a new Gel image object
  Desc : make a new GelImage object with the given data
  Side Effects: none

=cut

sub new {
  my ($class,@args) = @_;

  my $self = $class->SUPER::new(@args);

  @args%2 and $self->throw('argument list must be even-length');

  sub arraystr {
    my ($val) = @_;
    my $origvalstr = ref($val) eq 'ARRAY' ? join(',',@$val) : $val;
    $val = [ split /\s+/,$val ] unless ref $val eq 'ARRAY';
    return ($val,$origvalstr);
  }

  #parse and validate arguments
  while(my ($key,$val) = splice @args,0,2) {
    #for config options
    if($key =~ s/^-//) {
      if($key eq 'title') {
	$self->{title} = $val;
      } elsif($key eq 'lane_width') {
	$val > 0 or $self->throw("invalid lane width '$val'");
	$self->{lane_width} = $val;
      } elsif($key eq 'lane_length') {
	$val > 0 or $self->throw("invalid lane length '$val'");
	$self->{lane_length} = $val;
      } elsif($key eq 'lane_spacing') {
	$val >0 or $self->throw("invalid lane_spacing '$val'");
	$self->{lane_spacing} = $val;
      } elsif($key eq 'padding') {
	my ($val,$origval) = arraystr($val);
# 	use Data::Dumper;
# 	print 'got padding ',Dumper($val);
	(@$val == 4) #and (not grep {! $_ >= 0 } @$val)
	  or $self->throw("invalid padding '$origval'");
	$self->{padding} = $val;
      } elsif($key eq 'bandcolor') {
	my ($val,$origval) = arraystr($val);
	@$val == 3 #and not grep {! ($_ >= 0 && $_ <= 255)} @$val
	  or $self->throw("invalid bandcolor '$origval'");
	$self->{bandcolor} = $val;
      } elsif($key eq 'gelcolor') {
	my ($val,$origval) = arraystr($val);
	@$val == 3 #and not grep {! ($_ >= 0 && $_ <= 255)} @$val
	  or $self->throw("invalid gelcolor '$origval'");
	$self->{gelcolor} = $val;
      } elsif($key eq 'bgcolor') {
	my ($val,$origval) = arraystr($val);
	@$val == 3 and not grep {! ($_ >= 0 && $_ <= 255)} @$val
	  or $self->throw("invalid bgcolor '$origval'");
	$self->{bgcolor} = $val;
      } elsif($key eq 'textcolor') {
	my ($val,$origval) = arraystr($val);
	@$val == 3 and not grep {! ($_ >= 0 && $_ <= 255)} @$val
	  or $self->throw("invalid textcolor '$origval'");
	$self->{textcolor} = $val;
      } elsif($key eq 'font_size') {
	$val > 0 or $self->throw("invalid font_size '$val'");
	$self->{font_size} = $val;
      } elsif($key eq 'font_file') {
	-f $val or $self->throw("font file '$val' does not exist, please specify a different one");
	$self->{font_file} = $val;
      } elsif($key eq 'band_thickness') {
	$val > 0 or $self->throw("invalid band_thickness '$val'");
	$self->{band_thickness} = $val;
      } elsif($key eq 'min_frag') {
	$val > 0 or $self->throw("invalid min_frag '$val'");
	$self->{min_frag} = $val;
      } elsif($key eq 'dilation') {
	$val > 0 or $self->throw("invalid dilation '$val'");
	$self->{dilation} = $val;
      } elsif($key eq 'diff_limit') {
	$val > 0 or $self->throw("invalid diff_limit '$val'");
	$self->{diff_limit} = $val;


      } else {
	$self->throw("unknown configuration parameter '-$key'");
      }
    }
    #for lanes
    else {
      #must be a lane with a title
      $self->{lanes} ||= [];
      ref($val) eq 'ARRAY' or $self->throw("fragments lengths must be given as arrayrefs");
      push @{$self->{lanes}}, Bio::Graphics::Gel::Lane->new($key,$val);
    }
  }

  $self->{lanes} && @{$self->{lanes}}
    or $self->throw('must specify at least one lane');

  #set default values
  $self->{lane_width}     ||= 40;
  $self->{lane_length}    ||= 200;
  $self->{lane_spacing}   ||= 5;
  $self->{padding}        ||= [10,20,10,20];
  $self->{bandcolor}      ||= [255,255,255];
  $self->{gelcolor}       ||= [127,127,127];
  $self->{bgcolor}        ||= [255,255,255];
  $self->{textcolor}      ||= [0,0,0];
  $self->{font_size}      ||= 10;
  $self->{font_file}      ||= '/usr/share/fonts/truetype/ttf-bitstream-vera/Vera.ttf';
  $self->{band_thickness} ||= 1;

  $self->_render; #< creates $self->{gd_img}

  return $self;
}

=head2 lanes

  Usage: my @lanes = $gel->lanes;
  Args : none
  Ret  : list of Bio::Graphics::Gel::Lane objects representing the
         lanes in the gel
  Desc : get/set the list of lanes and their titles in the gel

=cut

sub lanes {
  my ($self) = @_;
  return @{$self->{lanes}};
}


=head2 img

  Usage: print $gel->img->png; #prints this gel image as PNG to stdout
  Desc : get the GD image with the gel drawn on it
  Args : none
  Ret  : the L<GD::Image>, with this gel image drawn on it.
         see L<GD::Image> or L<GD> for how to use it

=cut

sub img {
  my ($self) = @_;
  return $self->{gd_img};
}


sub _min(@) { #unfortunately, List::Util::min() doesn't work on OS X 10.3, so I can't use it
  my $min;
  $min = (defined($min) and $min <= $_) ? $min : $_ foreach @_;
  return $min;
}
sub _max(@) {
  my $max;
  $max = (defined($max) and $max >= $_) ? $max : $_ foreach @_;
  return $max
}

#no arguments, renders the 
sub _render {
  my ($self) = @_;

  #set padding numbers for rendering vertically
  my ($tpad,$rpad,$bpad,$lpad) = @{$self->{padding}};

  #figure out the height and width of our text labels
  my $labels_angle = 0;
  my $lane_labels_height;
  my $fragsize_labels_width;
  {
    my $throwaway = GD::Image->new(10,10,1);
    my $b = $throwaway->colorAllocate(0,0,0);
    $throwaway->useFontConfig(1);
    $lane_labels_height = _max map {
      my @b = GD::Image->stringFT($b,$self->{font_file},$self->{font_size},$labels_angle,100,100,$_->name);
      $b[1]-$b[5]
    } $self->lanes;
    $fragsize_labels_width = _max map {
      my @b = GD::Image->stringFT($b,$self->{font_file},$self->{font_size},$labels_angle,100,100,_commify_number($_));
      $b[4]-$b[0]
    } $self->_ladder_lane->fragments;
  }

#  warn "got height $lane_labels_height\n";

  my ($width,$height) = (
			 (@{$self->{lanes}}+1)*($self->{lane_width}+$self->{lane_spacing})
			 + $lpad + $rpad + $self->{lane_spacing} + $fragsize_labels_width,

			 $self->{lane_length} + 4 + $tpad + $lane_labels_height + $bpad ,
			);

  #initalize our canvas, true-color, with a white background
  my $im = $self->{gd_img} = GD::Image->new($width,$height,1);
  my $textcolor = $im->colorAllocate(@{$self->{textcolor}});
  my $bg = $im->colorAllocate(@{$self->{bgcolor}});
  my $gelcolor = $im->colorAllocate(@{$self->{gelcolor}});
  my $fg = $im->colorAllocate(@{$self->{bandcolor}});
  $im->fill(0,0,$bg);

  #draw the gel
  my ($gelx,$gely) = ($lpad+$fragsize_labels_width,$tpad+$lane_labels_height);
  my ($gelwidth,$gelheight) = ($width-$rpad-$gelx,$height-$bpad-$gely);
  $im->filledRectangle($gelx,$gely,$gelx+$gelwidth,$gely+$gelheight,$gelcolor);

  ### draw the lanes with bands and labels
  $im->useFontConfig(1);
  my $smallest_frag = $self->{min_frag} || _min map { $_->fragments } @{$self->{lanes}};
  my $biggest_frag  = $self->{max_frag} || _max map { $_->fragments } @{$self->{lanes}};
  $self->{diff_limit} ||= log10($biggest_frag*1.3);
  $self->{dilation}   ||= $self->{lane_length} / ($self->{diff_limit}-log10($smallest_frag));
#  warn "using gel params $self->{dilation},$self->{diff_limit}\n";
  $im->setThickness($self->{band_thickness});
  my @lanes = ($self->_ladder_lane,@{$self->{lanes}});
  my @fraglabels;
  for(my $lanenum = 0; $lanenum < @lanes; $lanenum++) {
    my $lane = $lanes[$lanenum];
    my $x_offset = $gelx+$self->{lane_spacing}+($self->{lane_width}+$self->{lane_spacing})*$lanenum;

    _stringFT_origin('lc',$im,$textcolor,$self->{font_file},$self->{font_size},$labels_angle,$x_offset+$self->{lane_width}/2,$gely - 5,$lane->name);

    foreach my $frag ($lane->fragments) {
      my $diffusion_px = _min($self->{lane_length},sprintf('%d',$self->{dilation}*($self->{diff_limit}-log10($frag))));
      $diffusion_px = 0 unless $diffusion_px > 0;
      my $y_offset = $gely + $diffusion_px + 1;
#      warn "drawing with $y_offset\n";
      $im->line($x_offset,$y_offset,$x_offset+$self->{lane_width},$y_offset,$fg);
      if($lanenum == 0) {
	push @fraglabels, [$y_offset,$frag];
#	_stringFT_origin('cr',$im,$textcolor,$self->{font_file},10,0,$gelx-2,$y_offset,_commify_number($frag));
      }
    }
  }

  #draw fragment labels from top to bottom, skipping ones that would overlap with the ones above
  my @bounds;
  foreach my $label (sort {$a->[0] <=> $b->[0]} @fraglabels) {
    my @stringargs = ($textcolor,$self->{font_file},$self->{font_size},0,$gelx-2,$label->[0],_commify_number($label->[1]));
    my @newbounds = GD::Image->stringFT(@stringargs);
    unless(@bounds && ($newbounds[7] < $bounds[1])) {
      _stringFT_origin('cr',$im,@stringargs);
      @bounds = @newbounds;
    }
  }
}

#just like stringFT, but using a different coordinate origin for the text
#does not allow rotated text
sub _stringFT_origin {
  my ($origin,$im,@stringargs) = @_;

  #get a bounding box
  if($origin eq 'll') {
    #lower-left is the native origin for stringFT, so we don't have to do anything
    return $im->stringFT(@stringargs);
  } else {
    my ($yor,$xor) = split '',$origin;
    my @bounds = GD::Image->stringFT(@stringargs);
    my $width = $bounds[2]-$bounds[0];
    my $height = $bounds[3]-$bounds[5];
    $stringargs[5] +=
      $yor eq 'u' ? $height   :
      $yor eq 'c' ? $height/2-2 :
      $yor eq 'l' ? 0         :
	confess "invalid y origin '$yor'";
    $stringargs[4] -=
      $xor eq 'r' ? $width    :
      $xor eq 'c' ? $width/2  :
      $xor eq 'l' ? 0         :
	confess "invalid x origin '$xor'";

#    $im->rectangle(@bounds[6,7,2,3],$stringargs[0]);
    return $im->stringFT(@stringargs);
  }
}

sub _commify_number {
  local $_  = shift;
  return undef unless defined $_;
  1 while s/^(-?\d+)(\d{3})/$1,$2/;
  $_;
}

#   #draw a ruler down the side
#   ruler( $im,
# 	 -start  => [$lpad+$ruler_width/2,$gely+$gelheight],
# 	 -dir    => 'up',
# 	 -length => $gelheight,
# #	 -widtha  => $ruler_width,

# 	 -units    => 'bp',
# 	 -label    => 'length',
# 	 -scale    => 'log',
# 	 -log_base => 10,
# #	 -tick_vals => 
# 	 -range  => [100,10000],
#        );


sub _ladder_lane {
  my ($self) = @_;

  return $self->{ladder_lane} ||= do {
    my @ladder_fragments = (10,30,50,100,200, 300, 400, 500,1000,2000,5000,7000,10000,20000,50000,100000,250000,500000,1000000);

    #look at the other lanes in the gel and figure out which ladder fragments to use
    my @allfrags = map {$_->fragments} $self->lanes;
    my $minfrag = $self->{min_frag} || _min(@allfrags);
    my $maxfrag = $self->{max_frag} || _max(@allfrags);
    my @use_ladder = grep { $_*1.2 >= $minfrag && $_*0.5 <= $maxfrag } @ladder_fragments;
#    warn "min is $minfrag, max is $maxfrag, using ladder ".join(',',@use_ladder)."\n";
    Bio::Graphics::Gel::Lane->new( ladder => \@use_ladder );
  };
}

package Bio::Graphics::Gel::Lane;

use Bio::Tools::Gel;
our @ISA = qw/Bio::Root::Root/;

sub new {
  my ($class,$name,$frags) = @_;
  my $self = $class->SUPER::new;
  $self->name($name);
  $self->fragments(@$frags);
  return $self;
}

sub name {
  my ($self,$name) = @_;
  if($name) {
    $self->{name} = $name;
  }
  return $self->{name};
}

sub fragments {
  my ($self,@frags) = @_;
  if(@frags) {
    foreach (@frags) {
      unless($_+0 eq $_) {
	$self->throw("invalid fragment length $_");
      }
    }
    $self->{frags} = [ sort {$a <=> $b} @frags ];
  }
  return @{$self->{frags}};
}


###
1;#do not remove
###
