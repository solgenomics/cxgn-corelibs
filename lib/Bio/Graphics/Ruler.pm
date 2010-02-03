package Bio::Graphics::Ruler;
use strict;
use warnings;
use English;
use Carp;

use POSIX qw/log10/;
use GD;

=head1 NAME

Bio::Graphics::Ruler - functions for drawing a ruler on a L<GD::Image>

=head1 SYNOPSIS

  ruler( $image,
         -scale    => 'log' or 'linear',
         -label    => 'length',
         -units    => 'bp',
         -range    => [0,1000],

         -start    => [x,y],
         -dir      => 'horizontal',
         -length   => 100, #pixels
         -width    => 10, #pixels

         -font     => 'sans:normal',
         -tt       => 1, #use truetype fonts
         -ticks    => 0,1,2
       );

=head1 DESCRIPTION

Function for drawing a ruler on a L<GD::Image>.

=head1 AUTHOR(S)

Robert Buels - rmb32 at cornell dot edu

=head1 FUNCTIONS

All functions below are EXPORT_OK.

=cut

use base qw/Exporter/;

BEGIN {
  our @EXPORT_OK = qw(
		      ruler
		     );
}
our @EXPORT_OK;

=head2 ruler

  Usage: ruler($image, arg => value, ...)
  Desc : draw a ruler on a GD::Image
  Args : a GD::Image, then the args:
         -scale     => 'log' or 'linear',
         -log_base  => 10,
         -label     => 'length',
         -units     => 'bp',
         -range     => [0,1000],
         -ticks     => 0,1,2

         -start     => [10,20],
         -dir       => 'up',
         -label_pos => 'above' 'below' 'left' 'right'
         -length    => 100, #pixels
         -width     => 10,

         -font      => 'sans:normal', #or a gd font like gdSmallFont
         -tt        => 1, #use truetype fonts

  Ret  : nothing
  Side Effects: draws a ruler on the given image
  Example:

=cut

sub ruler {
  my ($im,%args) = @_;
  UNIVERSAL::isa($im,'GD::Image')
      or croak "first argument must be a GD::Image or a subclass";

  #process options and validate args
  my @valid_args = qw/-scale -log_base -label -units -range -ticks -tick_vals -start -dir -label_pos  -length -width -font -tt/;
  my %valid_args; $valid_args{$_} = 1 foreach @valid_args;
  while(my ($k,$v) = each %args) {
    $valid_args{$k} or croak "invalid argument '$k'";
    if($k eq '-scale') {
      $v eq 'log' or $v eq 'linear'
	or croak "invalid -scale '$v'";
    } elsif($k eq 'log_base') {
      $v eq 'e' || $v =~ /^\d+$/
	or croak "invalid -log_base '$v', must be a number or 'e'";
    } elsif($k eq '-range') {
      ref($v) && ref($v) eq 'ARRAY' && @$v ==2
	&& $v->[0] < $v->[1]
	or croak "invalid -range '$v'";
    } elsif($k eq '-ticks') {
      $v == 0 or $v == 1 or $v == 2
	or croak "invalid -ticks '$v', must be 0, 1, or 2";
    } elsif($k eq '-tick_vals') {
      ref($v) eq 'ARRAY'
	or croak "invalid -tick_vals, must be an arrayref";
    } elsif($k eq '-dir') {
      grep {$v eq $_} qw/up down left right/
	or croak "-dir must be either up, down, left, or right";
    } elsif($k eq '-label_pos') {
      grep {$v eq $_} qw/above below left right/
	or croak "-label_pos must be either above, below, left, or right";
    } elsif($k eq '-length') {
      $v > 0 or croak "invalid length '$v'";
    } elsif($k eq '-width') {
      $v > 0 or croak "invalid width '$v'";
    } elsif($k eq '-start') {
      ref($v) && ref($v) eq 'ARRAY' && @$v ==2
	&& $v->[0] >= 0 && $v->[1] >= 0
	or croak "invalid start '$v'";
    }
  }
  #set defaults
  $args{-scale}      ||= 'linear';
  $args{-log_base}   ||= 10;
  $args{-label}      ||= '';
  $args{-units}      ||= '';
  $args{-range}      ||= [0,1000];
  $args{-ticks}      ||= 2;
  $args{-start}      ||= [0,0];
  $args{-dir}        ||= 'horizontal';
  $args{-label_pos}  ||= $args{-dir} eq 'up' || $args{-dir} eq 'down'  ? 'left' : 'below';
  $args{-length}     ||= 100;
  $args{-width}      ||= 10;
  $args{-tt}         ||= 0;
  $args{-font}       ||= $args{-tt} ? 'sans:normal' : gdSmallFont;

  #draw the base line and end caps
  my $black = $im->colorAllocate(0,0,0);
  $im->setThickness(1);

  my $majwidth = $args{-width};
  my $minwidth = $majwidth*0.75;
  my $len = $args{-length};
  my $s = $args{-start};
  my $e =   $args{-dir} eq 'up'   ? [$s->[0],      $s->[1]-$len] :
	    $args{-dir} eq 'down' ? [$s->[0],      $s->[1]+$len] :
	    $args{-dir} eq 'left' ? [$s->[0]-$len, $s->[1]]      :
	                            [$s->[0]+$len, $s->[1]];
  my ($range_start,$range_end) = @{$args{-range}};
  my $range_length = abs($range_end-$range_start);

  $im->line(@$s,@$e,$black);

  #now draw some tick marks and label them
  my $num2px = do {
    if($args{-scale} eq 'linear') {
      my $px_per_num = $args{-length}/$range_length;
      sub {$_[0]*$px_per_num}
    } elsif($args{-scale} eq 'log') {
      my $logdiff = abs(_log($range_end/($range_start||1),$args{-log_base}));
      my $px_per_num = $args{-length}/$logdiff;
#      warn "logdiff is $logdiff, ppn is $px_per_num\n";
      sub {_log($_[0]||1,$args{-log_base})*$px_per_num}
    }
  };

  #now get the numerical values at which to draw ticks,
  #either calculate them or get them from our arguments
  my @ticks = do {
    if($args{-tick_vals}) {
      @{$args{-tick_vals}}
    } elsif($args{-scale} eq 'linear') {
      my $maj_tick_interval = _pick_linear_tick_interval($range_length,$args{-length},$args{-dir});
      my $maj_tick_step = $range_start > $range_end ? -$maj_tick_interval : $maj_tick_interval;
#      warn "for $args{-range}->[0],$args{-range}->[1], picked maj tick interval of $maj_tick_interval\n";
      my @t;
      for(my $i = 0; $i*$maj_tick_interval<=$range_length; $i++) {
	push @t,$range_start + $i*$maj_tick_step;
      }
      @t
    } elsif($args{-scale} eq 'log') {
      my $log_range_length = abs _log($range_end/($range_start||1),$args{-log_base});
      my $log_range_start = _log($range_start||1,$args{-log_base});
      my $maj_tick_interval = 1;
      my $maj_tick_step = $range_start > $range_end ? -$maj_tick_interval : $maj_tick_interval;
#      warn "for log range length $log_range_length, picked maj tick interval of $maj_tick_interval\n";
      my @t;
       for(my $i = 0; ($i*$maj_tick_interval)<=$log_range_length; $i++) {
 	push @t,_exp($args{-log_base}, $log_range_start + $i*$maj_tick_step);
      }
#      warn "made ticks ".join(',',@t)."\n";
      @t
    }
  };

  #now draw the ticks
  foreach my $tickval (@ticks) {
#    warn "$tickval => ".$num2px->($tickval)."\n";
    my @offset_coords = _offset(@$s,$num2px->($tickval) - $num2px->($range_start) ,$args{-dir});
    _tick($im,$black,,@offset_coords, $majwidth,$args{-dir});
    _label($im,$black, _commify_number($tickval), @offset_coords,$majwidth,$args{-label_pos});
  }
}

sub _commify_number {
  local $_  = shift;
  return undef unless defined $_;
  1 while s/^(-?\d+)(\d{3})/$1,$2/;
  $_;
}

sub _offset {
  my ($x,$y,$distance,$dir) = @_;
  if($dir eq 'up') {
    $y-=$distance;
  } elsif($dir eq 'down') {
    $y+=$distance;
  } elsif($dir eq 'left') {
    $x-=$distance;
  } elsif($dir eq 'right') {
    $x+=$distance;
  } else {
    confess "invalid dir '$dir'";
  }
  return ($x,$y);
}

sub _exp {
  my ($base,$exp) = @_;
  if($base eq 'e') {
    return exp $exp;
  } else {
    $base =~ /^\d+$/ or croak "invalid log base '$base'";
    return $base**$exp;
  }
}
sub _log {
  my ($num,$base) = @_;
  if($base eq 'e') {
    return log $num
  } elsif($base == 10) {
    return log10($num)
  } else {
    $base =~ /^\d+$/ or croak "invalid log base '$base'";
    return log($num)/log($base)
  }
}

#given a range, and the length of pixels we have to cover it,
#pick a good tick interval for it
sub _pick_linear_tick_interval {
  my ($range_length, $length_px, $dir)  = @_;
  $range_length = abs $range_length;

  my $tick_spacing_px = $dir eq 'up' || $dir eq 'down' ? 15 : 25;
  my $ticks_we_have_room_for = int($length_px / $tick_spacing_px);
#  warn "in $length_px, we have room for $ticks_we_have_room_for\n";
  my %possible;
  foreach my $modifier (25,20,5,3,2,1) {
    foreach my $basep (reverse -10..10) {
      my $interval = 10**$basep*$modifier;
      my $numticks = $range_length/$interval;
      #	warn "for $range_length, $interval results in $numticks ticks, we have room for $ticks_we_have_room_for\n";
      if ($numticks <= $ticks_we_have_room_for) {
	$possible{$interval} = 1;
      }
    }
  }

  die "could not pick a tick interval\n"
    unless %possible;

  return (sort {$a <=> $b} keys %possible)[0];
}

sub _tick {
  my ($im,$color,$x,$y,$width,$dir,$label,$label_pos) = @_;

  if($dir eq 'up' || $dir eq 'down') {
    $im->line($x+$width/2,$y,
	      $x-$width/2,$y,
	      $color);
  } elsif($dir eq 'left' || $dir eq 'right' ) {
    $im->line($x,$y+$width/2,
	      $x,$y-$width/2,
	      $color);
  } else {
    confess "invalid direction '$dir'";
  }
}

sub _label {
  my ($im,$color,$text,$x,$y,$width,$label_rel) = @_;
  my $offset = $width/2+2;
  $im->useFontConfig(1);
#  sub dp(@) { print join(',',@_),"\n"; @_ }
  if($label_rel eq 'above') {
    _stringFT_origin('lc',$im,$color,'sans:normal',10, 0,
		     $x,$y-$offset,
		     $text);
  } elsif($label_rel eq 'left') {
    _stringFT_origin('cr',$im,$color,'sans:normal',10, 0,
		     $x-$offset,$y,
		     $text);
  } elsif($label_rel eq 'right' ) {
    _stringFT_origin('cl',$im,$color,'sans:normal',10, 0,
		     $x+$offset,$y,
		     $text);
  } elsif($label_rel eq 'below' ) {
    _stringFT_origin('uc',$im,$color,'sans:normal',10, 0,
		     $x,$y+$offset,
		     $text);
  } else {
    confess "invalid label direction '$label_rel'";
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
      $yor eq 'c' ? $height/2 :
      $yor eq 'l' ? 0         :
	confess "invalid y origin '$yor'";
    $stringargs[4] -=
      $xor eq 'r' ? $width    :
      $xor eq 'c' ? $width/2  :
      $xor eq 'l' ? 0         :
	confess "invalid x origin '$xor'";

    return $im->stringFT(@stringargs);
  }
}

###
1;#do not remove
###
