package CXGN::Phylo::Alignment::Member;

use base qw/ 	CXGN::Tools::Sequence 
				CXGN::Phylo::Alignment::ImageObject /;
use strict;
use GD;
use CXGN::Tools::Identifiers qw/ link_identifier /;

=head1 Package CXGN::Phylo::Alignment::Member

Inherited from ImageObject.  Its special attributes include id, seq, species, seq_line_height, label_spacer, hide and url

=cut

BEGIN {
	our %AA_NAME_TABLE = (
			"F" => "phenylalanine",
			"L" => "leucine",
			"I" => "isoleucine",
			"M" => "methionine",
			"V" => "valine",
			"S" => "serine",
			"P" => "proline",
			"T" => "threonine",
			"A" => "alanine",
			"Y" => "tyrosine",
			"H" => "histidine",
			"Q" => "glutamine",
			"N" => "asparagine",
			"K" => "lysine",
			"D" => "aspartate",
			"E" => "glutamate",
			"C" => "cysteine",
			"W" => "tryptophan",
			"R" => "arginine",
			"G" => "glycine" 
		);



}
our %AA_NAME_TABLE;

=head1 Constructor new()

Synopsis:     my $al_sq = CXGN::Phylo::Alignment::Member->new(
						    left_margin=>$x, 
						    top_margin=>$y, 
						    width=>$z,
						    height=>$h,
						    start_value=>$start_value, 
						    end_value=>$end_value
						    id=>$id,
						    seq=>seq,
						    species=>$species
						   );

Returns:      a CXGN::Phylo::Alignment::Member object

=cut

sub new {
	my $class = shift;
	my %args = @_;
	if(ref($_[0]) eq "HASH"){
		%args = %{$_[0]};
	}
	my $image_obj = CXGN::Phylo::Alignment::ImageObject->new(@_);
	my $self = {};
	#Inherit ImageObject properties
	while(my ($k, $v) = each %$image_obj){
		$self->{$k} = $v;
	}
	bless $self, $class; 
	#$self is now a member of this class, rather than ImageObject
	#Necessary so that it can inherit subs() from CXGN::Tools::Sequence

	$self->{id} = $args{id};
	$self->{seq} = $args{seq};
	$self->{species} = $args{species};
	$self->{hidden} = $args{hidden};
	$self->{type} = $args{type};
	$self->{cds_nocheck} = $args{cds_nocheck};
	$self->{url} = ();
	$self->{regions} = ();
	$self->{non_gaps} = undef; # number of non-gap characters in sequence

	$self->use_liberal_cds();  #CXGN::Tools::Sequence parent method

	if ($self->{seq}) {
		$self->{start_value} = 1 unless $self->{start_value};
		$self->{end_value} = length($self->{seq}) unless $self->{end_value};
		my $seq = $self->get_seq();
		$self->set_nongaps((length $seq) - ($seq =~ tr/-//));
 #	print "# nongaps: ", $self->get_nongaps(), " \n";
	#	readline STDIN;
	}
	
	#extra imagemap areas to include 
	$self->{imagemap_areas} = ();
	if (defined $self->{type} eq "cds") {
		$self->_check_cds if ($self->{type} eq "cds" && !$self->{cds_nocheck});
	}

	#map the alignment position to sequence position, for the sake of efficiency
	#this uses 0-start counting, keep in mind!
	my %alignpos2seqpos = ();
	my %seqpos2alignpos = ();
	my $i = 0;
	my $aa = -1; #gaps before sequence starts will have translation value -1
	while($i < length($self->{seq})){
		my $mer = substr($self->{seq}, $i, 1);
		if($mer eq '-'){
			$alignpos2seqpos{$i} = $aa;
		}
		else{
			$aa++;
			$alignpos2seqpos{$i} = $aa;	
			$seqpos2alignpos{$aa} = $i;
		}
		$i++;
	}
	$self->{alignpos2seqpos} = \%alignpos2seqpos;
	$self->{seqpos2alignpos} = \%seqpos2alignpos;
	
	my $ungapped_seq = $self->{seq};
	$ungapped_seq =~ s/-//g;	
	$self->{ungapped_seq} = $ungapped_seq;	

	return $self;
}

=head1 Setters and getters

set_seq_line_height(), get_seq_lien_width(), set_label_spacer(), get_label_spacer(), is_hidden(), hide_seq(), unhide_seq(), set_url(), get_url(), set_id(), get_id(), set_species(), get_species(), set_seq(), get_seq(), get_select_seq() get_nongaps()

=cut

=head3 add_region

 Add a highlighted region to the alignment member.
 Arguments: "Name", start_pos, end_pos, [r, g, b]
 Example: $mem->add_region("sigpep", 1, 32, [0, 90, 0]);

=cut

sub get_ungapped_seq {
	my $self = shift;
	if(!$self->{ungapped_seq}){
		my $unseq = $self->{seq};
		$unseq =~ s/-//g;
		$self->{ungapped_seq} = $unseq;
	}
	return $self->{ungapped_seq};
}
sub add_region {
	my $self = shift;
	my ($name, $start, $end, $rgb) = @_;
	#$rgb = [255, 255, 0]
	unless($start && $end) {
		die "Must specify a start point and end point of the region";
	}
	($start, $end) = $self->translate_positions_to_align($start, $end);
	$self->{regions}->{$name}->{start} = $start;
	$self->{regions}->{$name}->{end} = $end;
	$self->{regions}->{$name}->{color} = $rgb;
	
}

=head3

 Remove a region by its given name, which this function
 takes as an argument.
 Example: $mem->remove_region("sigpep");

=cut

sub remove_region {
	my $self = shift;
	my $name = shift;
	delete $self->{regions}->{$name};
}

=head3 smallest_region_where_position_is 

 Given a position, the function tells you the name of the region
 you are in.  If you have overlapping regions, it returns the
 first region found in the hash.  Don't overlap.*

 *Ok, turns out you have to overlap.  Return the smallest
 region (most significant?), which will be flanked by a 
 larger region.

 Example: my $name = $mem->smallest_region_where_position_is(32);

=cut

sub smallest_region_where_position_is {
	my $self = shift;
	my $position = shift;
	my %size2region = ();
	foreach(keys %{$self->{regions}}){
		my $region_start = $self->{regions}->{$_}->{start};
		my $region_end = $self->{regions}->{$_}->{end};
		my $size = $region_end - $region_start;
		$size2region{$size} = $_ if ($position >= $region_start && $position <= $region_end);
	}
	my @ordered_sizes = sort {$a <=> $b} (keys %size2region);
	my $key = shift @ordered_sizes;
	if($key){
		return $size2region{$key};
	}
	return undef;
}

=head3 regions_where_position_is 

 Given a position, the function tells you the names of the regions
 you are in, in array format.  
 
 Example: my @region_names = $mem->regions_where_position_is(32);

=cut

sub regions_where_position_is {
	my $self = shift;
	my $position = shift;
	my @regions = ();
	foreach(keys %{$self->{regions}}){
		my $region_start = $self->{regions}->{$_}->{start};
		my $region_end = $self->{regions}->{$_}->{end};
		push(@regions, $_) if ($position >= $region_start && $position <= $region_end);
	}
	return @regions;
}


sub seqpos2alignpos {
	my $self = shift;
	my $seqpos = shift;
	return $self->{seqpos2alignpos}->{$seqpos};

}

sub alignpos2seqpos {
	my $self = shift;
	my $alignpos = shift;
	return $self->{alignpos2seqpos}->{$alignpos};
}

=head3 translate_positions_to_align
 
 Given a start and end value for sequence positions,
 translates these values to alignment positions and
 returns them in order

 Arguments: [Sequence] Start Position (int), End Position (int)
 Returns: [Alignment] Start Position (int), End Position (int)
 Example: my ($a_s, $a_e) = $member->translate(115, 129);

=cut

sub translate_positions_to_align {
	my $self = shift;
	my ($start, $end) = @_;
	my ($a_s, $a_e) = (0, 0); #will hold results
	$a_s = $self->{seqpos2alignpos}->{$start};
	$a_e = $self->{seqpos2alignpos}->{$end};
	return ($a_s, $a_e);
}

sub translate_positions_to_seq {
	my $self = shift;
	my ($a_s, $a_e) = @_;
	my ($seq_start, $seq_end) = (0,0);
	$seq_start = $self->{alignpos2seqpos}->{$a_s};
	$seq_end = $self->{alignpos2seqpos}->{$a_e};
	return ($seq_start, $seq_end);
}


sub set_label_spacer { 
  my $self = shift;
  $self->{label_spacer} = shift;
}

sub get_label_spacer {
  my $self = shift;
  return $self->{label_spacer};
}

sub set_seq_line_height {
  my $self = shift;
  $self->{seq_line_height} = shift;
}

sub get_seq_line_height {
  my $self = shift;
  return $self->{seq_line_height};
}

sub set_id {
  my $self = shift;
  $self->{id} = shift;
}

sub get_id {
  my $self = shift;
  return $self->{id};
}

sub set_species {
  my $self = shift;
  $self->{species} = shift;
}

sub get_species {
  my $self = shift;
  return $self->{species};
}

sub set_seq {
  my $self = shift;
  $self->{seq} = shift;
}

sub get_seq {
  my $self = shift;
  return $self->{seq};
}

sub get_select_seq {
  my $self = shift;
  my $id = $self->{id};
  my $seq = $self->{seq};
  # return $seq if($seq eq "");
  $seq = substr($seq, $self->{start_value} - 1, $self->{end_value} - $self->{start_value} + 1);
  return $seq;
}

sub set_nongaps{
	my $self = shift;
	my $nongaps = shift;
	$self->{non_gaps} = $nongaps;
}
sub get_nongaps{
	my $self = shift;
	return $self->{non_gaps};
}

sub layout_seq_line_height {
	my ($self, $slh) = @_;
	my $clh = $self->{seq_line_height};
	$clh ||= 0;
	$self->{seq_line_height} = $slh unless($clh>0);
}

=head3 is_hidden()

Synopsis: member->is_hidden();

Description:  check if itself is hidden

Returns: 1 (true) if the sequence is hidden and 0 (false) if not.  It is set to 0 (un-hidden) by default when the object is constructed.

=cut
 
sub is_hidden {
  my $self = shift;
  return $self->{hidden};
}

sub hide_seq {
  my $self = shift;
  $self->{hidden} = 1;
}

sub unhide_seq {
  my $self = shift;
  $self->{hidden} = 0;
}

sub show_remove {
	my $self = shift;
	$self->{show_remove} = 1;
}

sub hide_remove {
	my $self = shift;
	$self->{show_remove} = 0;
}

sub show_link {
	my $self = shift;
	$self->{link_shown} = 1;
}

sub hide_link {	
	my $self = shift;
	$self->{link_shown} = 0;
}

=head1 Image display subs

=cut

=head2 render()

Synopsis: member->render($image) where $image is an image object

Description: render the member object

Returns: 

=cut

sub render {
	my $self = shift;
	my $image = shift;  
	#affects values if they haven't already been set:
	$self->layout_color(40, 10, 180);  
	$self->layout_label_color(0, 0, 0);
	$self->layout_label_spacer(20);
	$self->layout_seq_line_height(8);
	$self->_calculate_scaling_factor();

	my @member_color = ($self->{color}[0], $self->{color}[1], $self->{color}[2]);
	my @lightened = map { 255 - (255-$_)*0.2 } @member_color;
	my $lightened_color = $image->colorResolve(@lightened);

	my $member_color = $image->colorResolve(@member_color);
	
	my $show_base = 0;
	my $color;
	if(($self->{scaling_factor}) < $self->{font}->width) {
		$show_base = 0;
	}
	else {
		$show_base = 1;
	}
	$self->{show_base} = $show_base;

	my @label_color = ($self->{label_color}[0], $self->{label_color}[1], $self->{label_color}[2]);
	my $label_color = $image->colorResolve(@label_color);
	my $base_color = $image->colorResolve(0, 0, 0);

	
	if($self->{link_shown} && link_identifier($self->{id})){
		$label_color = $image->colorResolve(50, 50, 200);
	}

	my $member = substr ($self->{seq}, $self->{start_value}-1, $self->{end_value}-$self->{start_value}+1);
	
	my $seq_id = $self->{id};
	
	my $i;
	my $red = $image->colorResolve(150, 20, 20);
	my $blue = $image->colorResolve(20, 20, 150);
	my $gold = $image->colorResolve(100, 100, 20);
	my $purple = $image->colorResolve(100, 20, 100);
	my $green = $image->colorResolve(20, 100, 20);

	for($i = 0; $i < length($member); $i++){
		my $base = substr($member, $i, 1);
		
		if ($base eq '-'){

			if($show_base) { 
				$color = $lightened_color;
			}
			else {
				$color = $member_color;
			}

			#Color Line with region color, but only if next region the same, preventing 
			#colored tail lines after a region. {/////------}{||||||}
			my $aa_pos = $self->alignpos2seqpos($i+$self->{start_value}-1);
			my $next_pos = $self->seqpos2alignpos($aa_pos+1); 
			$next_pos = $self->seqpos2alignpos($aa_pos) unless defined $next_pos;
			my $smallest_r = $self->smallest_region_where_position_is($i+$self->{start_value}-1);
			my $next_r = $self->smallest_region_where_position_is($next_pos+1); 
			if($smallest_r && $next_r && ($smallest_r eq $next_r)){
				my @r_color = @{$self->{regions}->{$smallest_r}->{color}};
				my @r_lite_color = map{255-(255-$_)*0.4} @r_color;
				if($show_base){
					$color = $image->colorResolve(@r_lite_color);
				} else { $color = $image->colorResolve(@r_color); }
			}
	
			my $x1 = $i*$self->{scaling_factor}+$self->{left_margin};
			my $x2 = ($i+1)*$self->{scaling_factor}+$self->{left_margin};
			$image->line(	$x1,	
							$self->{top_margin}, 
							$x2,
							$self->{top_margin}, 
							$color	);
		}

	}


	for ($i = 0; $i < length ($member); $i++){
		
		#draw sequence, a line if the base is a gap and a rectangle otherwise
		my $base = substr($member, $i, 1);
		if($show_base) { 
			$color = $lightened_color;
		}
		else {
			$color = $member_color;
		}
		if($base ne '-'){
			my @regions = $self->regions_where_position_is($i + $self->{start_value});
			my $x1 = $i*$self->{scaling_factor} + $self->{left_margin};	
			my $y1 = $self->{top_margin} - $self->{seq_line_height}/2;
			my $x2 = ($i+1)*$self->{scaling_factor} + $self->{left_margin};
			my $y2 = $self->{top_margin} + $self->{seq_line_height}/2;
			if(@regions){
				my $reg_height = $self->{seq_line_height}/(scalar @regions);
				foreach my $r (@regions){
					my @region_color = @{$self->{regions}->{$r}->{color}};
					next unless ((scalar @region_color)==3);
					my @lightened_region = map{255-(255-$_)*0.4} @region_color;
					if($show_base){
						$color = $image->colorResolve(@lightened_region);
					}
					else {
						$color = $image->colorResolve(@region_color);
					}
					my $t_y2 = $y1 + $reg_height;
					$t_y2 = $y2 if ($y2 - $t_y2 < $reg_height);
					$image->filledRectangle($x1,$y1,$x2,$t_y2, $color);
					$y1+=$reg_height;
				}
			}
			else {	
				$image->filledRectangle($x1, $y1, $x2, $y2, $color);
			}

			 if($show_base){
				if($self->{type} eq "pep"){
					my $type = $self->_get_aa_type($base);
					$base_color = $red if ($type eq "acidic");
					$base_color = $green if ($type eq "basic");
					$base_color = $gold if ($type eq "nonpolar");
					$base_color = $blue if ($type eq "polar");
				}

			 	$image->char(	$self->{font},
								$i*$self->{scaling_factor} + $self->{left_margin} + $self->{scaling_factor}/2 - $self->{font}->width/3,
								$self->{top_margin} - $self->{seq_line_height} / 2 - $self->{font}->height/6,
								uc($base),
								$base_color );
				my $coords = join ",", ($i*$self->{scaling_factor}+$self->{left_margin}, $self->{top_margin} - $self->{seq_line_height}/2,
										($i+1)*$self->{scaling_factor}+$self->{left_margin}, $self->{top_margin} + $self->{seq_line_height}/2);
				my $id = $self->{id};
				my $pos = $self->{alignpos2seqpos}->{$i+$self->{start_value}-1} + 1;
				my $aa_name = ucfirst($self->_get_aa_name($base));
				my $aa_type = ucfirst($self->_get_aa_type($base));
				$aa_name ||= "Unknown";
				my $title = "AA #$pos ($aa_name) of $id";
				my $area_string = "<area shape=\"rect\" coords=\"$coords\" title=\"$title\">";
				$self->add_imagemap_area($area_string);
			}
		}
	}
	

	#add sequence name, first chop the sequence name to up to 30 characters. add '..' if the name is longer
	my $displayed_id;
	my $id = $self->{id};
	$id||="";
	my $species = $self->{species};
	$species||="";
	my $full_id = "$id $species";
	if ((length $full_id) >= 90) {
		$displayed_id = substr ($full_id, 0, 90);
		$displayed_id .= '..';
	}
	else {
		$displayed_id = $full_id;
	}
	$self->{displayed_id} = $displayed_id;
	
	$image->string(		$self->{font}, 
						length($member)*$self->{scaling_factor} + $self->{left_margin} + $self->{label_spacer}, 
						$self->{top_margin} - $self->{seq_line_height} / 2 - $self->{font}->height()/4, 
						$displayed_id, 
						$label_color	);

	if($self->{show_remove}){	
		#Add an X for removal of sequence (imagemap adds id to list of sequences to remove on page form)
		my $remove_color = $image->colorResolve(100, 30, 30);
		my ($tlx, $tly, $brx, $bry) = $self->get_remove_enclosing_rect();
		my ($w, $h) = ($brx - $tlx, $bry - $tly);
		$image->line( $tlx, $tly, $brx, $bry, $remove_color); # \
		$image->line( $tlx, $tly+$h, $brx, $bry-$h, $remove_color); # /    
	}
}

=head1 Sequence analyzing subs

get_nogap_length(), calculate_similarity(), get_medium(), get_range()

All analysis are in the range from start_value to end_value

=cut

sub get_nogap_length {
  my $self = shift;
  my $no_gap_seq = $self->get_select_seq();
  $no_gap_seq =~ s/-//g;
  return length ($no_gap_seq);
}

=head3 calculate_similarity()

Synopsis: $member->calculate_similarity($other_member) where $other_member is another member object

Description: get the overlap base number and idnetical percentage of the seq of two member objects.

Returns:  an integer (number of overlap base) and a float (percentage indentity)

=cut

sub calculate_similarity {
  my $self = shift;
  my $other_seq = shift;
  ($self->get_width() != $other_seq->get_width()) 
  	and return;
  my ($overlap_base, $identical_base) = (0, 0);
  for (my $i = $self->{start_value} - 1; $i < $self->{end_value}-1; $i++){
    my $self_base = substr ($self->{seq}, $i, 1);
    my $other_base = substr($other_seq->{seq}, $i, 1);
    (($self_base eq '-') || ($other_base eq '-')) and next;
    $overlap_base++;
    ($self_base eq $other_base) and $identical_base++;
  }
  if ($overlap_base != 0){
    return $overlap_base, $identical_base/ $overlap_base * 100;
  }
  else {
    return $overlap_base, $identical_base;
  }
}

=head3 $member->get_clean_member()

Synopsis: ($clean_seq_1, $clean_seq_2) = $member1->get_clean_member($member2) where $member2 is another member object

Description:  goes through the two alignment sequences, in the conmmon range, and leave out common gaps.  

Returns: two 'clean' overlap sequences, with common gaps removed.

=cut

sub get_clean_member {
  my $self = shift;
  my $other_seq = shift;

  ($self->get_width() != $other_seq->get_width()) and return;
  my ($start1, $end1) = $self->get_range();##Takes care of start_value and end_value
  my ($start2, $end2) = $other_seq->get_range();
  my ($start, $end);

  ($start1 > $start2) ? ($start = $start1) : ($start = $start2);
  ($end1 < $end2) ? ($end = $end1) : ($end = $end2);

  my $id1 = $self->get_id();
  my $id2 = $other_seq->get_id();
  
  my ($seq1, $seq2);
  for (my $i=$start-1; $i<$end-1; $i++) {
    my $base1 = substr ($self->get_seq(), $i, 1);
    my $base2 = substr ($other_seq->get_seq(), $i, 1);

    ($base1 eq '-' && $base2 eq '-') and next;
    $seq1 .= $base1;
    $seq2 .= $base2;
  }
  
  return $seq1, $seq2;
}

=head3 get_medium()

Synopsis: $member->get_medium() 

Description: calculate the middle point of non-gap bases of the member

Returns: an integer

=cut

sub get_medium {
  my $self = shift;
 
  my $non_gap_len = 0;
  my $seq = $self->get_select_seq();
  while ($seq =~ /[A-Z]/gi) {
    $non_gap_len++;
  }

  my $non_gap_mid = int ($non_gap_len / 2);
  my $non_gap_count = 0;
  
  my $mid;
  foreach ( my $i = $self->{start_value}-1; $i < $self->{end_value}; $i++){
    my $base = substr($self->{seq}, $i, 1);
    ($base ne '-') and $non_gap_count++; 
    if ($non_gap_count > $non_gap_mid) {
      $mid = $i;
      last;
    }
  }

  $mid = $mid + $self->{start_value};
  return $mid;
}

=head3 get_range()

 Synopsis: $member->get_range()
 Description: Get the position of the first non-gap character and the 
              last non-gap character, from start_value to end_value.
 Returns: Two integers representing positions.

=cut

sub get_range {
  my $self = shift;
  my ($base_start, $base_end);

  my $seq = $self->get_select_seq();
  
  my ($head_gaps) = $seq =~ /^(-+)/;
  my ($tail_gaps) = $seq =~ /(-+)$/;
  (!defined $head_gaps) and $head_gaps = '';
  (!defined $tail_gaps) and $tail_gaps = '';
  $base_start = $self->get_start_value() + length ($head_gaps);
  $base_end = $self->get_end_value() - length ($tail_gaps);

  return $base_start, $base_end;
}


sub get_label_enclosing_rect {
	my $self = shift;
	my $height_adj = 0 - $self->{seq_line_height} / 2 - $self->{font}->height()/4;
	my $left_bound = $self->get_left_margin()+$self->get_width();
	my $label = $self->{displayed_id};
	$label ||= $self->{id};
	return (
		$left_bound,
			$self->get_top_margin() + $height_adj,
		$left_bound + (length($label)*$self->{font}->width()),
			$self->get_top_margin() + $height_adj + $self->get_height()
	);
}

sub get_remove_enclosing_rect {
	my $self = shift;
	my ($tlx, $tly, $brx, $bry) = map {int($_)} 
		($self->get_width() + $self->get_left_margin() - 12, $self->get_top_margin - 3,
		 $self->get_width() + $self->get_left_margin() - 6,  $self->get_top_margin + 3);
	#	($self->get_left_margin() - 12, $self->get_top_margin - 3,
	#	 $self->get_left_margin() - 6,  $self->get_top_margin + 3);
	return ($tlx, $tly, $brx, $bry);
}

sub add_imagemap_area {
	my $self = shift;
	my $area_string = shift;
	push(@{$self->{imagemap_areas}}, $area_string);
}

sub get_imagemap_string {
	my $self = shift;
	my $coords = join ",", ($self->get_label_enclosing_rect());
	my $string;
	my ($url, $id, $title) = ($self->get_url, $self->get_id, $self->get_tooltip);
	
	if ($self->get_url()) {  
		$string = <<HTML;
<area 	shape="rect" 
		coords="$coords" 
		title="$title"
		href="$url" 
		alt="$id"	>
HTML
	}

	if($self->{show_remove}){
		my $remove_coords = join ",", $self->get_remove_enclosing_rect();
		
		$string.= <<HTML;
<area  shape="rect"
	   coords="$remove_coords"
	   title="Click to remove this member from analyzed sequences (added to list below)"
	   alt="Remove $id"
	   href="#"
	   onclick="
	   		var old_val = document.getElementById('hide_seqs').value;
			var new_val = old_val + ' $id';
			document.getElementById('hide_seqs').value = new_val;
			return false;" >
HTML
	}
	
	
	#Add the other imagemap areas
	$string .= "\n$_\n" foreach @{$self->{imagemap_areas}};

	return $string;
}

sub _get_aa_type {
    my ($self, $aa) = @_;
    $aa = uc($aa);
    return -1 unless (length($aa)==1);
    return "acidic" if ($aa =~ /D|E/);
    return "basic" if ($aa =~ /R|H|K/);
    return "polar" if ($aa =~ /N|C|Q|S|T/);
    return "nonpolar" if ($aa =~ /A|G|I|L|M|F|P|W|Y|V/);
}

sub _get_aa_name {
	my ($self, $aa) = @_;
	$aa = uc($aa);
	return -1 unless (length($aa)==1);
	return $AA_NAME_TABLE{$aa};
}

sub _check_cds {
	my $self = shift;
	my $cds_seq = $self->{seq};
	#if ungapped, nothing to check
	return unless $cds_seq =~ /-/;
	$cds_seq =~ s/---//g;
	die "Poorly gapped CDS: " . $self->{id} . "  $cds_seq" if $cds_seq =~ /-/;
}

=head3 to_fasta 

 Returns string-fasta representation of member, i.e:
 ">Member_id / Species
  ---ATTGCC---GCGGG---GGCGGCAATTTA------"

=cut

sub to_fasta {
	my $self = shift;
	my $string = "";
	$string .= ">" . $self->{id};
	$string .= " / " . $self->{species} if $self->{species};
	my $pseq = $self->{seq};
	$pseq =~ s/([\w-]{80})/$1\n/g; # allow "-" (gap char) in string
	chomp $pseq;
	$string .= "\n$pseq";
	return $string;
}

####	
1;##
####


