package CXGN::Phylo::Alignment;

use strict;
use GD;
use File::Temp;
use Carp;
use Cwd;
use Digest::MD5 qw/md5_hex/;
use CXGN::Phylo::Alignment::Ruler;
use CXGN::Phylo::Alignment::Chart;
use CXGN::Phylo::Alignment::Member;
use CXGN::Phylo::Alignment::Legend;
use CXGN::Tools::Identifiers qw/identifier_url identifier_namespace/;
use CXGN::Tools::Param qw/ hash2param /;
use CXGN::Tools::Parse::Fasta;
use CXGN::Tools::Gene;
use CXGN::DB::Connection;

=head1 CXGN::Phylo::Alignment

Alignment -- packages for analyzing, optimizing and displaying sequence alignments

=head1 Author

Chenwei Lin (cl295@cornell.edu)
Refactoring and lingual adjustments provided by Chris Carpita <csc32@cornell.edu>

=head1 Packages

 CXGN::Phylo::Alignment
 CXGN::Phylo::Alignment::ImageObject
 CXGN::Phylo::Alignment::Member 
 CXGN::Phylo::Alignment::Ruler
 CXGN::Phylo::Alignment::Chart
 
 Packages Member, Ruler and Chart inherit from ImageObject

=head1 Package CXGN::Phylo::Alignment
 
 The basic element of the alignment object is an array of member.
 Its attributes include: name, width (pixel), height(pixel), 
 image, members, ruler, chart, conserved_seq, sv_overlap, sv_identtity, 
 start_value and end_value 
 
 Its functionality includes:
 1. Image display. 
 2. Calculation and output of pairwise similaity and putative splice variant pairs based on similarity. 
 3. Hide some alignment sequences so that they are not included in the analysis.
 4. Select a range of sequences to be analyzed.
 5. Asses how a set of members overlaps with another set.  
 6. Calculate the non-gap mid point of each alignment sequence and group the sequences according to their overlap.

=head2 Constructer new()

Create a new alignment, returns an alignment object

=head3

 Synopsis:  my $alignment = CXGN::Phylo::Alignment->new(
                                                   name=>$name,
                                                   width=>$width, 
                                                   height=>$height, 
                                                   type=>$type, #'nt' or 'pep'
                                                   );

 Description:  Upon constructing an alignment object, it sets name, 
 width and height using arguments.  It also generates an image object of 
 {width} and {height} and sets the default value of sv_overlap, 
 sv_identity (the minimum number overlapping aa and percentage 
 identity for two members to be considered as putative splice variants), 
 sv_indel_limit (the min aa indel length for two sequences to be considered 
 as splice variants, instead of alleles) and start_value (the start value 
 of the ruler and member objects(s))

 Returns: A CXGN::Phylo::Alignment object

=cut

sub new { 
    my $class = shift;
    my %args = @_;
   	if(ref($_[0]) eq "HASH"){ #forward compatibility
		%args = %{$_[0]};
	} 

	my $self = bless {}, $class;
    ##################set attibutes from parameter
    $self->{name} = $args{name};

	## Default constraints for all member ImageObjects, unless their display 
	## properties are set explicitly.  If you don't use set_image, this will 
	## determine the height and width of the created image
    $self->{width} = $args{width} || 600;
    $self->{height} = $args{height} || 400;
    $self->{left_margin} = 30;
    $self->{top_margin} = 30;
	$self->{right_margin} = 10;

	$self->{type} = $args{type}; # 'pep' or 'nt' or 'cds'
	
	$self->{display_type} = "complete"; 
	#also: "alignment" (only), "stats" (chart and conserved sequence only).  
	#You can use 'c','a', and 's' as shorthand.

    ##################set defaults
    #splice variants criteria
    $self->{sv_overlap} = 20; #default in case we are using peptides 
    $self->{indel_limit} = 4; #(ditto)
    $self->{sv_identity} = 95;
    $self->{start_value} = 1;  #the end_value is initiated when the first member is added
	$self->{end_value} = 1;

    ## define some 'empty' attributes that will be asigned later
    @{$self->{members}} = ();
    $self->{ruler} = undef;
    $self->{chart} = undef
    $self->{image} = undef;
    $self->{conserved_seq} = undef;    
    $self->{seq_length} = 0;

	#generally don't need to set this, since it can be inferred based on content
	$self->{unaligned} = 0; 
	$self->{muscle} = {}; #muscle parameters for running alignment
	$self->{from_file} = undef;	

	foreach(qw/ from_file unaligned from_ids muscle tmp_dir /) {
		$self->{$_} = $args{$_} if exists($args{$_});
	}

	if(defined $self->{from_file}  and  -f $self->{from_file}){
		$self->from_file();
	}
	elsif($self->{from_file}) {
		warn "Alignment file not found: " . $self->{from_file} . "\n";
	}
	
	if(ref($self->{from_ids}) eq "ARRAY"){
  		my @ids = @{$self->{from_ids}};
		foreach my $id (@ids){
			my $seq = "";
			my $g = undef;
			eval{
				$g = CXGN::Tools::Gene->new($id);
				$g->fetch("seq");
				$seq = $g->get_sequence('protein');
			};
			if($seq){
				my $m = CXGN::Phylo::Alignment::Member->new({
					id=>$id,
					seq=>$seq
				});
				$self->add_member($m);
			}
		}
		$self->run_muscle();
	}

    return $self;
}

# get the cols with <= $max_gaps gaps in them (non-hidden sequences only), make new alignment object
# with just these columns of the non-hidden sequences only.

sub remove_gappy_cols{ 
	my $self = shift;
	my $mxgps = shift;
	$mxgps = 0 unless($mxgps);		#default is 0
	my $oseqs = $self->get_overlap_seqs($mxgps); # ref to hash with id/seq pairs. These are seqs with only the ungappy columns
	my $cols_left;
	if ((scalar keys %$oseqs)) {
		$cols_left =  length $oseqs->{(keys %$oseqs)[0]};
	#	print STDERR  "After winnowing cols with max_gaps = $mxgps.  Cols remaining: ", $cols_left, "\n";
	} else {
		$cols_left = 0;
	}
	return undef if($cols_left == 0); # in case of empty sequences
	my $alignment = CXGN::Phylo::Alignment->new();
	foreach my $id (keys %$oseqs) {
		my $seq = $oseqs->{$id};
		my $member = CXGN::Phylo::Alignment::Member->new( id => $id, seq => $seq );
		$alignment->add_member($member); 
	}
	return $alignment;
}


=head2 Setters and getters

	get_name(), set_name()

	get_image(), set_image()

	get_width(), set_width()

get_height(), set_height()

get_seq_length()

get_sv_criteria(), set_sv_criteria()

get_start_value(), set_start_value(), check_start_value()

get_end_value(), set_end_value(), check_end_value()

get_left_margin(), set_left_margin(), get_top_margin(), set_top_margin()

Those for name, image, sv_overlap and sv_identity, height, width, 
left_margin, top_margin are straightforward, while the 
setters for start_value, end_value are not simple, since these attributes 
are related to and/or restricted by other attributes.  seq_length is 
determined by the first member added and therefore can not be reset.

=cut

sub get_name {
  my $self= shift; 
  return $self->{name};
}

sub set_name {
  my $self = shift;
  my $name = shift;
  $self->{name} = $name;
}

sub get_image {
  my $self = shift;
  return $self->{image};
}

sub set_image {
  my $self = shift;
  $self->{image} = shift;
}
 
sub get_width {
  my $self = shift;
  return $self->{width};
}

sub get_height {
  my $self = shift;
  return $self->{height};
}

sub set_tmp_dir {
	my $self = shift;
	my $dir = shift;
	if(-d $dir){
		$self->{tmp_dir} = $dir;
	}
	elsif($dir){
		die "Directory does not exist: $dir\n";
	}
	else {
		my $vhost = SGN::Context->new();
		$self->{tmp_dir} = $vhost->get_conf('basepath') . $vhost->get_conf('tempfiles_subdir') . '/align_viewer';
		unless(-d $self->{tmp_dir}){
			warn "Temporary directory does not exist: " . $self->{tmp_dir} . "; setting to current directory";
			$self->{tmp_dir} = ".";
		}
	}
	return $self->{tmp_dir};
}

sub get_tmp_dir {
	my $self = shift;
	if(!$self->{tmp_dir}){
		$self->set_tmp_dir();
	}
	return $self->{tmp_dir};
}

=head3 set_width(), set_height()

Synopsis: set_width($x), set_height($x)

Description:  sets the attributes {width} and {height}.  

=cut

sub set_width {
  my $self = shift;
  $self->{width} = shift;
}

sub set_height {
  my $self = shift;
  $self->{height} = shift;
}

=head3 set_sv_criteria()

Synopsis:  $alignment->set_sv_criteria($x, $y, $z), while $x is 
the minimum overlap, $y is a percentage similarity and $z is the minimal 
amino acid indel length to be considered as a splice variant

Description:  Set the putative splice variants standard, the minimum 
overlapping bases and percentage identity (sv_overlap and sv_identity).  
The sub checks if the values are correct before setting the attributes

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
  return ($self->{sv_overlap}, $self->{sv_identity}, $self->{indel_limit});
}

sub set_left_margin {
  my $self = shift;
  $self->{left_margin} = shift;
}

sub get_left_margin {
  my $self = shift;
  return $self->{left_margin};
}

sub set_top_margin {
  my $self = shift;
  $self->{top_margin} = shift;
}

sub get_top_margin {
  my $self = shift;
  return $self->{top_margin};
}

sub get_right_margin {
	my $self = shift;
	return $self->{right_margin};
}

sub set_right_margin {
	my $self = shift;
	$self->{right_margin} = shift;
}

sub get_label_gap {
	my $self = shift;
	return $self->{label_gap};
}

sub set_label_gap {
	my $self = shift;
	$self->{label_gap} = shift;
}

sub _calculate_label_gap {
	my $self = shift;
	my $maxwidth = 0;
	foreach my $m (@{$self->{members}}) {
		my $ls = $m->get_label_spacer();
		$ls ||= 0;
		my $labelwidth = $m->{font}->width() * length($m->get_id()) + $ls;
		$maxwidth = $labelwidth if($labelwidth > $maxwidth);	
	}
 	if($self->{chart}){
 		my $labelwidth = $self->{chart}->get_longest_label_width();
 		$maxwidth = $labelwidth if($labelwidth > $maxwidth);
 	}
	$self->{label_gap} = $maxwidth;
	return $maxwidth;
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
  if ($value > length $self->{members}[0]->{seq}){
    $value = length $self->{members}[0];
    print "value greater than sequence length, reset to sequence length\n";
  }
  return $value;
}
# 
sub get_seq_length {
  my $self = shift;
  return $self->{seq_length};
}

=head3 set_start_value(), set_end_value()

Synopsis:  set_start_value($x), set_end_value($x)

Description: set the start_value and end_value.  Check if the input value is correct before setting the attributes.  Since the {start_value} and {end_value} attributes of the {ruler} and {members} must be the same as those of the alignment object, the set subs call the set_start_value and set_end_value of the {ruler} and all members of {members} 

Returns:

=cut

sub set_start_value {
  my $self = shift;
  my $value = shift;
  $value = $self->check_start_value($value);#check if the start value is correct
  $self->{start_value} = $value; #the ruler will use this start_value 

  foreach (@{$self->{members}}) { #set the start_value of each included member
    $_->set_start_value($value);
  }
}

sub set_end_value {
  my $self = shift;
  my $value = shift;
  #$value = $self->check_end_value($value);#check if the end value is correct
  $self->{end_value} = $value; 
  
  foreach (@{$self->{members}}) { #set the start_value of each included member
    $_->set_end_value($value);
  }
}

sub get_type {
	my $self = shift;
	return $self->{type};
}

sub set_type {
	my $self = shift;
	$self->{type} = shift; #'nt' or 'pep'
}

sub set_display_type {
	my $self = shift;
	my $display_type = shift;
	die "Please set display type to c(omplete), a(lignment), or s(tats)" 
		unless $display_type =~ /^(a|c|s)/i;
	$self->{display_type} = $display_type;
}

sub get_display_type {
	my $self = shift;
	return $self->{display_type};
}

sub show_label {
	my $self = shift;
	$self->{label_shown} = 1;
}

sub hide_label {
	my $self = shift;
	$self->{label_shown} = 0;
}

sub get_combined_member_height {
	my $self = shift;
	my $total_height = 0;
	foreach my $m (@{$self->{members}}){
		next if $m->is_hidden;
		$total_height += $m->get_height;
	}
	return $total_height;
}

sub set_fasta_temp_file {
	my $self = shift;
	$self->{fasta_temp_file} = shift;
}

sub get_fasta_temp_file {	
	my $self = shift;
	return $self->{fasta_temp_file};
}

sub set_cds_temp_file {
	my $self = shift;
	$self->{cds_temp_file} = shift;
}

sub get_cds_temp_file {
	my $self = shift;
	return $self->{cds_temp_file};
}


=head1 Subroutines to add ImageObjects to Alignment object

add_member(), _add_ruler(), _add_cvg_chart, _add_conserved_seq_obj()

=cut

sub from_file {
	my $self = shift;
	my $from_file = shift;
	$from_file ||= $self->{from_file};
	my $parser = CXGN::Tools::Parse::Fasta->new($from_file);
	my $count = 0;
	my $debug = "";
	while (my $entry = $parser->next()) {
		my ($id, $seq, $species) = ($entry->{id}, $entry->{seq}, $entry->{species});
		chomp $seq;
		my $len = length($seq);
		my $member = undef;
		eval {
			$member = CXGN::Phylo::Alignment::Member->new(
																										id => $id,
																										seq => $seq,
																										species => $species,
																										type => $self->{type}
																									 );
			my $r = $self->add_member($member);
			$count++;
		};
		warn $@ if ($@);
	}
}

=head3 add_member()

 Synopsis:  $alignment->add_member($member),  while member is an member object

 Description: Add member to alignment object.  The member objects are
 stored in an array members.  Once the first member object is added,
 only member objects of the same length can be further added.  At the
 same time, the end_value is set to be the same as the sequence length
 of the first member added.

=cut

sub add_member {
    my $self = shift;
    my $member = shift;
    ref $member && $member->isa(__PACKAGE__.'::Member') or croak "invalid member '$member'";

    if (!defined @{$self->{members}}) {
        #if there are no members in @members, reset the end_value of overall 
        #alignment to the length of this sequence
        $self->set_end_value($member->get_end_value());
        $self->{seq_length} = length ($member->get_select_seq());
        #adjust the vertical and horizontal offsets and length
        #add the member to @members
        push @{$self->{members}}, $member;
    } else {
        my $len = length($member->get_seq()); 
        #the length of the member must the the same as the first member in
        #@members, otherwise it won't be added
        if ( $len == $self->{seq_length}) { 
			
            # Set the start_value and end_value of the member to the current 
            # values of the overall alignment 
            $member->set_start_value($self->get_start_value());
            $member->set_end_value($self->get_end_value());

            push @{$self->{members}}, $member;
        } elsif (!$self->{unaligned}) {
            my $id = $member->get_id();
            my $seq = $member->get_select_seq();
            unless($seq=~/-/){
                warn "Sequence w/ id $id does not have same length, assuming unaligned sequences are provided";
                $self->{unaligned} = 1;
				#don't need to set start/end values, since those are meaningless in the unaligned context
				#we are assuming that muscle will be run via $self->run_muscle();
                push(@{$self->{members}}, $member);
            } else {
				#if we thought we were well-aligned, then we're dead wrong
                die "Error in adding pre-aligned sequence $id, length ($len) not the same as overall alignment (" . $self->{seq_length} . ")\n";
            }
        } else {
            #We know the family is yet-to-be aligned
            push(@{$self->{members}}, $member);
        }
    }
}

sub get_nongaps_hash{           # this returns a ref to a hash with ids as keys, numbers of nongaps as values
    my $self = shift;
    my %nongaps;
    foreach ( @{$self->{members}}) {
        next if($_->is_hidden());
        $nongaps{$_->get_id()} = $_->get_nongaps(); # this get_nongaps is a method of Member, returns # of nongaps
    }
    return \%nongaps;
}

sub get_gaps_nongaps{								# this returns just the total number of nongap characters in the alignment's non-hidden members.
	my $self = shift;
	my $nongaps = 0;
	foreach ( @{$self->{members}}) {
		next if($_->is_hidden());
		$nongaps += $_->get_nongaps(); # this get_nongaps is a method of Member, returns # of nongaps
	}
#	print "in get_gaps_nongaps: ", $self->get_seq_length()*$self->get_visible_member_nr() - $nongaps,  "   ",  $nongaps, "\n";
	return ($self->get_seq_length()*$self->get_visible_member_nr() - $nongaps,  $nongaps)
}

#sub get_gaps{										# get total gap characters in non-hidden members
#	my $self = shift;
#	my $n_cols = $self->get_seq_length();
#	my $n_seq = $self->get_visible_member_nr();
#	return $n_cols*$n_seq - $self->get_nongaps();
#}

=head3 hide_gappy_members

Hide members (sequences) if they have fewer than the specified number of non-gap characters
Arg: Minimum number of non-gap characters in sequence for it to be kept.
Ret: Number of members hidden by this pass through subroutine, others may have been already hidden.

=cut

sub  hide_gappy_members{
	my $self = shift;
	my $min_nongaps = shift;
	my $n_hide = 0;								# counts the number of sequences hidden by this call 
	foreach ( @{$self->{members}}) {
		next if($_->is_hidden());		#
	#	my ($gaps, $nongaps) = $_->get_nongaps();
		if ($_->get_nongaps() < $min_nongaps) {
			$_->hide_seq();
			$n_hide++;
			#		print "hiding id: ", $_->get_id(), ".  nongaps:   ", $_->get_nongaps(), "\n";
		}
	}
	return $n_hide;
}


=head3 get_members 

 Get the member objects of the alignment
 Arg: none
 Ret: List of members

=cut

sub get_members {
	my $self = shift;
	return @{$self->{members}};
}



sub add_legend_item {
	my $self = shift;
	my ($name, $color, $url, $tooltip) = @_;
	#color is array ref
	$self->_add_legend() unless $self->{legend};
	$self->{legend}->add_item($name, $color, $url, $tooltip);
}

=head3 _add_ruler()

 Synopsis: $alignment->_add_ruler($x,$y), where $x is the top margin 
          and $y is the height of the ruler.

 Description:  Add a ruler to the alignment object, the start_value and 
 end_value are set to the same as those of the alignment.  If no member 
 has been added to the alignment object, the seq_length, start_value and 
 end_value of the alignment are not set (see sub add_member), then a ruler 
 can not be added.

=cut

sub _add_ruler {
	my $self = shift;

	my $ruler = CXGN::Phylo::Alignment::Ruler->new (
					   start_value=>$self->{start_value}, 
					   end_value=>$self->{end_value}
					  ); 
	($self->{type} eq 'pep') and ($ruler->set_unit('aa'));
	($self->{type} eq 'nt') and ($ruler->set_unit('bp'));
	$self->{ruler} = $ruler;
}

=head3 _add_cvg_chart()

 Synopsis: $alignment->_add_ruler($x,$y,$z), while $x is the vertical 
 offset, $y is the id and $z is a hash reference whose key is an integer 
 (a position) and value is a percentage

 Description:  Add a chart representing coverage by a member.  The 
 start_value and end_value are set to the same as those of the alignment.  
 The coverage of each alignment postion is repreesnted by a hash reference 
 passed to the subroutine.  The key of the hash is the alignment postion 
 and the values are percentage converage. 

=cut

sub _add_cvg_chart {
  my $self = shift;
  my $title = shift;
  my $similarity_hash = shift;
  my $conservation_hash = shift;
  my $type_hash = shift;

  my $chart = CXGN::Phylo::Alignment::Chart->new (
					   start_value=>$self->{start_value}, 
					   end_value=>$self->{end_value}, 
					   id=>$title,
					   type=> $self->{type},
					   similarity_hash=>$similarity_hash,
					   conservation_hash=>$conservation_hash,
					   type_hash => $type_hash,
					  ); 
  $self->{chart} = $chart;
}

sub _add_legend {
	my $self = shift;

	$self->{legend} = CXGN::Phylo::Alignment::Legend->new(
							left_margin => $self->{left_margin},
							top_margin => $self->{height} - 100,
							);
}




=head3 _add_conserved_seq_obj()

Synopsis: $alignment->_add_conserved_seq_obj($x), while $x is the vertical offset.

Description:  Add a member object representing the conserved sequence of 
the @members.  The seq of this object is generated by another subroutine 
get_conserved_seq.   If the sequence at a position is not conserved among 
all present members, it is repreesnted by - in conserved_seq.  This 
object is NOT a member of @members.

=cut

sub _add_conserved_seq_obj {
	my $self = shift;
	my $title = shift;
	$title ||= "Overall Conserved Sequence";
	my $seq = $self->get_conserved_seq();
	my $seq_obj = CXGN::Phylo::Alignment::Member->new (
						 start_value => $self->{start_value}, 
						 end_value => $self->{end_value}, 
						 id => $title, 
						 seq => $seq,
						 species => ' ',
						);
	$self->{conserved_seq} = $seq_obj;
}


=head1 Subroutines to search and ouput ids of @members

is_id_member(), is_member(), id_to_member(), get_member_ids(), 
get_nonhidden_member_ids, get_hidden_member_ids(), get_member_species(), 
get_member_urls()

=cut

=head3 is_id_member()

Synopsis: is_id_member($id)

Description:  Do any of the members have the same id as $id?

Returns:  1 for true and 0 for false

=cut

sub is_id_member {
	my $self = shift;
	my $id = shift;
	foreach (@{$self->{members}}) {
		return 1 if $_->{id} eq $id;
	}
	return 0;
}

=head3 is_member()

Synopsis:  is_member($member), while $member is an member object 

Description:  Is $member already a member?

Returns:  1 for true and 0 for false

=cut

sub is_member {
	my $self = shift;
	my $member = shift;
	foreach (@{$self->{members}}) {
		return 1 if $member == $_;
	}
	return 0;
}

=head3 id_to_member()

Synopsis: $alignment->id_to_member($id);

Description: check if a alignment member has the id $id and return the alignment member

Returns: an alignment object

=cut
  
sub id_to_member {
	my $self = shift;
	my $id = shift;
	foreach (@{$self->{members}}) {
		return $_ if $_->{id} eq $id;
  	}
}

=head3 get_member_ids()

Synopsis: $alignment->get_member_ids()

Description:  Returns ids of all members

Returns:  an array of ids of all non-hidden @members elements

=cut
  
sub get_member_ids {
  my $self = shift;

  my @member_ids = ();
  push (@member_ids, $_->get_id) foreach (@{$self->{members}});
  return \@member_ids;
}

sub get_member_nr {
  my $self = shift;

  my $number = int (@{$self->{members}});
  return $number;
}


=head3 get_nonhidden_member_ids()

Synopsis: $alignment->get_nonhidden_member_ids()

Description:  Returns ids of members that are not hidden

Returns:  an array of ids of all non-hidden @members elements

=cut

sub get_nonhidden_member_ids {
  my $self = shift;

  my @members = ();
  foreach (@{$self->{members}}){
    unless($_->is_hidden) {
      my $id = $_->get_id();
      push @members, $id;
    }
  }
  return \@members;
}

sub get_nonhidden_member_nr {
  my $self = shift;
  my $number = 0;
  foreach (@{$self->{members}}){
    $number++ unless $_->is_hidden;
  }
  return $number;
}

=head3 get_hidden_member_ids()

Synopsis: $alignment->get_hidden_member_ids()

Description:  Returns ids of members that are hidden

Returns:  an array of ids of all hidden @members elements

=cut


sub get_hidden_member_ids {
	my $self = shift;
	my @members = ();
	foreach (@{$self->{members}}){
		push (@members, $_->get_id()) if ($_->is_hidden());
	}
	return \@members;
}

sub get_hidden_member_nr {
	my $self = shift;
	my $number = 0;
	foreach (@{$self->{members}}){
		$number++ if $_->is_hidden;
	}
	return $number;
}

sub get_visible_member_nr {
	my $self = shift;
	my $hidden_number = 0;
	foreach (@{$self->{members}}){
		$hidden_number++ if $_->is_hidden;
	}
	return $self->get_member_nr - $hidden_number;
}

=head3 get_member_species()

Synopsis: $alignment->get_member_species()

Description:  Return the species of each member of @members

Returns:  A hash reference whose keys are ids and values are species

=cut

  
sub get_member_species {
  my $self = shift;

  my %member_species = ();
  foreach (@{$self->{members}}){
    my $id = $_->get_id;
    my $species = $_->get_species();
    $member_species{$id} = $species;
  }
  return \%member_species;
}

sub get_member_urls {
  my $self = shift;

  my %member_url = ();
  foreach (@{$self->{members}}) {
    my $id = $_->get_id;
    my $url = $_ ->get_url();
    $member_url{$id} = $url;
  }

  return \%member_url;
}

=head2 Image processing subs of the package

render(), render_png(), render_jpg(), render_png_file(), render_jpg_file(), get_image_map()

=cut


sub layout {
	my $self = shift;
	my ($option) = $self->{display_type} =~ /^(\w)/;
	$option = lc($option);
	$option ||= 'c';

	$self->_add_ruler() unless $self->{ruler};
	$self->_add_cvg_chart("Coverage %", $self->get_ngap_pct) if ($option =~ /^(c|s)/i && !$self->{chart});
	#$self->_add_conserved_seq_obj() if ($option =~ /^(c|s)/i && !$self->{conserved_seq});

	my $label_gap = $self->_calculate_label_gap();

	#The ImageObjects: Chart, Ruler, Member must all be width-adjusted to account for
	#label spacing and alignment image margins.  This is an example where ImageObjects
	#should be subclassed and rendered properly in the first place, taking label spacing 
	#into account, but this is much easier for now:
	my $width_adjustment = $label_gap + $self->get_left_margin + $self->get_right_margin;
	$width_adjustment = $self->{width_adjustment} if exists $self->{width_adjustment};		

	my $ruler = $self->{ruler};
	my $ruler_top_margin = 0;
	if($ruler){
		$ruler->layout_top_margin($self->get_top_margin);
		$ruler->layout_left_margin($self->get_left_margin);
		$ruler->layout_width($self->get_width - $width_adjustment);
		$ruler->layout_label_spacer(20);
		$ruler->layout_color(140, 140, 140);
		$ruler->layout_label_color(120, 120, 120);
#		$ruler->layout_height($self->get_height);
		$ruler_top_margin = $ruler->get_top_margin;
	}
	my $chart = $self->{chart};
	my $chart_height = 0;
	if($chart){
		$chart->layout_top_margin($ruler_top_margin + 20);
		$chart->layout_left_margin($self->get_left_margin);
		$chart->layout_width($self->get_width - $width_adjustment);
		$chart->layout_label_spacer(20);
		$chart->layout_color(90, 90, 150);
		$chart->layout_height(40);
		$chart_height = $chart->get_height;
	}
	
	if ($option eq 'c' || $option eq 'a' || $option eq 's') { #alignment shown, default layout if member values not set
		my $align_v_offset;
		($option eq 'c' || $option eq 's') and $align_v_offset = $ruler_top_margin + $chart_height + 40;
		($option eq 'a') and $align_v_offset = $ruler_top_margin + 20;
		foreach my $m (@{$self->{members}}) {
			next if ($m->is_hidden());
			$m->layout_top_margin($align_v_offset);
			$m->set_left_margin($self->get_left_margin());
			$m->layout_width($self->get_width() - $width_adjustment);
			$m->layout_label_spacer(20);
			$m->layout_height(15);
			$m->layout_color(20, 20, 160);
			$m->layout_label_color(90, 90, 90);
			$align_v_offset += $m->get_height;
		}
		my $members_height = $align_v_offset;
		$self->set_height($members_height + 20);
	}
	else {
		$self->set_height($ruler_top_margin + $chart_height + 40);
	}

	$ruler->layout_height($self->get_height - 20) if $ruler;

	my $legend = $self->{legend};
	if($legend){
		$legend->{width} = $self->{width} - $self->{left_margin} - $label_gap;
		$legend->layout();
		$self->{height} = ($self->{height} + $legend->{height} + 10);
		$legend->{top_margin} = ($self->{height} - $legend->{height} - 20);
		$self->{height} -= 5;
		$legend->{left_margin} += 5;
	}

}

=head3 render()

Synopsis: $alignment->render($o) where $o represnts option, 'c' for complete, 'a' for alignment only and 's' for simple (only the ruler, coverage chart and conserved sequence, no individual members of @members)

Description: it does the following
 1. Generage, set and render a ruler
 2. Generate, set and render a chart representing coverge
 3. Generate, set and render a member object representing conserved sequence
 4. Render all non-hidden members of the @aign_seqs


Returns: 

=cut

sub render {
	my $self = shift;
	
	$self->layout();
	
	#Generate a image object for the ImageObject (member, ruler and chart) to render
	unless($self->{image}){
		$self->{image} = 
		GD::Image->new(
			$self->get_width(),			
			$self->get_height()
			) 
			or die "Can't generate image\n";
	}

		
	# the first color located is the background color, white
	$self->{white} = $self->{image}->colorResolve(255,255,255);
	
	$self->{image}->filledRectangle(0,0 ,$self->{width}, $self->{height},  $self->{white});

	$self->{chart}->render($self->{image}) if ($self->{chart});
	
	$self->{ruler}->render($self->{image}, $self) if ($self->{ruler});
	$self->{conserved_seq}->render($self->{image}) if ($self->{conserved_seq});
	

	my ($option) = $self->{display_type} =~ /^(\w)/;
	$option = lc($option);
	my $m;
	if($option eq 'a' || $option eq 'c'){
		foreach (@{$self->{members}}) {
			$_->render($self->{image}) unless ($_->is_hidden);
			$m = $_;
		}
	}

	#Send one member to legend renderer as sample for base_showing mode,
	#where colors must be lightened.  Easiest if member has already been
	#rendered: otherwise, scaling factor and text width must be calculated
	#explicitly.
	$self->{legend}->render($self->{image}, $self, $m) if ($self->{legend} && ($option eq 'c' || $option eq 's'));

}

=head3 render_png(), render_jpg()

Synopsis: $alignment->render_jpg(), $alignment->render_png

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
    $self->render();
    print $self->{image}->png();
}

sub render_jpg {
    my $self = shift;
    $self->render();
    print $self->{image}->jpeg();
}    

=head3 render_png_file(), render_jpg_file()

SYnopsis: $alignment->render_png_file($file_name, $option), $alignment->render_jpg_file($file_name, $option)

Description:  take a filename as arguments, render itself and output pgn or jpg image to the file.

Returns:

=cut

sub render_png_file {
    my $self = shift;
    my $filename = shift;
    $self->render();
    open (F, ">$filename") || die "Can't open $filename for writing!!! Check write permission in dest directory.";
    print F $self->{image}->png;
    close(F);
}

sub render_jpg_file {
    my $self = shift;
    my $filename = shift;
    $self->render();
    open (F, ">$filename") || die "Can't open $filename for writing!!! Check write permission in dest directory.";
    print F $self->{image}->jpeg;
    close(F);
}

=head3 write_image_map()

Synopsis: $alignment->write_image_map()

Description: get the image map string of each non-hidden @members, concat them and return as a single string

Returns:  a string

=cut

sub get_param {
	my $self = shift;
	return $self->{param};
}

sub set_param {
	my $self = shift;
	my $hashref = shift;
	die "Not hashref" unless (ref $hashref eq "HASH");
	$self->{param} = $hashref;
}

sub get_image_map {
	my $self = shift;
	my($show_sv, $show_breakdown) = @_;
	my $map_content;
	

	#XHTML 1.0+ requires id; name is for backward compatibility -- Evan, 1/8/07
	$map_content = "<map name='align_image_map' id='align_image_map'>\n"; 
	foreach (@{$self->{members}}) {
            unless ( ref && $_->isa(__PACKAGE__.'::Member') ) {
                require Data::Dumper;
                warn "members list is:\n".Data::Dumper::Dumper($self->{members});
                confess "invalid member '$_'";
            }
		next if ($_->is_hidden);
		$_->set_url(identifier_url($_->get_id));
		my $string = $_->get_imagemap_string();
		$map_content .= $string . "\n";     
	} 
	if($self->{ruler} && $self->get_fasta_temp_file){
		my ($sv_shared, $sv_similarity, $sv_indel) = $self->get_sv_criteria;
		my $hide_seq_string = join("%20", @{$self->get_hidden_member_ids});
#		my $extra_url_vars = hash2param($self->get_param);
		$map_content .= $self->{ruler}->get_imagemap_string($self, $self->get_param);
	}
	$map_content .= $self->{legend}->get_imagemap_string() if $self->{legend};
	$map_content .= "</map>\n";
	return $map_content;
}




=head1 Subroutines to analyze sequences of @members and output result

get_member_similarity(), get_sv_candidates(), get_allele_candidates(), 
get_overlap_score(), get_all_overlap_score(), get_all_medium(), 
get_all_range(), get_seqs(), get_nopad_seqs(), get_overlap_seqs(), 
get_overlap_nums(), get_ngap_pct(), get_all_ngap_length(), 
get_conserved_seq_obj()

=cut

=head3 get_member_similarity()

Sysopsis: $alignment->get_member_similarity($al_sq) where $al_sq is an object of of algn_seq and member of @members

Description: To output pair-wise similarities (overlap base, percentage indentity)of the member which is specified as argument between other members of @members.  

Returns: two hash references, one for overlap bases and the other for percentage indentity.  The key of both hashes are the ids of other non hidden members of @members

=cut

sub get_member_similarity {
	my $self = shift;
	my $al_sq = shift;
	my %member_ol = ();
	my %member_pi = ();

	foreach (@{$self->{members}}) {
		next if $_ == $al_sq;
		my ($overlapping, $percent_ident) = $al_sq->calculate_similarity($_);
		my $other_id = $_->get_id();
		$member_ol{$other_id} = $overlapping;
		$member_pi{$other_id} = $percent_ident;
	}
	return \%member_ol, \%member_pi;
}

=head3 get_sv_candidates()

 Synopsis: $alignment->get_sv_candidates() 
 Description:  make pairwise comparison between members of @members of the 
 same species.  If the pair have enough overlap, and the percentage 
 indentity is high enough, and they have enough insertion-deletion (
 specified as parameter), they are considered as putative splice variant pair  

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

  foreach (my $i = 0; $i < @{$self->{members}}; $i++){
    foreach (my $j = $i + 1; $j < @{$self->{members}}; $j++){
      (($self->{members}[$i]->get_species()) ne ($self->{members}[$j]->get_species())) and next;
      my ($ol_seq1, $ol_seq2) = $self->{members}[$i]->get_clean_member($self->{members}[$j]);

     (!(($ol_seq1 =~ /$indel/) || ($ol_seq2 =~ /$indel/))) and next;
      
      my ($self_id, $other_id) = ($self->{members}[$i]->get_id(), $self->{members}[$j]->get_id());
      my ($ob, $pi) = $self->{members}[$i]->calculate_similarity($self->{members}[$j]);
      if ( ($ob >= $overlap) && ($pi >= $self->{sv_identity})){
	$sv_candidate_ob{$self_id}{$other_id} = $ob;
	$pi = sprintf("%.2f", $pi);#truncate the number to two digits after the decimal point
	$sv_candidate_pi{$self_id}{$other_id} = $pi;
	$sv_candidate_sp{$self_id} = $self->{members}[$i]->get_species;
      }
    }
  }
  return \%sv_candidate_ob, \%sv_candidate_pi, \%sv_candidate_sp;
}

=head3 get_allele_candidates()

 Synopsis: $alignment->get_allele_candidates()

 Description:  make pairwise comparison between members of @members of the 
 same species.  If the pair have enough overlap, and the percentage 
 indentity is high enough, and they only have short insertion-deletion 
 (specified as parameter), they are considered as putative allele pair  

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
  foreach (my $i = 0; $i < @{$self->{members}}; $i++){
    foreach (my $j = $i + 1; $j < @{$self->{members}}; $j++){
      (($self->{members}[$i]->get_species()) ne ($self->{members}[$j]->get_species())) and next;
      my ($ol_seq1, $ol_seq2) = $self->{members}[$i]->get_clean_member($self->{members}[$j]);
      
      (($ol_seq1 =~ /$indel/) || ($ol_seq2 =~ /$indel/)) and next; #skip if the aequence pair have long indel
      
      my ($self_id, $other_id) = ($self->{members}[$i]->get_id(), $self->{members}[$j]->get_id());
      my ($ob, $pi) = $self->{members}[$i]->calculate_similarity($self->{members}[$j]);
      if ( $ob >= $overlap && ($pi >= $self->{sv_identity})){
	$al_candidate_ob{$self_id}{$other_id} = $ob;
	$pi = sprintf("%.2f", $pi);#truncate the number to two digits after the decimal point
	$al_candidate_pi{$self_id}{$other_id} = $pi;
	$al_candidate_sp{$self_id} = $self->{members}[$i]->get_species;
      }
    }
  }
  return \%al_candidate_ob, \%al_candidate_pi, \%al_candidate_sp;
}

=head3 get_overlap_score();

Synopsis: $alignment->get_overlap_score($alignment) where $member is an object of align

Description:  Calculate the overlap score of a member of @ members, which is specified as parameter.  At a particular position of the target sequence(s1) has an overlap (not a gap) in another sequence (s2), s1 gets 1 point for alignment score.  The total alignment score of s1 is the sum of all its non-gap positions.

Returns: an integer

=cut

sub get_overlap_score {
  my $self = shift;
  my $al_sq = shift;

  return unless $self->is_member($al_sq);
  return if $al_sq->is_hidden;
  my $score = 0;
  foreach ( my $i = $self->{start_value}-1; $i < $self->{end_value}-1; $i++){
    my $base = substr($al_sq->get_seq(), $i, 1);
    $base eq '-' and next; # if a gap, next
# char in al_sq is not a gap
    foreach (@{$self->{members}}) {
      $_ == $al_sq and next; # do all sequences except skip $al_sq
      next if $_->is_hidden;
      my $other_base = substr ($_->get_seq(), $i, 1);
      if ($other_base ne '-') {
	$score++;
      }
    }
  }
  return $score;
}    

=head3 get_all_overlap_score()

Synopsis: $alignment->get_all_overlap_score()

Description: score of all the non-hiden members in @members

Returns: A hash reference whose key is the id of a @members elements and the value is the overlap score

=cut

sub get_all_overlap_score {
	my $self = shift;
	
	my %member_score = ();
	foreach (@{$self->{members}}){
		next if $_->is_hidden;
		my $score = $self->get_overlap_score($_);
		my $id = $_->get_id();
		$member_score{$id} = $score;
	}
	return \%member_score;
}

=head3 get_all_medium

Synopsis: $alignment->get_all_medium()

Description: Returns the medium position of each alignment sequence, in hash form

Returns: A hash reference whose key is the id of a @members elements and the value is the medium position

=cut

sub get_all_medium {
	my $self = shift;
 
	my %member_medium = ();
	foreach (@{$self->{members}}){
		unless ($_->is_hidden) {
			my $medium = $_->get_medium();
			my $id = $_->get_id();
			$member_medium{$id} = $medium;
		}
	}
	return \%member_medium;
}

=head3 get_all_range

Synopsis: $alignment->get_all_range()

Description: Output the start and end of characters of each member sequence

Returns: Two hash references whose keys are the id of a @members element 
 and whose values are the start and end positions, respectively
 ($start_pos, $end_pos) = ($start_ref->{$id}, $end_ref->{$id})

=cut

sub get_all_range {
  my $self = shift;

  my %member_head = ();
  my %member_end = ();
  foreach (@{$self->{members}}) {
    unless($_->is_hidden){
      my ($head, $end) = $_->get_range();
      my $id = $_->get_id();
      $member_head{$id} = $head;
      $member_end{$id} = $end;
    }
  }
  return \%member_head, \%member_end;
}

=head3 get_seqs()

Synopsis: $alignment->get_seqs()

Description: Output the alignment sequences (padded with gaps) of @members which are are not hidden, in the range specified by start_value and end_value

Returns: a hash reference whose key is the id of each member and the value is the alignment sequence

=cut

sub get_seqs {
  my $self = shift;
  (!defined @{$self->{members}}) and return;

  my %member_seqs = ();
  foreach (@{$self->{members}}) {
    unless ($_->is_hidden) {
      my $id = $_->get_id();
      my $seq = $_->get_select_seq();
      $member_seqs{$id} = $seq;
    }
  }
  return \%member_seqs;
}

=head3 get_nopad_seqs()

 Synopsis: $alignment->get_nopad_seqs()
 Description: Output the 'original' sequences (with gaps removed) of @members 
              which are are not hidden, in the range specified by start_value and end_value
 Returns: a hash reference whose key is the id of each members and the value is the sequence

=cut

sub get_nopad_seqs {
  my $self = shift;
  (!defined @{$self->{members}}) and return;

  my %member_seqs = ();
  foreach (@{$self->{members}}) {
    unless ($_->is_hidden) {
      my $id = $_->get_id();
      my $seq = $_->get_select_seq();
      $seq =~ s/-//g;
      $member_seqs{$id} = $seq;
    }
  }
  return \%member_seqs;
}

=head3 get_overlap_seqs()

 Synopsis: $alignment-> get_overlap_seqs($max_gaps)
Arguments: $max_gaps specifies a maximum number of gaps allowed in kept columns. Default is zero. 
 Description: for each non-hidden @members, get the sequences that overlap with all 
              the other non-hidden @members, in the range from start_value to end_value
 Returns: a hash reference whose key is the id of each member and the value is the overlap sequence

=cut

sub get_overlap_seqs { 
	my $self = shift;
	my $max_gaps = shift;
	$max_gaps ||= 0;
	return unless (@{$self->{members}});
	my $cols_removed = 0;
	my $cols_kept = 0;
	my %overlap_seqs;  
	foreach (my $i = $self->{start_value} - 1; $i <= $self->{end_value} - 1; $i++) {
		my %single_base = ();
		my $gaps_in_col = 0;
		foreach (@{$self->{members}}) {
			next if $_->is_hidden; # skip hidden ones
			my $id = $_->get_id();
			$overlap_seqs{$id} = "" unless($overlap_seqs{$id}); # make sure there is a key/val pair for each id (with val empty string).
			my $base = substr($_->get_seq(), $i, 1);
			$single_base{$_->get_id()} = $base;
			if ($base eq '-') {
				$gaps_in_col++;
				last if($gaps_in_col > $max_gaps);
			}
		}
			
		# $overlap_seqs{$_} = "" unless (defined $overlap_seqs{$_});
		if ($gaps_in_col <= $max_gaps) {
			$cols_kept++;
			foreach (keys %single_base) {
#	$overlap_seqs{$_} = "" unless ($overlap_seqs{$_});
				$overlap_seqs{$_} .= $single_base{$_};
			}
		} else {
			$cols_removed++;
#			 $overlap_seqs{$_} = "" unless (defined $overlap_seqs{$_});
		}
	}
#	print "in get_overlap_seqs. cols kept, removed: ", $cols_kept, "   ", $cols_removed, "\n";
				return \%overlap_seqs;
			}

=head3 get_overlap_num()

Synopsis:  $alignment->get_overlap_num()

Description:  count the number of bases that overlap between all the non-
 hidden members, in the range from start_value to end_value

Returns:  an integer

=cut

sub get_overlap_num { 
	my $self = shift;
	if (0) {											# old way. works
		my $overlap_count = 0;
		return unless @{$self->{members}};

		#Get the first non-hidden member in @members as a basis for comparison
		my $select;
		foreach (@{$self->{members}}) {
			next if $_->is_hidden;
			$select = $_;
			last;
		}

		foreach (my $i = $self->{start_value} - 1; $i <= $self->{end_value} - 1; $i++) {
			my $base = substr($select->get_seq(), $i, 1);
    	next if $base eq '-';
    	my $pause = 0;
			foreach (@{$self->{members}}) {
				next if $_ == $select;	# skip $select
				next if $_->is_hidden;
				my $other_base = substr($_->get_seq(), $i, 1);
				if ($other_base eq '-') {
	  			$pause = 1;	
					last;
				}
    	}
			$overlap_count++ if ($pause==0);
		}
		return $overlap_count;
	} else {											# new way. also works but uses get_overlap_cols, which is more general as can allow >0 gaps in a col.
		my $overlap_cols = $self->get_overlap_cols();
		return $overlap_cols
	}
}

=head3 get_overlap_cols()

 Synopsis:  $alignment->get_overlap_cols($max_gaps)

 Description:  Like get_overlap_num, but can allow some number ($max_gaps) of gaps in a column (counting non-hidden members only).,
   instead of requiring this be strictly zero. ($max_gaps is 0 by default). 

 Returns:  The number of columns with no more than $max_gaps gaps in them.
=cut



sub get_overlap_cols{ 
	my $self = shift;
	my $max_gaps = shift;	# this is the max number of gaps allowed in a column which is kept in the overlap
		$max_gaps = 0 unless(defined $max_gaps); 
	return unless   @{$self->{members}}; # return if no sequences

												my $ncols = $self->{end_value} - $self->{start_value} + 1;
	my $gappy_cols = 0;
	foreach (my $i = $self->{start_value} - 1; $i <= $self->{end_value} - 1; $i++) {
		my $col_gaps = 0;
		foreach (@{$self->{members}}) {			
			next if $_->is_hidden;
			my $base = substr($_->get_seq(), $i, 1);
			if ($base eq '-') {
				$col_gaps++;		
				if ($col_gaps > $max_gaps) {
					$gappy_cols++;
					last;
				}
			}
		}	
	}
	return $ncols - $gappy_cols;
}


=head3 get_overlap_cols_nongapchars()

Synopsis:  $alignment->get_overlap_cols_nongapchars($max_gaps)

Returns:  A list of (The number of columns with no more than $max_gaps gaps in them, the number of non-gap characters in those columns)
	=cut

sub get_overlap_cols_nongapchars{ # gets the number of columns with <= max_gaps, and also the number of nongap chars in those columns.
	my $self = shift;
	my $max_gaps = shift;					# this is the max number of gaps allowed in a column which is kept in the overlap
	$max_gaps = 0 unless(defined $max_gaps); 
	my $overlap_cols = 0;
	my $overlap_nongap_chars = 0;
	return unless   @{$self->{members}}; # return if no sequences

	foreach (my $i = $self->{start_value} - 1; $i <= $self->{end_value} - 1; $i++) {
		my $col_gaps = 0;
		my $n_seq_nonhidden = 0;
		foreach (@{$self->{members}}) {			
			next if $_->is_hidden;
			$n_seq_nonhidden++;
			my $base = substr($_->get_seq(), $i, 1);
			if ($base eq '-') {
				$col_gaps++;				
			}
		}
		if ($col_gaps <= $max_gaps) {
			$overlap_cols++;
			$overlap_nongap_chars += $n_seq_nonhidden - $col_gaps;
		}
	}
	return ($overlap_cols, $overlap_nongap_chars);
}

=head3 get_ngap_pct()

Synopsis:  $alignment->get_ngap_pct()

Description:  go from start_value to end_value, get the percentage 
	coverage by @members.  A position is covered by a member when it has a 
	non gap at the position.

Returns:  a hash reference whose key is the position and values are the 
	percentage coverage

=cut

sub get_ngap_pct { 
    my $self = shift;
    my %value_hash = ();
    my %conservation_hash = ();
    my %type_hash = ();
    
    (!@{$self->{members}}) and return;
    
    my $total_nhidden_member = 0;
    foreach (@{$self->{members}}) {
	next if $_->is_hidden;
	$total_nhidden_member++;
    }
    
    foreach (my $i = $self->{start_value} - 1; $i < $self->{end_value}; $i++){
	my $ngap_count = 0;
	foreach (@{$self->{members}}) {
	    next if $_->is_hidden;
	    my $seq = $_->get_seq();
	    my $base = substr($seq, $i, 1);
	    ($base ne '-') and $ngap_count++;
	}
	my $pct = $ngap_count / $total_nhidden_member * 100;
	$value_hash{$i} = sprintf("%.2f", $pct);
	
	if($pct>0){
	    my %na_count = ();
	    my %type_count = ();
	    my $base_count = 0;
	    foreach (@{$self->{members}}) {
		next if $_->is_hidden();
		my $base = substr($_->get_seq(), $i, 1);
		$base_count++;
		unless ($base eq '-') {
		    $na_count{$base}++;
		    my $type = $self->_get_aa_type($base);
		    $type_count{$type}++;
		}
		
	    }
	    my $max_ind = 0;
	    while(my($base, $count) = each %na_count){
		$max_ind = $count if($count>$max_ind);
	    }
	    my $max_type = 0;
	    while(my($type, $count) = each %type_count){
		$max_type = $count if ($count>$max_type);
	    }
	    if ($max_ind > 1){
		$conservation_hash{$i} = sprintf("%.2f", ($max_ind / $base_count) * 100);
	    }
	    if ($max_type > 1 && $self->{type} eq 'pep'){
		$type_hash{$i} = sprintf("%.2f", ($max_type / $base_count) * 100);
	    }
	}
	else { 
	    $conservation_hash{$i} = 0; 
	    $type_hash{$i} = 0;
	}
    }
    return \%value_hash, \%conservation_hash, \%type_hash;
}

=head3 get_all_nogap_length()

 Synopsis:  $alignment->get_all_nogap_length()

 Description:  Go from start_value to end_value, get the sequence length 
 without gap of @members...

 Returns:  A hash reference whose key is the id and value is the length

=cut

sub get_all_nogap_length {
	my $self = shift;
	my %member_ng_len = ();
	foreach (@{$self->{members}}) {
		next if $_->is_hidden();
		$member_ng_len{$_->get_id()} = $_->get_nogap_length();
	}
	return \%member_ng_len;
}

=head3 get_conserved_seq()

Synopsis:  $alignment->get_conserved_seq()

Description:  go through each postion from start_value to end_value of 
 non-hidden member of @members.  If all members have the same seq at the 
 position, get the seq, otherwise put a gap (-) in the position.

Returns:  s string of sequence

=cut

sub get_conserved_seq {
	my $self = shift;
	my $seq;

	return unless (@{$self->{members}});
	
	my $total_nhidden_member = 0;
	foreach (@{$self->{members}}) {
		next if $_->is_hidden;
		$total_nhidden_member++;
	}
	return if ($total_nhidden_member == 0);

	foreach (my $i = $self->{start_value}-1; $i < $self->{end_value}; $i++){
		my %na_count = ();
		my $base_count = 0;
		my $conserved_base = '-';
		foreach (@{$self->{members}}) {
			next if $_->is_hidden();
			my $base = substr($_->get_seq(), $i, 1);
			unless ($base eq '-') {
				$base_count++;
				$na_count{$base}++;
			}
		}
		($conserved_base) = (keys %na_count) if ((int(keys %na_count) == 1) && ($base_count > 1));
		$seq .= $conserved_base;
	}

	#fill in the positions before the start value with gap characters
	$seq = '-' x ($self->{start_value} - 1) . $seq; 
	return $seq;
}

sub _get_aa_type {
	my ($self, $aa) = @_;
	$aa = uc($aa);
	return unless (length($aa)==1);
	return "acidic" if ($aa =~ /D|E/);
	return "basic" if ($aa =~ /R|H|K/);
	return "polar" if ($aa =~ /N|C|Q|S|T/);
	return "nonpolar" if ($aa =~ /A|G|I|L|M|F|P|W|Y|V/);
}

sub highlight_domains {
	my $self = shift;
	#Retrieved from storable hash of gene objects, saving resources when possible:
	my $genes = shift; 

	$genes ||= {};

	my ($start_value, $end_value) = ($self->{start_value}, $self->{end_value});
	return unless $self->{type} eq "pep";
	my %domains; #general domain information
	my %correct_length;
	my $sigpos_found =0; #flag for displaying legend item

	my %member_domains; # member_id => array_ref of DB-derived domains

	foreach my $m(@{$self->{members}}){
		my $id = $m->get_id();
		my $gene = $genes->{$id};
		unless($gene){
			eval{
				$gene = CXGN::Tools::Gene->new($id);
				$gene->fetch("protein_length");
				$gene->fetch_sigp();
				$gene->fetch_dom();
			};
			$self->{page}->log($@) if $@ && ref($self->{page});
			$genes->{$id} = $gene;
		}
	}

	#Test the input sequences against protein lengths in the database. 
	#If they're not the same, the user put in a fragment, or incorrect
	#data.  Thus, we won't display misleading domain information.
	foreach my $m (@{$self->{members}}) {
		my $id = $m->get_id();
		my $db_seq_len = 0;
		my $gene = $genes->{$id};
		next unless $gene;
		$db_seq_len = length($gene->get_sequence('protein'));
		my $prot_seq = $m->get_ungapped_seq;
		$prot_seq =~ s/X$//; #stop codon may be translated to X
		(length($prot_seq)==$db_seq_len)?
		($correct_length{$id} = 1):
			($correct_length{$id} = 0);
	}

	#Iterate through members, collecting domain information that will determine
	#the predominant domains for which to show colors.  Also, determine signal
	#peptide and cleavage point.
	foreach my $member (@{$self->{members}}) {
		next if $member->is_hidden();

		my $id = $member->{id};
		
		next unless $correct_length{$id};
		my $gene = $genes->{$id};	
		next unless $gene;

		#Grab signal peptide
		my ($sigpos, $cleavage);
		$sigpos = $gene->isSignalPositive();
		$cleavage = $gene->getCleavagePosition();
		my($lb, $rb) = $member->translate_positions_to_seq($start_value, $end_value);
		unless (!$sigpos || $lb > ($cleavage+1)){
			my @pepcolor = (40, 180, 40);
			$member->add_region("Signal Peptide", 1, $cleavage-1, \@pepcolor) if $sigpos;
			$sigpos_found = 1;
		}

		#Grab Domains
		my @domains = $gene->getDomains;
		$member_domains{$id} = \@domains;
		
		foreach(@domains) {
			my ($lb, $rb) = $member->translate_positions_to_seq($start_value, $end_value);
			unless ((defined $rb && $_->{dom_start} > $rb ) || ($_->{dom_end} < $lb)) {
			$domains{$_->{dom_desc}}->{count}++;
			$domains{$_->{dom_desc}}->{length_tally} += ($_->{dom_end} - $_->{dom_start});
			$domains{$_->{dom_desc}}->{tooltip} = $_->{dom_full_desc} if $_->{dom_full_desc};
			$domains{$_->{dom_desc}}->{url} = identifier_url($_->{dom_interpro_id});
		}
		else {
				my $debug = "Dom-start: ". $_->{dom_start} . "\n" . "Dom-end: " . $_->{dom_end} . "\nRb: $rb\nLb: $lb";
				#die $debug;	
			}
		}
	}
	
	$self->add_legend_item("Signal Peptide", [40,180,40]) if $sigpos_found;
	
	my @limited_domain_colors = (
		[130, 20, 120],
		[20, 10, 80],
		[30, 100, 30],
		[70, 90, 10],
		[130, 140, 0],
		[170, 80, 20],
		[170, 10, 10],
		[70, 0, 70],
		[120, 70, 30],
		[130, 0, 50]
	);

	my $limited_count = scalar @limited_domain_colors;

	my $other_domain_color = [140, 140, 140]; #everything else
	my %domain_color;
	my $color_limit_reached = 0;
	foreach my $domain ( sort{$domains{$b}->{length_tally} <=> $domains{$a}->{length_tally}} keys %domains) {
		if(@limited_domain_colors){
			$domain_color{$domain} = shift @limited_domain_colors;
		}
		else{
			$color_limit_reached = 1;
		}
	}

	#Second domain iteration.  This time, we know which domains are assigned to
	#which colors, so we can set the highlighting.
	foreach my $m (@{$self->{members}}){
		next if $m->is_hidden();
		my $id = $m->{id};
		next unless $correct_length{$id};

		my @domains = @{$member_domains{$id}};
		foreach(@domains){
			my $desc = $_->{dom_desc};
			my $color = $domain_color{$desc};
			$color ||= $other_domain_color;
			$m->add_region($desc, $_->{dom_start}, $_->{dom_end}, $color);
		}
	}
	
	while(my ($desc, $color) = each %domain_color){
		$self->add_legend_item($desc, $color, $domains{$desc}->{url}, $domains{$desc}->{tooltip});
	}
	if($color_limit_reached){
		my $overage = ((scalar keys %domains) - $limited_count);
		$self->add_legend_item("Other ($overage)", $other_domain_color);
	}
	return $genes; #return hashref to be stored by script, optionally
}

sub print_to_file {
	my $self = shift;
	my $file = shift;
	open(WF, ">$file") or die("Can't open file '$file' for writing");
	print WF $self->to_fasta();
}

sub print_to_stdout {
	my $self = shift;
	print $self->to_fasta();
}

sub to_fasta { 
	my $self = shift;
	my $string = "";
	foreach my $m (@{$self->{members}}){
		$string .= $m->to_fasta . "\n";
	}
	return $string;

}

sub run_muscle {
	my $self = shift;
    my @local_run_output = "";
	my $command_line = "";
	my $path = $self->get_tmp_dir();
	my $run = shift;
	$run ||= "local";
	
	my $maxiters = 2;
	$maxiters = $self->{muscle}->{maxiters} if ref $self->{muscle};
	$maxiters ||= 2;

	if ($run eq "local") { 
		my @t = `which muscle`;
		my $mt = $t[0];
		chomp $mt;
		unless(-x $mt){
			warn "Program 'muscle' not available, alignment will not be performed.";
			return;
		}
		my $wd = &Cwd::cwd();
		chomp $wd;
		my $temp_file = File::Temp->new(
				TEMPLATE => 'unaligned-XXXXXXX',
				UNLINK=>1,
				DIR => $path,
		);
		$self->print_to_file($temp_file->filename);
		my $result_file = $temp_file . ".aligned.fasta";
        chdir $path;
		$command_line = "muscle -in $temp_file -out $result_file -maxiters $maxiters";
        print STDERR "Running: $command_line\n";
        @local_run_output = `$command_line `;
	
		my $aligned = __PACKAGE__->new({from_file=>$result_file});
		
		$self->{members} = $aligned->{members};
		$self->{seq_length} = $aligned->{seq_length};

		system "rm $result_file";
		chdir $wd;
    }

	if ($run eq "cluster") { 
            die 'cluster runs no longer supported in this module';

        }
}


1;





