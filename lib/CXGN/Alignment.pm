#!/usr/bin/perl -w
#################################General Description#########################################

=head1 Name and Description

Alignment -- packages for analyzing, optimizing and displaying sequence alignments

=cut

=head1 Author

Chenwei Lin (cl295@cornell.edu)

=cut

=head1 Packages

align, image_object, align_seq, ruler, chart

Packages align_seq, ruler and chart inherit from image_object

=cut

##############################End of General Description######################################



use strict;
use GD;
#use GD::Image;
use File::Temp;

1;


################################Package align###############################################
=head1 Package CXGN::Alignment::align
 
The basic element of the align object is an array of align_seq.
  
Its attributes include: align_name, width (pixel), height(pixel), image, align_seqs, ruler, chart, conserved_seq, sv_overlap, sv_identtity, start_value and end_value 

It functionality includes:
 
1. Image display. 

2. Calculation and output of pairwise similaity and putative splice variant pairs based on similarity. 

3. Hide some alignment sequences so that they are not included in the analysis.

4. Select a range of sequences to be analyzed.

5. Asses how a align_seq member overlap with other align_seq members.  

6. Calculate the non-gap mid point of each align sequence and group the sequences according to their overlap.
 

=cut

package CXGN::Alignment::align;

=head2 Constructer new()

=cut

=head3

Synopsis:  my $align = CXGN::Alignment::align->new(
                                                   align_name=>$name,
                                                   width=>$width, 
                                                   height=>$height, 
                                                   type=>$type, #'nt' or 'pep'
                                                   );

Description:  Upon constructing a align object, it sets align_name, width and height using arguments.  It also genertes a image object of {length} and {height} and sets the default value of sv_overlap, sv_idnentity (the minimum number overlapping aa and percentage identity for two align_seq to be considered as putattive splice variant), sv_indel_limit (the min aa indel length for two sequences to be condiered as splice variants, instead of allele) and start_value (the start value of the ruler and align_seq objects(s))

Returns: an CXGN::Alignment::align object

=cut

sub new { 
    my $class = shift;
    my %args = @_;
    my $self = bless {}, $class;

    ##################set attibutes from parameter
    $self->{align_name} = $args{align_name};
    $self->{width} = $args{width};
    $self->{height} = $args{height};
    $self->{type} = $args{type};

    ##################set defaults
    #splice variants criteria
    $self->{sv_overlap} = 20; #set for amino acid
    $self->{sv_identity} = 95;
    $self->{indel_limit} = 4; #set for amono acid
    $self->{start_value} = 1; #the end_value is initiated when the first align_seq is added

    #image offsets
    $self->{horizontal_offset} = 30;
    $self->{vertical_offset} = 30;

    ##################define some 'empty' attributes that will be asigned later
    @{$self->{align_seqs}} = ();
    $self->{ruler} = ();
    $self->{chart} = ();
    $self->{conserved_seq} = ();    
    $self->{seq_length} = ();
    $self->{image} = ();
    
    return $self;
}

=head2 Setters and getters

get_align_name(), set_align_name()

get_image(), set_image()

get_width(), set_width()

get_height(), set_height()

get_seq_length()

get_sv_criteria(), set_sv_criteria()

get_start_value(), set_start_value(), check_start_value()

get_end_value(), set_end_value(), check_end_value()

get_horizontal_offset(), set_horizontal_offset(), get_vertical_offset(), set_vertical_offset()

Those for align_name, image, sv_overlap and sv_identity, height, width, horizontal_offset, vertical_offset are straightforward, while the setters for start_value, end_value are not simple, since these attributes are related to and/or restricted by other attibutes.  seq_length is determined by the members of @align_seqs therefore can not be reset.

=cut

sub get_align_name {
  my $self= shift; 
  return $self->{align_name};
}

sub set_align_name {
  my $self = shift;
  my $name = shift;
  $self->{align_name} = $name;
}

sub get_image {
  my $self = shift;
  return $self->{image};
}

sub set_image {
  my $self = shift;
  my $image = new GD::Image($self->{width}, $self->{height});#generate a new image object using the current width and height attributes of the align object
  $self->{image} = $image;
}
 
sub get_width {
  my $self = shift;
  return $self->{width};
}

sub get_height {
  my $self = shift;
  return $self->{height};
}

=head3 set_width(), set_height()

Synopsis: set_width($x), set_height($x)

Description:  sets the attributes {width} and {height}.  Since the {iamge} attribute's width and height is related to {width} and {height}, when {width} and {height} are set, a {iamge} is re-generated.  Otherwise, setting the {width} and {height} won't have any real effect.

Returns:  

=cut

sub set_width {
  my $self = shift;
  $self->{width} = shift;
  #$self->set_image();
}

sub set_height {
  my $self = shift;
  $self->{height} = shift;
  #$self->set_image;
}

=head3 set_sv_criteria()

Synopsis:  $align->set_sv_criteria($x, $y, $z), while $x is minimum oberlap, $y is a percentage similarity and $z is the minimal amino acid indel length to be considered as splice variant

Description:  set the putative splice variants standard, the minimum overlapping bases and percentage identity (sv_overlap and sv_identity).  The sub checks if the values are correct before setting the arributes

Returns:

=cut

sub set_sv_criteria {
  my $self = shift;
  my ($overlap, $identity, $indel) = @_;

  if ($overlap <= 0) {
    die "Overlap must be greater than 0!\n";
  }
  elsif (($identity < 0) || ($identity > 100)){
    die "Percentage identity must be greater than 0 and less than 100\n";
  }
  elsif ($indel < 0) {
    die "Indel limit must be greater than 0!\n";
  }
  else {
    $self->{sv_overlap} = $overlap;
    $self->{sv_identity} = $identity;
    $self->{indel_limit} = $indel;
  }
}

sub get_sv_criteria {
  my $self = shift;
  return $self->{sv_overlap}, $self->{sv_identity}, $self->{sv_indel_limit};
}

sub set_horizontal_offset {
  my $self = shift;
  $self->{horizontal_offset} = shift;
}

sub get_horizontal_offset {
  my $self = shift;
  return $self->{horizontal_offset};
}

sub set_vertical_offset {
  my $self = shift;
  $self->{vertical_offset} = shift;
}

sub get_vertical_offset {
  my $self = shift;
  return $self->{vertical_offset};
}

sub get_start_value {
  my $self = shift;
  return $self->{start_value};
}

sub get_end_value {
  my $self = shift;
  return $self->{end_value};
}

sub check_start_value {
  my $self = shift;
  my $value = shift;
  if ($value < 0){
    $value = 0;
    print "$self->{id} start_value less than 0, reset to 0\n";
  }
  return $value;
}

sub check_end_value {
  my $self = shift;
  my $value = shift;
  if ($value > length $self->{align_seqs}[0]->{seq}){
    $value = length $self->{align_seqs}[0];
    print "value greater than sequence length, reset to sequence length\n";
  }
  return $value;
}

sub get_seq_length {
  my $self = shift;
  return $self->{seq_length};
}

=head3 set_start_value(), set_end_value()

Synopsis:  set_start_value($x), set_end_value($x)

Description: set the start_value and end_value.  Check if the input value is correct before setting the attributes.  Since the {start_value} and {end_value} attributes of the {ruler} and {align_seqs} members must be the same as those of the align object, the set subs call the set_start_value and set_end_value of the {ruler} and all members of {align_seqs} 

Returns:

=cut

sub set_start_value {
  my $self = shift;
  my $value = shift;
  $value = $self->check_start_value($value);#check if the start value is correct
  $self->{start_value} = $value; #set the start_value of the included ruler

  foreach (@{$self->{align_seqs}}) { #set the start_value of each included align_seq
    $_->set_start_value($value);
  }
}

sub set_end_value {
  my $self = shift;
  my $value = shift;
  #$value = $self->check_end_value($value);#check if the end value is correct
  $self->{end_value} = $value; 
  
  foreach (@{$self->{align_seqs}}) { #set the start_value of each included align_seq
    $_->set_end_value($value);
  }
}


=head2 Subroutines to add attributes to align object

add_align_seq(), _add_ruler(), _add_cvg_chart, _add_conserved_seq_obj()

=cut

=head3 add_align_seq()

Synopsis:  $align->add_align_seq($align_seq),  while align_seq is an align_seq object

Description: Add align_seq to align object.  The align_seq objects are stored in an array align_seqs.  Once the first align_seq object is added, nly align_seq object of the same length can be further added.  At the same time, the end_value is set to be the same as the sequence length of the first align_seqs member added.

Returns: 

=cut

sub add_align_seq {
  my $self = shift;    
  my $member = shift;
  if (! @{$self->{align_seqs}}){

    #if there is no members in @align_seqs, reset the end_value of overall alignment to the length of this sequence
    $self->set_end_value($member->get_end_value());
    $self->{seq_length} = length ($member->get_select_seq());

    #adjust the vertical and horizontal offsets and length
    $member->set_horizontal_offset($self->{horizontal_offset});
    #$member->set_vertical_offset($self->{vertical_offset} + 50);
    $member->set_length($self->{width} - 250);
    #add the align_seq to @align_seqs
    push @{$self->{align_seqs}}, $member;
  }
  else {

    #the length of the align_seq must the the same as the first member in @align_seqs, otherwise it won't be added
   
    if ( length($member->get_seq()) == $self->{seq_length}){ 

      #set the start_value and end_value is set to the current values of overall align and adjust the image length of sequence according to the width of overall alignment
      $member->set_start_value($self->get_start_value());
      $member->set_end_value($self->get_end_value());
      $member->set_length($self->{width} - 250);

      #adjust the vertical and horizontal offsets
      my $last_member = int @{$self->{align_seqs}} - 1;
      my $last_v_offset = $self->{align_seqs}[$last_member]->get_vertical_offset();
      $member->set_horizontal_offset($self->{horizontal_offset});
      #$member->set_vertical_offset($last_v_offset + 15);
      
      push @{$self->{align_seqs}}, $member;
    }
    else {
      my $id = $member->get_id();

      return;
#      die "error in adding sequence $id, length not the same as overall alignment, skip\n";
    }
  }
}

=head3 _add_ruler()

Synopsis: $align->_add_ruler($x,$y), while $x is the vertical offset and $y is the height of the ruler.

Description:  Add a ruler to the align object, the start_value and end_value are set to the same as those of the align.  If no align_seq has been added to the align object, the seq_length, start_value and end_value of the align are not set (see sub add_align_seq), then a ruler can not be added.

Returns:  

=cut

sub _add_ruler {
  my $self = shift;
  my $v_offset = shift;
  my $hi = shift;

  my $ruler = CXGN::Alignment::ruler->new (
					   horizontal_offset=>$self->{horizontal_offset},
					   vertical_offset=>$v_offset,
					   length=>($self->{width} - 250), 
					   height=>$hi,
					   start_value=>$self->{start_value}, 
					   end_value=>$self->{end_value}
					  ); 
  ($self->{type} eq 'pep') and ($ruler->set_unit('aa'));
  
  $self->{ruler} = $ruler;
}

=head3 _add_cvg_chart()

Synopsis: $align->_add_ruler($x,$y,$z), while $x is the vertical offset, $y is the id and $z is a hash reference whose key is a interger (a position) and value is a percentage

Description:  Add a chart representing coverage by member align_seq.  The start_value and end_value are set to the same as those of the align.  The coverage of each align postion is repreesnted by a hash reference passed to the subroutine.  The key of the hash is the align postion and the values are percentage converage. 

Returns:  

=cut


sub _add_cvg_chart {
  my $self = shift;
  my $v_offset = shift; #vertical offset
  my $id = shift;
  my $hash_ref = shift;

  my $chart = CXGN::Alignment::chart->new (
					   horizontal_offset=>$self->{horizontal_offset}, 
					   vertical_offset=>$v_offset, 
					   length=>($self->{width} - 250),
					   height=>50,
					   start_value=>$self->{start_value}, 
					   end_value=>$self->{end_value}, 
					   id=>$id, 
					   hash_ref=>$hash_ref
					  ); 
  $self->{chart} = $chart;
}


=head3 _add_conserved_seq_obj()

Synopsis: $align->_add_conserved_seq_obj($x), while $x is the vertical offset.

Description:  Add a align_seq object representing the conserved sequence of the @align_seqs.  The seq of this object is generated by another subroutine get_conserved_seq.   If the sequence at a position is not conserved among all present members, it is repreesnted by - in conserved_seq.  This object is NOT a  member of @align_seqs.

Returns:  

=cut

sub _add_conserved_seq_obj {
  my $self = shift;
  my $v_offset = shift;

  my $seq = $self->get_conserved_seq();
  my $seq_obj = CXGN::Alignment::align_seq->new (
						 horizontal_offset=>$self->{horizontal_offset}, 
						 vertical_offset=>$v_offset, 
						 length=>($self->{width} - 250), 
						 height=>15, 
						 start_value=>$self->{start_value}, 
						 end_value=>$self->{end_value}, 
						 id=>'Overall Conserved Sequence', 
						 seq=>$seq,
						 species=>' ',
						);
  $seq_obj->set_color(0,0,122);
  $self->{conserved_seq} = $seq_obj;
}

=head2 Subroutines to search and ouput ids of @align_seq members

is_id_member(), is_member(), id_to_member(), get_member_ids(), get_nonhidden_member_ids, get_hidden_member_ids(), get_member_species(), get_member_urls()

=cut

=head3 is_id_member()

Synopsis: is_id_member($id)

Description:  Does any of the align_seqs member have the same id as $id?

Returns:  0 for true and -1 for false

=cut

sub is_id_member {
  my $self = shift;
  my $id = shift;
  foreach (@{$self->{align_seqs}}) {
    if (($_->{id}) eq $id) {
      return 0;
      exit;
    }
  }
  return -1;
}

=head3 is_member()

Synopsis:  is_member($align_seq), while $align_seq is an align_seq object 

Description:  is $align_seq already a align_seqs member?

Returns:  0 for true and -1 for false

=cut

sub is_member {
  my $self = shift;
  my $member = shift;
  foreach (@{$self->{align_seqs}}) {
    if ($member == $_) {
      return 0;
      exit;
    }
  }
  return -1;
}
=head3 id_to_member()

Synopsis: $align->id_to_member($id);

Description: check if a align member has the id $id and return the align member

Returns: an align object

=cut
  
sub id_to_member {
  my $self = shift;
  my $id = shift;
  foreach (@{$self->{align_seqs}}) {
    if (($_->{id}) eq $id) {
      return $_;
      exit;
    }
  }
}

=head3 get_member_ids()

Synopsis: $align->get_member_ids()

Description:  Returns ids of all align_seqs members

Returns:  an array of ids of all non-hidden @align_seq members

=cut
  
sub get_member_ids {
  my $self = shift;

  my @members = ();
  foreach (@{$self->{align_seqs}}){
    my $id = $_->get_id();
    push @members, $id;
  }
  return \@members;
}

sub get_member_nr {
  my $self = shift;

  my $number = int (@{$self->{align_seqs}});
  return $number;
}


=head3 get_nonhidden_member_ids()

Synopsis: $align->get_nonhidden_member_ids()

Description:  Returns ids of align_seqs members that are not hidden

Returns:  an array of ids of all non-hidden @align_seq members

=cut

sub get_nonhidden_member_ids {
  my $self = shift;

  my @members = ();
  foreach (@{$self->{align_seqs}}){
    if ($_->is_hidden() ne 'yes') {
      my $id = $_->get_id();
      push @members, $id;
    }
  }
  return \@members;
}

sub get_nonhidden_member_nr {
  my $self = shift;
  my $number = 0;
  foreach (@{$self->{align_seqs}}){
    ($_->is_hidden() ne 'yes') and $number++;
  }
  return $number;
}

=head3 get_hidden_member_ids()

Synopsis: $align->get_hidden_member_ids()

Description:  Returns ids of align_seqs members that are hidden

Returns:  an array of ids of all hidden @align_seq members

=cut


sub get_hidden_member_ids {
 my $self = shift;

  my @members = ();
  foreach (@{$self->{align_seqs}}){
    if ($_->is_hidden() eq 'yes') {
      my $id = $_->get_id();
      push @members, $id;
    }
  }
  return \@members;
}

sub get_hidden_member_nr {
 my $self = shift;

  my $number = 0;
  foreach (@{$self->{align_seqs}}){
    ($_->is_hidden() eq 'yes') and $number++;
  }

  return $number;
}

=head3 get_member_species()

Synopsis: $align->get_member_species()

Description:  Return the species of each member of @align_seqs

Returns:  A hash reference whose keys are ids and values are species

=cut

  
sub get_member_species {
  my $self = shift;

  my %member_species = ();
  foreach (@{$self->{align_seqs}}){
    my $id = $_->get_id;
    my $species = $_->get_species();
    $member_species{$id} = $species;
  }
  return \%member_species;
}

sub get_member_urls {
  my $self = shift;

  my %member_url = ();
  foreach (@{$self->{align_seqs}}) {
    my $id = $_->get_id;
    my $url = $_ ->get_url();
    $member_url{$id} = $url;
  }

  return \%member_url;
}

=head2 Image processing subs of the package

render(), render_png(), render_jpg(), render_png_file(), render_jpg_file(), write_image_map()

=cut

=head3 render()

Synopsis: $align->render($o) where $o represnts option, 'c' for complete, 'a' for alignment only and 's' for simple (only the ruler, coverage chart and conserved sequence, no individual members of @align_seqs)

Description: it does the following
 1. Generage, set and render a ruler
 2. Generate, set and render a chart representing coverge
 3. Generate, set and render a align_seq object representing conserved sequence
 4. Render all non-hidden members of the @aign_seqs


Returns: 

=cut

sub render {
  my $self = shift;
  my $option = shift;#'c' for complete, 's' for simple, only chart and conserved seq, 'a' for alignment oly

  #check the option
  ($option eq 'a' || $option eq 'c' || $option eq 's') or die "Please enter correct option! 'a' for alignment only, 'c' for complate and 's' for chart and conserved seq only!\n";

  #adjust the image height according to @align_seqs
  if ($option eq 'c' || $option eq 'a') {
    my $nr_member = $self->get_nonhidden_member_nr;
    
    ($nr_member == 0) and exit "There is no sequence in align!\n";
    ($option eq 'c') and $self->set_height($nr_member * 15 + 200);
    ($option eq 'a') and $self->set_height($nr_member * 15 + 100);
  }
  else {
    $self->set_height(150);
  }
  
  #Generate a image object for the image_object (align_seq, ruler and chart) to render
  $self->{image} = GD::Image->new(
			   $self->{width}, 
			   $self->{height}) 
    or die "Can't generate imag\n";
  
  # the first color located is the background color, white
  $self->{white} = $self->{image}->colorResolve(255,255,255);
  
  $self->{image}->filledRectangle(0,0 ,$self->{width}, $self->{height},  $self->{white});
  
  #add and render a ruler
  $self->_add_ruler(50, $self->{height} - 20);
  
  $self->{ruler}->render($self->{image});
  
  #add and render a chart to indicate percentage coverage
  if ($option eq 'c' || $option eq 's') {
    my $hash_ref = $self->get_ngap_pct();
    $self->_add_cvg_chart(70, "Coverage %", $hash_ref);
    $self->{chart}->render($self->{image});
  }
  

  #add a sequence represnting the conserved region and render it
  if ($option eq 'c' || $option eq 's') {
    $self->_add_conserved_seq_obj(120);
    $self->{conserved_seq}->render($self->{image});
  }

  #adjust vertical offset and height of each non hidden align_seqs member and render the member
  if ($option eq 'c' ||$option eq 'a') {
    my $align_v_offset;
    ($option eq 'c') and $align_v_offset = 170;
    ($option eq 'a') and $align_v_offset = 70;
    foreach my $as (@{$self->{align_seqs}}) {
      if ($as->is_hidden() ne 'yes') {
	$as->set_vertical_offset($align_v_offset);
	$as->set_height(15);
	$as->render($self->{image});
	$align_v_offset += 15;
      }    
    }  
  }
}


=head3 render_png(), render_jpg()

Synopsis: $align->render_jpg(), $align->render_png

Description: Render itself and convert print out png or jpg

Returns:

=cut

sub render_separate_png_files {
	my $self = shift;
	my $background_filepath = shift;

	$self->{display_type} = "separate";
	$self->render();
	
	open(WF, ">", $background_filepath);
	print WF $self->{image}->png();
	close WF;

	my $mfp = $background_filepath;
	$mfp =~ s/\.[^\.]+$//;

	my @member_imgs = ();
	foreach(@{$self->{members}}){
		$_->set_left_margin($self->get_left_margin());	
		$_->set_top_margin($_->get_height()/2);

		my $id = $_->get_id();
		next unless $id;
		
		my $img_path = $mfp . "." . md5_hex($id) . ".png";
		push(@member_imgs, $img_path);
		open(WF, ">$img_path" );
		my $w =   $_->get_width() 
				+ $self->get_label_gap() 
				+ $self->get_right_margin();
				+ $self->get_left_margin();

		my $h = $_->get_height();

		my $image = GD::Image->new($w, $h)
			or die "Can't generate image\n";
		my $white = $image->colorAllocate(255,255,255);
		$image->filledRectangle(0,0,$w,$h,$white);
		$image->transparent($white);

		$_->render($image);
		print WF $image->png();
		close WF;
	}	
	return @member_imgs;
}

sub render_png {
    my $self = shift;
    my $option = shift;

    $self->render($option);
    print $self->{image}->png();
}

sub render_jpg {
    my $self = shift;
    my $option = shift;

    $self->render($option);
    print $self->{image}->jpeg();
}    

=head3 render_png_file(), render_jpg_file()

SYnopsis: $align->render_png_file($file_name, $option), $align->render_jpg_file($file_name, $option)

Description:  take a filename as arguments, render itself and output pgn or jpg image to the file.

Returns:

=cut

sub render_png_file {
    my $self = shift;
    my $filename = shift;
    my $option = shift;

    $self->render($option);
    open (F, ">$filename") || die "Can't open $filename for writing!!! Check write permission in dest directory.";
    print F $self->{image}->png();
    close(F);
}


sub render_jpg_file {
    my $self = shift;
    my $filename = shift;
    my $option = shift;

    $self ->render($option);
    open (F, ">$filename") || die "Can't open $filename for writing!!! Check write permission in dest directory.";
    print F $self->{image}->jpeg();
    close(F);
}



=head3 write_image_map()

Synopsis: $align->write_image_map()

Description: get the image map string of each non-hidden @align_seqs, concat them and return as a single string

Returns:  a string

=cut

sub write_image_map {
    my $self = shift;
    my $map_content;

    $map_content = "<map name=\"align_image_map\" id=\"align_image_map\">\n"; #XHTML 1.0+ requires id; name is for backward compatibility -- Evan, 1/8/07
    foreach (@{$self->{align_seqs}}) {
      ($_->is_hidden() eq 'yes') and next;
      my $string = $_->get_image_string();
      $map_content .= $string . "\n";     
    } 
    $map_content .= "</map>\n";
    return $map_content;
}

=head2 Subroutines to analyze sequences of @align_seq and output result

get_member_similarity(), get_sv_candidates(), get_allele_candidates(), get_overlap_score(), get_all_overlap_score(), get_all_medium(), get_all_range(), get_seqs(), get_nopad_seqs(), get_overlap_seqs(), get_overlap_nums(), get_ngap_pct(), get_all_ngap_length, get_conserved_seq_obj()

=cut

=head3 get_member_similarity()

Sysopsis: $align->get_member_similarity($al_sq) where $al_sq is an object of of algn_seq and member of @align_seqs

Description: To output pair-wise similarities (overlap base, percentage indentity)of the member which is specified as argument between other members of @align_seq.  

Returns: two hash references, one for overlap bases and the other for percentage indentity.  The key of both hashes are the ids of other non hidden members of @align_seqs

=cut

sub get_member_similarity {
  my $self = shift;
  my $al_sq = shift;
  my %member_ol = ();
  my %member_ip = ();

  ($self->is_member($al_sq) != 0) and exit "Not a member!\n";

  foreach (@{$self->{align_seqs}}) {
    ($_ == $al_sq) and next;
    my ($ol, $ip) = $al_sq->calculate_similarity($_);
    my $other_id = $_->get_id();
    $member_ol{$other_id} = $ol;
    $member_ip{$other_id} = $ip;
  }

  return \%member_ol, \%member_ip;
}

=head3 get_sv_candidates()

Synopsis: $align->get_sv_candidates() 
Description:  make pairwise comparison between members of @align_seq of the same species.  If the pair have enough overlap, and the percentage indentity is high enough, and they have enough insertion-deletion (specified as parameter), they are considered as putative splice variant pair  

Returns: 3 hash references
         1. for overlap bases, a 2-D hash, the two keys are the ids of putative pslice variant pair.
         2. for indentity percentage, also 2-D
         3. for species, the key is the species of the putative splice variant pair.

=cut

sub get_sv_candidates {
  my $self = shift;
  
  my ($indel, $overlap);
  ($self->{type} eq 'pep') ? ($indel = '-' x $self->{indel_limit}) : ($indel = '---' x $self->{indel_limit});
  ($self->{type} eq 'pep') ? ($overlap = $self->{sv_overlap}) : ($overlap = $self->{sv_overlap} * 3);

  my %sv_candidate_ob = ();
  my %sv_candidate_pi = ();
  my %sv_candidate_sp = ();

  foreach (my $i = 0; $i < @{$self->{align_seqs}}; $i++){
    foreach (my $j = $i + 1; $j < @{$self->{align_seqs}}; $j++){
      (($self->{align_seqs}[$i]->get_species()) ne ($self->{align_seqs}[$j]->get_species())) and next;
      my ($ol_seq1, $ol_seq2) = $self->{align_seqs}[$i]->get_clean_align_seq($self->{align_seqs}[$j]);

     (!(($ol_seq1 =~ /$indel/) || ($ol_seq2 =~ /$indel/))) and next;
      
      my ($self_id, $other_id) = ($self->{align_seqs}[$i]->get_id(), $self->{align_seqs}[$j]->get_id());
      my ($ob, $pi) = $self->{align_seqs}[$i]->calculate_similarity($self->{align_seqs}[$j]);
      if ( ($ob >= $overlap) && ($pi >= $self->{sv_identity})){
	$sv_candidate_ob{$self_id}{$other_id} = $ob;
	$pi = sprintf("%.2f", $pi);#truncate the number to two digits after the decimal point
	$sv_candidate_pi{$self_id}{$other_id} = $pi;
	$sv_candidate_sp{$self_id} = $self->{align_seqs}[$i]->get_species;
      }
    }
  }
  return \%sv_candidate_ob, \%sv_candidate_pi, \%sv_candidate_sp;
}

=head3 get_allele_candidates()

Synopsis: $align->get_allele_candidates()

Description:  make pairwise comparison between members of @align_seq of the same species.  If the pair have enough overlap, and the percentage indentity is high enough, and they only have short insertion-deletion (specified as parameter), they are considered as putative allele pair  

Returns: 3 hash references
         1. for overlap bases, a 2-D hash, the two keys are the ids of putative alllele pair.
         2. for indentity percentage, also 2-D
         3. for species, the key is the species of the putative allele pair.

=cut

sub get_allele_candidates {
  my $self = shift;
  
  my ($indel, $overlap);
  ($self->{type} eq 'pep') ? ($indel = '-' x $self->{indel_limit}) : ($indel = '---' x $self->{indel_limit});
  ($self->{type} eq 'pep') ? ($overlap = $self->{sv_overlap}) : ($overlap = $self->{sv_overlap} * 3);

  my %al_candidate_ob = ();
  my %al_candidate_pi = ();
  my %al_candidate_sp = ();
  foreach (my $i = 0; $i < @{$self->{align_seqs}}; $i++){
    foreach (my $j = $i + 1; $j < @{$self->{align_seqs}}; $j++){
      (($self->{align_seqs}[$i]->get_species()) ne ($self->{align_seqs}[$j]->get_species())) and next;
      my ($ol_seq1, $ol_seq2) = $self->{align_seqs}[$i]->get_clean_align_seq($self->{align_seqs}[$j]);
      
      (($ol_seq1 =~ /$indel/) || ($ol_seq2 =~ /$indel/)) and next; #skip if the aequence pair have long indel
      
      my ($self_id, $other_id) = ($self->{align_seqs}[$i]->get_id(), $self->{align_seqs}[$j]->get_id());
      my ($ob, $pi) = $self->{align_seqs}[$i]->calculate_similarity($self->{align_seqs}[$j]);
      if ( $ob >= $overlap && ($pi >= $self->{sv_identity})){
	$al_candidate_ob{$self_id}{$other_id} = $ob;
	$pi = sprintf("%.2f", $pi);#truncate the number to two digits after the decimal point
	$al_candidate_pi{$self_id}{$other_id} = $pi;
	$al_candidate_sp{$self_id} = $self->{align_seqs}[$i]->get_species;
      }
    }
  }
  return \%al_candidate_ob, \%al_candidate_pi, \%al_candidate_sp;
}


=head3 get_overlap_score();

Synopsis: $align->get_overlap_score($align) where $align_seq is an object of align

Description:  Calculate the overlap score of a member of @ align_seqs, which is specified as parameter.  At a particular position of the target sequence(s1) has an overlap (not a gap) in another sequence (s2), s1 gets 1 point for alignment score.  The total alignment score of s1 is the sum of all its non-gap positions.

Returns: an integer

=cut

sub get_overlap_score {
  my $self = shift;
  my $al_sq = shift;

  $self->is_member($al_sq) != 0 and exit "$al_sq->{id} is NOT a member!\n";
  $al_sq->{hide} eq 'yes' and exit "$self->{id} is hiden!\n";
  my $score = 0;
  foreach ( my $i = $self->{start_value}-1; $i < $self->{end_value}-1; $i++){
    my $base = substr($al_sq->get_seq(), $i, 1);
    $base eq '-' and next;
    foreach (@{$self->{align_seqs}}) {
      $_ == $al_sq and next;
      $_->{hide} eq 'yes' and next;
      my $other_base = substr ($_->get_seq(), $i, 1);
      if ($other_base ne '-') {
	$score++;
      }
    }
  }
  return $score;
}    

=head3 get_all_overlap_score()

Synopsis: $align->get_all_overlap_score()

Description: score of all the non-hiden members in @align_seq

Returns: a hash reference whose key is the id of a @align_seq member and the value is the overlap score

=cut

sub get_all_overlap_score {
  my $self = shift;
  
  my %member_score = ();
  foreach (@{$self->{align_seqs}}){
    ($_->is_hidden() eq 'yes') and next;
    my $score = $self->get_overlap_score($_);
    my $id = $_->get_id();
    $member_score{$id} = $score;
  }
  return \%member_score;
}


=head3 get_all_medium

Synopsis: $align->get_all_medium()

Description: Output the medium position of each alignment sequence

Returns: a hash reference whose key is the id of a @align_seq member and the value is the medoium

=cut

sub get_all_medium {
  my $self = shift;
 
  my %member_medium = ();
  foreach (@{$self->{align_seqs}}){
    if ($_->is_hidden() ne 'yes') {
      my $medium = $_->get_medium();
      my $id = $_->get_id();
      $member_medium{$id} = $medium;
    }
  }
  return \%member_medium;
}

=head3 get_all_range

Synopsis: $align->get_all_range()

Description: Output the start and end of characters of each @align_seqs member

Returns: two hash references whose keys are the id of a @align_seq member and the value is the start and end position respectively

=cut


sub get_all_range {
  my $self = shift;

  my %member_head = ();
  my %member_end = ();
  foreach (@{$self->{align_seqs}}) {
    if (($_->is_hidden()) ne 'yes'){
      my ($head, $end) = $_->get_range();
      my $id = $_->get_id();
      $member_head{$id} = $head;
      $member_end{$id} = $end;
    }
  }
  return \%member_head, \%member_end;
}


=head3 get_seqs()

Synopsis: $align->get_seqs()

Description: Output the alignment sequences (padded with gaps) of @align_seqs which are are not hidden, in the range specified by start_value and end_value

Returns: a hash reference whose key is the id of @align_seqs members and the value is the alignment sequence

=cut

sub get_seqs {
  my $self = shift;
  (! @{$self->{align_seqs}}) and exit "No align_seqs member.\n";

  my %member_seqs = ();
  foreach (@{$self->{align_seqs}}) {
    if ($_->{hide} eq 'no') {
      my $id = $_->get_id();
      my $seq = $_->get_select_seq();
      $member_seqs{$id} = $seq;
    }
  }
  return \%member_seqs;
}


=head3 get_nopad_seqs()

Synopsis: $align->get_nopad_seqs()

Description: Output the 'original' sequences (with gaps removed) of @align_seqs which are are not hidden, in the range specified by start_value and end_value

Returns: a hash reference whose key is the id of @align_seqs members and the value is the sequence

=cut

sub get_nopad_seqs {
  my $self = shift;
  (! @{$self->{align_seqs}}) and exit "No align_seqs member.\n";

  my %member_seqs = ();
  foreach (@{$self->{align_seqs}}) {
    if ($_->{hide} eq 'no') {
      my $id = $_->get_id();
      my $seq = $_->get_select_seq();
      $seq =~ s/-//g;
      $member_seqs{$id} = $seq;
    }
  }
  return \%member_seqs;
}

=head3 get_overlap_seqs()

Sysnopsis: $align-> get_overlap_seqs() 

Description: for each non hidden member of @align_seqs, get the sequences that overlap with all the other non hiden member of @align_seqs, in the range from start_value to end_value

Returns: a hash reference whose jkey ois the id of @align_seqs member and the value is the overlap sequence

=cut

sub get_overlap_seqs {
  my $self = shift;
  (! @{$self->{align_seqs}}) and exit "No align_seqs member.\n";
  my %overlap_seqs;  
 
  foreach (my $i = $self->{start_value} - 1; $i < $self->{end_value} - 1; $i++){
    my %single_base = ();
    my $pause = 0;
    foreach (@{$self->{align_seqs}}) {
      $_->is_hidden() eq 'yes' and next;
      my $base = substr($_->get_seq(), $i, 1);
      if ($base eq '-') {
	$pause = 1;
	last;
      }
      else {
	$single_base{$_->get_id()} = $base;
      }
    }
    if ($pause == 0) {
      foreach (keys %single_base) {
	if (!defined $overlap_seqs{$_}) {
	  $overlap_seqs{$_} = $single_base{$_};
	}
	else {
	  $overlap_seqs{$_} .= $single_base{$_};
	}
      }
    }
  }
  return \%overlap_seqs;
}

=head3 get_overlap_num()

Synopsis:  $align->get_overlap_num()

Description:  count the number of bases that overlap between all the  non hidden @align_seqs members, in the range from start_value to end)_value

Returns:  an integer

=cut

sub get_overlap_num { 
  my $self = shift;
  my $overlap_count = 0;
  (! @{$self->{align_seqs}}) and exit "No align_seqs member.\n";

  #look for the first non-hiden member in @align_seqs
  my $select;
  foreach (@{$self->{align_seqs}}) {
    ($_->is_hidden() eq 'yes') and next;
    $select = $_;
    last;
  }
    
  foreach (my $i = $self->{start_value} - 1; $i < $self->{end_value} - 1; $i++){
    my $base = substr($select->get_seq(), $i, 1);
    $base eq '-' and next;
    my $pause = 0;
    foreach (@{$self->{align_seqs}}) {
      ($_ == $select) and next;
      ($_->is_hidden() eq 'yes') and next;
      my $other_base = substr($_->get_seq(), $i, 1);
      if ($other_base eq '-') {
	$pause = 1;
	last;
      }
    }
    if ($pause == 0) {
      $overlap_count++;     
    }
  }
  return $overlap_count;
}

=head3 get_ngap_pct()

Synopsis:  $align->get_ngap_pct()

Description:  go from start_value to end_value, get the percentage coverage by @align_seqs.  A position is covered by a member when it has a non gap at the position.

Returns:  a hash reference whose key is the position and values are the percentage coverage

=cut


sub get_ngap_pct { 
  my $self = shift;
  my %value_hash = ();

  (! @{$self->{align_seqs}}) and exit "No align_seqs member.\n";
  
  my $total_nhidden_member = 0;
  foreach (@{$self->{align_seqs}}) {
    ($_->is_hidden() eq 'yes') and next;
    $total_nhidden_member++;
  }
  
  foreach (my $i = $self->{start_value} - 1; $i < $self->{end_value}; $i++){
    my $ngap_count = 0;
    foreach (@{$self->{align_seqs}}) {
      $_->is_hidden() eq 'yes' and next;
      my $seq = $_->get_seq();
      my $base = substr($seq, $i, 1);
      ($base ne '-') and $ngap_count++;
    }
    my $pct = $ngap_count / $total_nhidden_member * 100;
    $value_hash{$i} = sprintf("%.2f", $pct);
  }
  
  return \%value_hash;
}


=head3 get_all_nogap_length()

Synopsis:  $align->get_all_nogap_length()

Description:  go from start_value to end_value, get the sequence length without gap of @align_seqs member..

Returns:  a hash reference whose key is the id and value is the length

=cut



sub get_all_nogap_length {
  my $self = shift;

  my %member_ng_len = ();
  foreach (@{$self->{align_seqs}}) {
    $_->is_hidden() eq 'yes' and next;
    $member_ng_len{$_->get_id()} = $_->get_nogap_length();
  }

  return \%member_ng_len;
}



=head3 get_conserved_seq()

Synopsis:  $align->get_conserved_seq()

Description:  go through each postion from start_value to end_value of non hidden member of @align_seqs.  If all members have the same seq at the position, get the seq, otherwise put a gap (-) in the position.

Returns:  s string of sequence

=cut

sub get_conserved_seq {
  my $self = shift;
  my $seq;

  (! @{$self->{align_seqs}}) and exit "No align_seqs member.\n";
  
  my $total_nhidden_member = 0;
  foreach (@{$self->{align_seqs}}) {
    ($_->is_hidden() eq 'yes') and next;
    $total_nhidden_member++;
  }
  ($total_nhidden_member == 0) and exit "All members are hidden!\n";

  foreach (my $i = $self->{start_value}-1; $i < $self->{end_value}; $i++){
    my %na_count = ();
    my $base_count = 0;
    my $conserved_base = '-';
    foreach (@{$self->{align_seqs}}) {
      $_->is_hidden() eq 'yes' and next;
      my $base = substr($_->get_seq(), $i, 1);
      if ($base ne '-') {
	$base_count++;
	if (!defined $na_count{$base}) {
	  $na_count{$base} = 1;
	}
	else {
	  $na_count{$base}++;
	}
      }
    }
    if ((int keys %na_count == 1) && ($base_count > 1)) {
      foreach (keys %na_count) {
	$conserved_base = $_;
      }
    }
    $seq .= $conserved_base;
  }
  
  $seq = '-' x ($self->{start_value} - 1) . $seq; #fill in the position before start_value
  return $seq;
}



################################End of Package align#####################################






###############################Package image_object#######################################

=head1 Package CXGN::Alignment::image_object

The base class for align_seq and ruler.

Its attributes include: horizontal_offset, vertical_offset, length (pixel), height (pixel), horizontal_offset,  vertical_offset, color, label_corlor

=cut

package CXGN::Alignment::image_object; 

=head2 Constructer new()

Synopsis:     my $img_obj = Alignment::image_object->new(
                                                         horizontal_offset=>$x, 
                                                         vertical_offset=>$y, 
                                                         length=>$z,
                                                         height=>$h,
                                                         start_value=>$start_value, 
                                                         end_value=>$end_value
                                                         );

Returns:      a Alignment::image_object object

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless {}, $class;
    
    $self->{horizontal_offset} = $args{horizontal_offset};
    $self->{vertical_offset} = $args{vertical_offset};
    $self->{length} = $args{length};
    $self->{height} = $args{height};
    $self->{start_value} = $args{start_value};
    $self->{end_value} = $args{end_value};

    return $self;
}


=head2 Setters and getters

set_horizontal_offset(), set_vertical_offset, set_color(), set_label_color(), set_length(), set_start_value

get_horizontal_offset(), get_vertical_offset(), get_label_color(), set_label_color(), get_length(), get_start_value()

=cut

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

sub get_horizontal_offset { 
    my $self = shift;
    if (!exists($self->{horizontal_offset})) { $self->{horizontal_offset} = 0; }
    return $self->{horizontal_offset};
}

sub set_horizontal_offset { 
    my $self = shift;
    $self->{horizontal_offset} = shift;
}

sub get_vertical_offset { 
    my $self = shift;
    return $self->{vertical_offset};
}

sub set_vertical_offset { 
    my $self = shift;
    $self->{vertical_offset} = shift;
}

sub get_length { 
    my $self = shift;
    if (!exists($self->{length})) { $self->{length} = 0; }
    return $self->{length};
}


sub set_length { 
  my $self = shift;
  $self->{length} = shift;
}

sub get_height {
  my $self = shift;
  return $self->{height};
}

sub set_height {
  my $self = shift;
  $self->{height} = shift;
}


=head2 Subs for image display

set_enclosing_rect(), get_enclosing_rect, render(), get_image_string()

=cut

 
sub set_enclosing_rect {
    my $self = shift;
    ($self->get_horizontal_offset(), $self->get_vertical_offset(), $self->{width}, $self->{height}) = @_;
}

sub get_enclosing_rect {
    my $self = shift;
    return ($self->get_horizontal_offset(), $self->get_vertical_offset(), $self->get_horizontal_offset() + $self->get_length() + 150, $self->get_vertical_offset() + $self->get_height);#to include the label space, $x plus 150
}
  
sub render {
    my $self = shift;
    # does nothing
}

sub get_image_string {
    my $self = shift;

    my $coords = join ",", ($self->get_enclosing_rect());
    my $string;
    if ($self->get_url()) {  
      $string =  "<area shape=\"rect\" coords=\"".$coords."\" href=\"".$self->get_url()."\" alt=\"".$self->get_id()."\" />";
    }
    return $string;
}


=head3 _calculate scaling_factor()

Synopsis:  $self->_calculate_scaling_factor()

Description: calculate the scaling factor, set the scaling_factor attribute and return the scaling factor. private, called by render

Returns:  a number, scaling factor.

=cut

sub _calculate_scaling_factor {
    my $self = shift;
    my $dist = ($self->{end_value} - $self->{start_value}) + 1;
    if ($dist ==0) { return 0; }
    $self->{scaling_factor} = $self->{length}/$dist;
    return $self->{scaling_factor};
}



##############################End of Package image_object###################################






##############################Package align_seq#############################################

=head1 Package Alignment::align_seq

Inherit from image_object.  Its special attributes include id, seq, species, seq_line_width, label_spacer, hide and url

=cut

package CXGN::Alignment::align_seq;
use base qw( CXGN::Alignment::image_object );

=head2 COnstructer new()

Synopsis:     my $al_sq = Alignment::align_seq->new(
						    horizontal_offset=>$x, 
						    vertical_offset=>$y, 
						    length=>$z,
						    height=>$h,
						    start_value=>$start_value, 
						    end_value=>$end_value
						    id=>$id,
						    seq=>seq,
						    species=>$species
						   );

Returns:      a CXGN::Alignment::align_seq object

=cut

sub new {
  my $class = shift;
  my %args = @_;
  my $self = $class->SUPER::new(@_);

  $self->{id} = $args{id};
  $self->{seq} = $args{seq};
  $self->{species} = $args{species};

  #set defaults
  $self->{font} = GD::Font->Small();
  $self->set_color (0, 0, 255);
  $self->set_label_color(0, 0, 0);
  $self->set_seq_line_width(8);
  $self->{label_spacer} = 20;
  $self->{hide} = 'no';

  #define an empty attributes
  $self->{url} = ();

  return $self;
}

=head2 Setters and getters

set_seq_line_width(), get_seq_lien_width(), set_label_spacer(), get_label_spacer(), is_hide(), hide_seq(), unhide_seq(), set_url(), get_url(), set_id(), get_id(), set_species(), get_species(), set_seq(), get_seq(), get_select_seq()

=cut

sub set_label_spacer{
  my $self = shift;
  $self ->{label_spacer} = shift;
}

sub get_label_spacer{
  my $self = shift;
  if (!exists $self->{label_spacer}){
    $self->{label_spacer} = 0;
  }
  return $self->{label_spacer};
}

sub set_seq_line_width{
  my $self = shift;
  $self->{seq_line_width} = shift;
}
sub get_seq_line_width{
  my $self = shift;
  if (!exists $self->{seq_line_width}){
    $self->{seq_line_width} = 1;
  }
  return $self->{seq_line_width};
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
  $seq = substr($seq, $self->{start_value} - 1, $self->{end_value} - $self->{start_value} + 1);
  return $seq;
}


=head3 is_hidden()

Synopsis: align_seq->is_hidden();

Description:  check if itself is hidden

Returns: 'yes' if the sequence is hidden and 'n' if not.  It is set to 'no' by default when the object is constructed.

=cut
 
sub is_hidden {
  my $self = shift;
  return $self->{hide};
}


sub set_url {
    my $self = shift;
    $self->{url} = shift;
}

sub get_url {
    my $self = shift;
    return $self->{url};
}

sub hide_seq {
  my $self = shift;
  $self->{hide} = 'yes';
}

sub unhide_seq {
  my $self = shift;
  $self->{hide} = 'no';
}


=head2 Image display subs

render()

=cut

=head3 render()

Synopsis: align_seq->render($image) where $iamge is an image object

Description: render the align_seq object

Returns: 

=cut

sub render {
  my $self = shift;
  my $image = shift;  
  my $color = $image->colorResolve($self->{color}[0], $self->{color}[1], $self->{color}[2]);
  my $label_color = $image->colorResolve($self->{label_color}[0], $self->{label_color}[1], $self->{label_color}[2]);
  my $align_seq = substr ($self->{seq}, $self->{start_value}-1, $self->{end_value}-$self->{start_value}+1);
  my $seq_id = $self->{id};
  $self->_calculate_scaling_factor();
  my $i;
  for ($i = 0; $i < length ($align_seq); $i++){

    #draw sequence, a line if the base is a gap and a rectangle otherwise
    my $base = substr($align_seq, $i, 1);
    my $width;
    if ($base eq '-'){
      $image->line($i*$self->{scaling_factor}+$self->{horizontal_offset}, $self->{vertical_offset}, ($i+1)*$self->{scaling_factor}+$self->{horizontal_offset}, $self->{vertical_offset}, $color);
    }
    else {
      $image->filledRectangle($i*$self->{scaling_factor}+$self->{horizontal_offset}, $self->{vertical_offset}-$self->{seq_line_width}/2, ($i+1)*$self->{scaling_factor}+$self->{horizontal_offset}, $self->{vertical_offset}+ $self->{seq_line_width}/2, $color);
    }
  }

  #add sequence name, first chop the sequence name to up to 30 characters. add '..' if the name is longer
  my $show_id;
  my $full_id = $self->{id} . ' ' . $self->{species};
  if ((length $full_id) >= 30) {
     $show_id = substr ($full_id, 0, 30);
     $show_id .= '..';
   }
  else {
    $show_id = $full_id;
  }
  
  $image->string($self->{font}, $i*$self->{scaling_factor}+ $self->{horizontal_offset} + $self->{label_spacer}, $self->{vertical_offset} - $self->{seq_line_width} / 2, $show_id, $label_color);
}


=head2 Sequence analyzing subs

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

Synopsis: $align_seq->calculate_similarity($other_align_seq) where $other_align_seq is another align_seq object

Description: get the overlap base number and idnetical percentage of the seq of two align_seq objects.

Returns:  an integer (number of overlap base) and a float (percentage indentity)

=cut

sub calculate_similarity {
  my $self = shift;
  my $other_seq = shift;
  ($self->get_length() != $other_seq->get_length()) and exit "$self->{id} and $other_seq->{id} sequences are not of the same length, align them first!\n";
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

=head3 $align_seq->get_clean_align_seq()

Synopsis: $align_seq->get_clean_align_seq($align_seq2) where $align_seq2 is another align_seq object

Description:  goes through the two alignment sequences, in the conmmon range, and leave out common gaps.  

Returns: two 'clean' overlap sequences, with common gaps removed.

=cut

sub get_clean_align_seq {
  my $self = shift;
  my $other_seq = shift;

  ($self->get_length() != $other_seq->get_length()) and exit "$self->{id} and $other_seq->{id} sequences are not of the same length, align them first!\n";
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

Synopsis: $align_seq->get_medium() 

Description: calculate the middle point of non-gap bases of the align_seq

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

Synopsis: $align_seq->get_range()

Description:  get the postion of the first non gap character and the last non gap character, from start_value to end_value.

Returns: two intgers representing two positions.

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


###################################End of Package align_seq####################################






##################################Package ruler###############################################

=head1 Package Alignment::ruler

This class is inherited from image_object.  Its special attributes include label_side, unit, label_spacing and tick_spacing.  The ruler is horizontal only.

=cut

package CXGN::Alignment::ruler;

use base qw( CXGN::Alignment::image_object);
=head2 Constructor new()

  Synopsis:     my $ruler = Alignment::ruler->new(
						  horizontal_offset=>$x, 
						  vertical_offset=>$y, 
						  length=>$z,
						  height=>$h,
						  start_value=>$a, 
						  end_value=>$b
						 );
  Returns:      a Alignment::ruler object

=cut

sub new {
    my $class = shift;
    my %args = @_;
    my $self = $class->SUPER::new(@_);

    #set defaults
    $self->{font} = GD::Font->Small();
    $self->set_color (127, 127, 127);
    $self->set_label_color (0,0, 0);
    $self->{label_side} = "up";
    $self->{unit} = "bp";
    $self->{label_spacing} = 50;
    $self->{tick_spacing} = 50;

    return $self;
}

=head2 Setters and getters

set_labels_up(), set_labels_down(), set_unit("my_unit"), get_unit(), set_label_spacing, get_label_spacing, set_tick_spacing, get_tick_spacing

=cut

sub set_labels_up {
    my $self = shift;
    $self->{label_side} = "up";
}

sub set_labels_down {
    my $self = shift;
    $self ->{label_side} = "down";
}

sub set_unit {
    my $self = shift;
    $self->{unit} = shift;
}

sub get_unit { 
    my $self = shift;
    return $self->{unit};
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

=head2 Image display sub render()

Synopsis: $ruler->render($img) where $img is a image object

Description: draws ruler line, ticks (goes to near the bottom of the image), label and unit, 

=cut

sub render {
    my $self = shift;
    my $image = shift;

    my $color = $image->colorResolve($self->{color}[0], $self->{color}[1], $self->{color}[2]);

    #####################Draw ruler line
    $image->line($self->{horizontal_offset}, $self->{vertical_offset}, $self->{horizontal_offset} + $self->{length}, $self->{vertical_offset}, $color);
    
    #####################Draw ticks and  tick labels
    #Reset tick and spacing, depending on the length
    $self->{tick_spacing} = ((int (($self->{end_value} - $self->{start_value} + 1) / 1000))+ 1) * 100;
    #$self->{label_spacing} = ($self->{tick_spacing}) * 2;

    #####################Determine the scaling factor.  Increment label spaing  by 10 until the longest label (maxim value) is shorter than label spacing 
    $self->_calculate_scaling_factor();
    if ($self->{scaling_factor})  { 
	#otherwise this is an infinite loop....
	while (($self->{label_spacing} * $self->{scaling_factor}) < ($self->{font}->width() * length ($self->{end_value})+2)) { $self->{label_spacing} +=50; }
    }
   
    my $tick_number = int($self->{end_value}-$self->{start_value})/$self->{tick_spacing} + 1;    
    for (my $i = 0; $i < $tick_number - 1; $i++) {
      my $x = $self->{horizontal_offset} + (($i*$self->{tick_spacing})*$self->{scaling_factor});
      $image->dashedLine($x, $self->{vertical_offset}-2, $x, $self->{height}, $color); #draw the tick
      if ( $i*$self->{tick_spacing} % $self->{label_spacing} == 0){#Draw tick label
	my $tick_label = $i*$self->{tick_spacing} + $self->{start_value} - 1;
	my $horizontal_adjust = $self->{font}->width * length ($tick_label)/2;
	my $tick_label_x = $x - $horizontal_adjust;
	my $tick_label_y;
	if ($self->{label_side} eq 'down'){
	  $tick_label_y = $self->{vertical_offset} + 1;
	}
	else {
	  $tick_label_y = $self->{vertical_offset} - 1 - $self->{font}->height;
	}
	$image->string($self->{font}, $tick_label_x, $tick_label_y, $tick_label, $color);
      }
    }
    
    #Write unit
    my $unit_label = "[".$self->{unit}."]";
    my $unit_label_x = $self->{horizontal_offset} + ($self->{length}- $self->{font}->width() * length($unit_label))/2;
    my $unit_label_y;
    if ($self->{label_side} eq 'down'){
      $unit_label_y = $self->{horizontal_offset} + 1 + $self->{font}->height;
    }
    else {
      $unit_label_y = $self->{horizontal_offset} - 1 - $self->{font}->height*2;
    }
    $image->string($self->{font}, $unit_label_x, $unit_label_y, $unit_label, $color);    
}


###################################End of Package ruler#####################################






##################################Package chart#############################################
=head1 Package CXGN::Alignment::chart

Inherit from image_object.  Its special attributes include id and hash_ref.  The keys of the hash is position and the vaule is a percentage.

=cut

package CXGN::Alignment::chart;

use base qw( CXGN::Alignment::image_object);

=head2 Constructer new()

  Synopsis:     my $chart= Alignment::chart->new(
                                                 horizontal_offset=>$x, 
						 vertical_offset=>$y, 
						 length=>$z,
						 height=>$h,
						 start_value=>$start_value, 
						 end_value=>$end_value
                                                 id=>id,
                                                 hash_ref=>$ref
                                                 );
  Returns:      a Alignment::chart object

=cut

sub new {
  my $class = shift;
  my %args = @_;
  my $self = $class->SUPER::new(@_);
  
  $self->{id} = $args{id};
  $self->{hash_ref} = $args{hash_ref};
  
  #set defaults
  $self->{font} = GD::Font->Small();
  $self->set_color (0, 0, 122);
  $self->set_label_color(0, 0, 0);
  $self->{label_spacer} = 20;
  $self->{hide} = 'no';
  return $self;
}

=head2 Setters and getters

set_id(), get_id(), set_hash_ref(), get_hash_ref()

Nothing special

=cut

sub set_id {
  my $self = shift;
  $self->{id} = shift;
}

sub get_id {
  my $self = shift;
  return $self->{id};
}

sub set_hash_ref {
  my $self = shift;
  $self->{hash_ref} = shift;
}

sub get_hash_ref {
  my $self = shift;
  return $self->{hash_ref};
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
  
  my $ref = $self->{hash_ref};
  my %chart_hash = %$ref;

  my $color = $image->colorResolve($self->{color}[0], $self->{color}[1], $self->{color}[2]);
  my $label_color = $image->colorResolve($self->{label_color}[0], $self->{label_color}[1], $self->{label_color}[2]);
  
  my $seq_id = $self->{id};
  $self->_calculate_scaling_factor();

  $image->line($self->{horizontal_offset}, $self->{vertical_offset}, $self->{horizontal_offset} + $self->{length}, $self->{vertical_offset}, $color); #Draw the 0% line
  $image->line($self->{horizontal_offset}, $self->{vertical_offset} + 33.3, $self->{horizontal_offset} + $self->{length}, $self->{vertical_offset}+ 33.3, $color); #Draw the 100% line
      
  my ($i, $adjust_i);
  for ($i = $self->{start_value} - 1; $i < $self->{end_value}; $i++){

    (!defined $chart_hash{$i}) and ($chart_hash{$i} = 0);
    $adjust_i = $i - $self->{start_value} + 1; #adjust horizontal offset according to start_value

    $image->filledRectangle($adjust_i*$self->{scaling_factor}+$self->{horizontal_offset}, $self->{vertical_offset},  ($adjust_i+1)*$self->{scaling_factor}+$self->{horizontal_offset}, $self->{vertical_offset}+$chart_hash{$i}/3, $color);
    
  }

  #add sequence name, first chop the sequence name to up to 30 characters. add '..' if the name is longer
  my $show_id; ;
  if ((length ($self->{id})) >= 30) {
     $show_id = substr ($self->{id}, 0, 30);
     $show_id .= '..';
   }
  else {
    $show_id = $self->{id};
  }
  
  $image->string($self->{font}, ($adjust_i + 1) *$self->{scaling_factor}+ $self->{horizontal_offset} + $self->{label_spacer}, $self->{vertical_offset} - $self->{seq_line_width} / 2, $show_id, $label_color);
}

################################End of Package chart###########################################
