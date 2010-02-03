=head2 BLAST::tomato_bac_ends

  BLAST versus BAC ends

  Secondary input parameters:
    blastall_binary   - (optional) full path to blastall executable
    bac_ends_blast_db - (optional) file_base of the L<CXGN::BlastDB> to use

=cut

package CXGN::TomatoGenome::BACSubmission::Analysis::BLAST::tomato_bac_ends;
use CXGN::Genomic::CloneIdentifiers qw/parse_clone_ident/;

use Data::Dumper;

use base 'CXGN::TomatoGenome::BACSubmission::Analysis::BLAST::Base';

__PACKAGE__->run_for_new_submission(1);
sub list_params {
  return ( blastall_binary => 'optional full path to blastall executable',
	   bac_ends_blast_db => 'optional file_base of the CXGN::BlastDB bac ends blast database to use',
	 );
}
sub _fileset {
  my ($self,$aux_inputs) = @_;
  return ($aux_inputs->{bac_ends_blast_db} || 'bacs/tomato_bac_ends');
}

sub _feature_type {
  my ($self,$f) = @_;
  my $p = parse_clone_ident( $f->[1], 'bac_end' )
    or die "cannot parse bac end ident '$f->[1]'";

  if( $p->{end} eq 'left' ) {
    return 'clone_start';
  } elsif( $p->{end} eq 'right' ) {
    return 'clone_end'
  } else {
    return 'match';
  }
}


sub _write_gff3 {
  my ($self,$submission,$outfile, $gff3_file) = @_;
  open my $out_fh, '<', $outfile or die "Could not open blast output file $outfile: $!";
  my $fo = $submission->_open_gff3_out($gff3_file);

  ### parse the whole blast report, index the blast lines by BAC name (not bac end name)
  my %lines;
  while (my $line = <$out_fh> ) {
    next if $line =~ /^\#/ || ! $line =~ /\S/;
    next unless $self->_use_line($line);
    chomp $line;
    my @fields = my ($qname, $hname, $percent_id, $hsp_len, $mismatches,$gapsm,
		     $qstart,$qend,$hstart,$hend,$evalue,$bits) = split /\s+/,$line;
    my $p = parse_clone_ident($hname,'bac_end')
      or die "cannot parse bac_end ident '$hname'";
    $p->{end} eq 'left' || $p->{end} eq 'right'
      or die "sanity check failed, invalid 'end' field value ($p->{end}) in parsed bac_end name '$hname'";
    push @{$lines{$p->{clone_name}}}, {fields => \@fields, p => $p};
  }
  close $out_fh;

  my @sequences = $submission->sequences;
  @sequences == 1 or die $submission->tarfile.' should not have multiple sequences!';

  my @features = map { $self->_build_bac_end_features($sequences[0]->length, $_, $lines{$_}) } keys %lines;

#     my $fwdrev = $hstart >= $hend ? 'rev' : 'fwd';
#     #	   my $plusminus = $hstart >= $hend ? '-' : '+';
#     my $feature = $self->new_feature( -start => $qstart,
# 				      -end   => $qend,
# 				      -score => $bits,
# 				      -type  => $self->_feature_type(\@fields),
# 				      -source => $self->analysis_name,
# 				      -seq_id => $qname,
# 				      -target => { -start => $hstart,
# 						   -end   => $hend,
# 						   -target_id => $self->_target_name($hname),
# 						 },
# 				      -annots => { ID => $self->_unique_bio_annotation_id("${hname}_${fwdrev}_alignment"),
# 						   blast_percent_identity => $percent_id,
# 						   blast_mismatches => $mismatches,
# 						   blast_gaps => $gapsm,
# 						   blast_evalue => $evalue,
# 						 },
# 				    );

  $fo->write_feature( $_ ) foreach sort {$a->start <=> $b->start} @features;
}

sub _build_bac_end_features {
  my ($self,$seq_length,$clone_name,$lines) = @_;
  my @lines = @{$lines};

  # find all possible forward-reverse pairs in the lines,
  # by doing a all-vs-all comparison
  my @fr_pairs;
  my %pairs_membership;
  my %uniq_pairs;
  foreach my $a (@lines) {
    foreach my $b (@lines) {
      if (     $a->{p}{end}
	       && $b->{p}{end}
	       && $a->{p}{end} ne $b->{p}{end}
	 ) {
	my ($al,$bl) = ( $a->{fields}[6] < $b->{fields}[6] ? ($a,$b) : ($b,$a) );
	# now $al, $bl is sorted by start coord
	
	# the matches must be in different senses, as well, for it to
	# be a valid pair, so check that, and check that we have not
	# done this pair already
	my $pair_uniq_key = $al.$bl;
	next if $uniq_pairs{$pair_uniq_key};
	my $a_matchdir = $al->{fields}[8] <= $al->{fields}[9] ? 1 : 0;
	my $b_matchdir = $bl->{fields}[8] <= $bl->{fields}[9] ? 1 : 0;
	next if $a_matchdir == $b_matchdir;

	# now make the pair and record that we have it
	push @fr_pairs, [$al,$bl];
	$pairs_membership{$al} = 1;
	$pairs_membership{$bl} = 1;
	$uniq_pairs{$pair_uniq_key} = 1;
      }
    }
  }

  # does it have forward-reverse pairs that look problematic?
  # sort the pairs into good pairs and problematic-looking pairs
  my @good_pairs;
  my @problematic_pairs;
  while (my $pair = shift @fr_pairs) {
    my ($a,$b) = @$pair;
    $a->{fields}[6]
      or warn 'invalid a fields! '.Dumper($a);
    $b->{fields}[6]
      or warn 'invalid b fields! '.Dumper($a);
    $a->{fields}[6] && $b->{fields}[6]
      or die 'sanity check failed';

    my $dist = $a->{fields}[6] - $b->{fields}[6];
    $dist = -$dist if $dist < 0;
    if ( my $dist_bounds = _ideal_end_distance( $a->{p}{clonetype} ) ) {
      if ( $dist > $dist_bounds->{minus_2sd} && $dist < $dist_bounds->{plus_2sd} ) {
	push @good_pairs, $pair;
      } else {
	#warn "problematic distance $dist ($dist_bounds->{minus_2sd},$dist_bounds->{plus_2sd})\n";
	push @problematic_pairs, $pair;
      }
    } else {
      push @good_pairs, $pair;
    }
  }

  # does it have single matches that look problematic? (go off the end of the BAC)?
  my @single_matches = grep !$pairs_membership{$_}, @lines;
  my @good_singles;
  my @problematic_singles;
  while( my $s = shift @single_matches ) {
    # for this code, we think of a true value in $dir as a match that
    # indicates the clone extends to the right (increasing coords),
    # and a false value indicating the clone extends to the left
    # (decreasing coords)
    my $dir = $s->{fields}[8] < $s->{fields}[9]; #< false is 'clone extends to left', true is 'clone extends to right'
    my $clone_end_coord = $s->{fields}[($dir ? 6 : 7)];
    #$dir = $dir ? 'left' : 'right';
    # and now dir is 'left' or 'right', indicating whether the clone
    # extends to the left or the right

    my $dist_from_end = $dir ? $seq_length - $clone_end_coord + 1  #< clone extends to right
                             : $clone_end_coord;                   #< clone extends to left
    #print join(' ',@{$s->{fields}}).", extends to ".($dir ? 'right' : 'left').", dist from end $dist_from_end\n";

    if( my $dist_bounds = _ideal_end_distance( $s->{p}{clonetype} ) ) {
      if( $dist_from_end < $dist_bounds->{plus_2sd} ) {
	push @good_singles, $s;
      } else {
	#warn "problematic distance $dist_from_end ($clone_end_coord,$s->{p}{end},$dir) ($dist_bounds->{minus_2sd},$dist_bounds->{plus_2sd})\n";
	push @problematic_singles, $s;
      }
    } else {
      push @good_singles, $s;
    }
  }

  # now that we have sorted our pairs and singles into good ones and
  # problematic ones, make features for them
  my @features;

  foreach my $r ( (map [$_,0], @good_pairs),
		  (map [$_,1], @problematic_pairs),
		) {
    my ($p,$problematic) = @$r;
    my ($al,$bl) = @$p;
    my ($clone_strand,$atype,$btype) = do {
      if( $al->{p}{end} eq 'left' ) {
	qw/ + clone_start clone_end /
      } else {
	qw/ - clone_end clone_start /
      }
    };
    my $af = $self->_line_rec_to_feature($atype, $problematic, $al );
    my $bf = $self->_line_rec_to_feature($btype, $problematic, $bl );
    #($af,$bf) = ($bf,$af) unless $af->start < $bf->start; #< make sure the two features are coord sorted
    my $parent_id = $self->_unique_bio_annotation_id("$al->{fields}->[0]-$al->{p}->{clone_name}");

    my $pf = $self->new_feature( -type => 'clone',
				 -start => $af->start,
				 -end   => $af->end,
				 -strand => $clone_strand,
				 -frame => $af->frame,
				 -source => $af->source,
				 -seq_id => $af->seq_id,
				 -score  => ($af->score()->value() + $bf->score()->value())/2,
				 -annots => { ID => $parent_id,
					      is_problematic => $problematic,
					    },
			       );

    $_->add_Annotation('Parent',Bio::Annotation::SimpleValue->new(-value => $parent_id))
      foreach $af,$bf;

    $pf->remove_Annotations('Target');
    $pf->add_SeqFeature($_,'EXPAND') foreach sort {$a->start <=> $b->start} $af,$bf;
    push @features,$pf;
  }
  foreach my $r ((map [$_,0],@good_singles),
		 (map [$_,1],@problematic_singles),
		) {
    my ($s,$problematic) = @$r;
    my $type = $s->{p}{end} eq 'left' ? 'clone_start' : 'clone_end';
    my $sf = $self->_line_rec_to_feature( $type, $problematic, $s );
    push @features, $sf;
  }

  return @features;
}

sub _ideal_end_distance {
  my ($clone_type) = @_;

  if( $clone_type eq 'fosmid' ) {
    return {
	    plus_2sd => 45_000,
	    minus_2sd => 35_000,
	    avg => 40_000,
	   };
  } else {
    return {
	    plus_2sd => 160_000,
	    minus_2sd => 20_000,
	    avg => 90_000,
	   };
  }

  return;
}

sub _line_rec_to_feature {
  my ($self, $type, $problematic, $line) = @_;
  my ($qname, $hname, $percent_id, $hsp_len, $mismatches,$gapsm,
      $qstart,$qend,$hstart,$hend,$evalue,$bits) = @{$line->{fields}};

  if( $hstart > $hend ) {
    ($hend,$hstart) = ($hstart,$hend);
    ($qend,$qstart) = ($qstart,$qend);
  }

  return $self->new_feature( -start => $qstart,
			     -end   => $qend,
			     -score => $bits,
			     -type  => $type,
			     -source => $self->analysis_name,
			     -seq_id => $qname,
			     -target => { -start => $hstart,
					  -end   => $hend,
					  -target_id => $self->_target_name($hname),
					},
			     -annots => { ID => $self->_unique_bio_annotation_id("${qname}-${hname}"),
					  blast_percent_identity => $percent_id,
					  blast_mismatches => $mismatches,
					  blast_gaps => $gapsm,
					  blast_evalue => $evalue,
					  is_problematic => $problematic,
					},
			   );
}

sub _use_line {
  my ($self,$line) = @_;
  my ($qname,$hname, $percent_id, $hsp_len, $mismatches,$gapsm,
      $qstart,$qend,$hstart,$hend,$evalue,$bits) = split /\s+/,$line;
  return $percent_id > 98 && $mismatches < 10 && $gapsm <= 1;
}
sub _blastparams {
  -e => '1e-60', -p => 'blastn'
}


1;

