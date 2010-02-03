=pod

=head1 NAME

Bio::FeatureIO::geneseqer - FeatureIO parser for GeneSeqer reports

=head1 SYNOPSIS

  my $feature_in = Bio::FeatureIO->new(-format => 'geneseqer',
                                       -file   => 'myfile.geneseqer.out',
                                      );

  $feature_in->attach_alignments(1); #attach alignments to their AGSs

  $feature_in->mode('both_separate'); #parse both alignments and PGLs from the
                                      #report

  while(my $feat = $feature_in->next_alignment) {
    #do something with alignment feature
  }

  while(my $feat = $feature_in->next_feature) {

    #get the alignment objects attached to the PGL feature
    my @alignments =
      map {
	$_->value
      } $feat->annotation->get_Annotations('supporting_alignment');

    foreach my $alignment (@alignments) {
      # $alignment is now a feature representing one of the EST
      # alignments used to compute this PGL
    }

  }


=head1 DESCRIPTION

Parses GeneSeqer reports, returning L<Bio::SeqFeature::Annotated>
objects.  Alignments are represented by a
L<Bio::SeqFeature::Annotated> object with a 'Target' annotation,
holding a L<Bio::Annotation::Target> object.  PGLs are also
L<Bio::SeqFeature::Annotated> objects.

The mode() accessor controls the parsing mode, which is one of:

=over 4

=item 'pgls'

Only predicted gene location (PGL) features will be parsed and
returned.  Supporting alignments in the file will be ignored.

=item 'alignments'

Only supporting EST/protein alignments will be returned, PGLs will be
ignored.

=item 'both_separate'

Both PGLs and alignments will be parsed.  next_feature() will return
PGLs only, and next_alignment() will return the alignments

=item 'both_merged'

Both PGLs and alignments will be parsed.  next_feature() will return
B<both> PGLs and alignments.  next_alignment will always return undef

=back

If the parse mode is set to 'both_separate' or 'both_merged', you can
also set the accessor attach_alignments() to have the supporting
alignment features attached to the AGS features in which they are
used.  These are attached under the Annotation key/tag
'supporting_alignment'.  This is off by default.

In the future, this module may be enhanced to have the capability of
producing L<Bio::SeqFeature::Generic> and
L<Bio::SeqFeature::FeaturePair> objects.

=head1 STRUCTURE OF RETURNED FEATURES

This module returns a bunch of hierarchical features (that is, the
features have subfeatures) that represent the GeneSeqer output.  The
feature hierarchy for PGLs is arranged as:

  region                    - the GeneSeqer predicted gene location (PGL)
   |- processed_transcript  - each alternative gene structure (AGS) in the PGL
   |  |- CDS                - each exon in that AGS
      |- (optional) match           - alignment, see below
                     |- match_part

and for alignments it is

  match          - spliced alignment of an EST/protein to the ref seq
   |- match_part - each exon in the spliced alignment

Note that the alignments (match and match_part features) will only be
attached to the gene features if attach_alignments() is set to true.

=head1 REDUCING MEMORY REQUIREMENTS

If you find yourself running out of memory while parsing large
GeneSeqer output files with this parser, there are a couple of things
you can do to decrease the memory requirements:

  1.  do not use the 'both_separate' parsing mode, since it can sometimes
      need to keep a large buffer of features in memory
  2.  make sure attach_alignments() is set to false (0 or '')

If these two measures are not adequate for you, please explain your
problem on the mailing list, and we may be able to address your
situation.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org              - General discussion
  http://bioperl.org/MailList.shtml  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via
the web:

  http://bugzilla.bioperl.org/

=head1 AUTHOR

 Robert Buels, rmb32@cornell.edu

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut

# Let the code begin...

package Bio::FeatureIO::geneseqer;
use strict;

use base qw(Bio::FeatureIO);

use Bio::SeqFeature::Annotated;

=head2 new()

  constructor options for this parser are:

  -mode
     takes same arguments as mode() accessor below
  -attach_alignments
     takes same arguments as attach_alignments() accessor below

=cut

sub _initialize {
  my($self,%arg) = @_;

  $self->SUPER::_initialize(%arg);

  #init buffers
  $self->{alignment_buffer} = [];
  $self->{feature_buffer} = [];

  #set defaults
  $arg{-mode} ||= 'pgls';
  $arg{-attach_alignments} = 0 unless defined $arg{-attach_alignments};

  #set options
  $self->mode($arg{-mode});
  $self->attach_alignments($arg{-attach_alignments});
}

=head2 mode()

  Usage: $fio->mode('alignments');
         #parse and return only alignments
  Desc : get/set the current parsing mode. Defaults to
         'pgls'
  Ret  : currently set parse mode
  Args : (optional) new parse mode, which is one of 'pgls',
         'alignments', 'both_separate', or 'both_merged'

=cut

sub mode {
  my ($self,$newmode) = @_;
  if(defined $newmode) {
    grep {$_ eq $newmode} qw/alignments pgls both_separate both_merged/
      or $self->throw("invalid mode selection $newmode");
    $self->{parse_mode} = $newmode;
  }
  return $self->{parse_mode};
}

=head2 attach_alignments()

  Usage: $fio->attach_alignments(1);
  Desc : get/set a flag telling the parser whether to attach
         the supporting alignment features to each AGS (gene
         feature) returned.
         Off by default.
         Attaches the alignments under a tag/Annotation
         named 'supporting_alignment'.
  Ret  : current value of this flag.
  Args : (optional) new true/false value of this flag

=cut

sub attach_alignments {
  my ($self,$newval) = @_;
  if(defined $newval) {
    $self->{attach_alignments} = $newval;
  }
  return $self->{attach_alignments};
}

=head2 next_feature()

 Usage   : my $feature = $featureio->next_feature();
 Function: reads the next Predicted Gene Location from the given
           geneseqer file, returning it as an object.  The PGLs
           will be returned in the same order in which they appear
           in the GeneSeqer output.
 Returns : a predicted gene location (PGL) feature, of class
           L<Bio::SeqFeature::Annotated>
 Args    : none

=cut

# next_feature
#    return 'pgl/alignment' if in buffer
#    else buffer 'pgl/alignment' and return it
sub next_feature {
  my ($self,$featuretype) = shift;
  $featuretype ||= 'pgl';

  #validate attach_alignments and mode selections
  if( $self->attach_alignments && $self->mode !~ /^both/ ) {
    $self->throw("mode must be set to 'both_merged' or 'both_separate' if attach_alignments() is set to true");
  }

  return $self->next_alignment if $featuretype eq 'alignment';

  $self->throw("invalid featuretype '$featuretype'") unless $featuretype eq 'pgl';

  #now down to business

  #get a pgl into the buffer if necessary
  unless( @{$self->{feature_buffer}} ) {
    $self->_buffer_item($self->mode eq 'both_merged' ? 'either' : 'pgl');
  }

  return shift @{$self->{feature_buffer}};
}

=head2 next_alignment()

  Usage: my $feature = $fio->next_alignment
  Desc : get the next EST/protein alignment feature from the
         GeneSeqer report.  The alignments will be returned in
         the same order in which they appear in the file.
  Ret  : an alignment feature, or undef if there are no more
  Args : none

=cut

# next_alignment
#    alias for next_feature('alignment')
sub next_alignment {
  my ($self) = @_;

  #validate attach_alignments and mode selections
  if( $self->attach_alignments && $self->mode !~ /^both_/ ) {
    $self->throw("mode must be set to 'both_separate' or 'both_merged' if attach_alignments() is set to true");
  }

  #get an alignment into the buffer if necessary
  unless( @{$self->{alignment_buffer}} ) {
    $self->_buffer_item('alignment');
  }

  return shift @{$self->{alignment_buffer}};
}

=head2 write_feature()

Not implemented.

=cut

sub write_feature {
  shift->throw_not_implemented;
}

#central repository for match patterns
sub _pattern {
  my ($self,$patname) = @_;
  my %patterns =
    (
     pgl      => qr/^\s*PGL\s+\d+\s+\(/,
     ags      => qr/^\s*AGS-\d+\s/,
     sequence => qr/^\s*Sequence\s+\d+\s*:\s+(.+),\s+from/,
     align    => qr/^\s*\*{10}/,
     finished => qr/^[^A-Za-z]+finished\s/,
    );
  return $patterns{$patname};
}

# buffer_item (central parsing loop)
#    read from file.  if mode says we're using it, parse the thing and buffer it.
#                     otherwise, **skip** it
#    return 1 when you finally buffer a thing of the type your arg says you're looking for
#    return 0 if EOF
sub _buffer_item {
  my ($self,$requested_type) = @_;
  grep {$requested_type eq $_} qw/ alignment pgl either /
    or $self->throw("invalid requested type '$requested_type'");

  ### MAIN PARSING LOOP detects the beginnings of sections, pushes
  # them back on the buffer, then calls the appropriate parsing
  # routine for them.  returns only if a.) it successfully finds and
  # parses an item of the requested type or b.) it reaches EOF
  while( my $line = $self->_readline ) {
#     chomp $line;
#     warn "decide line $.: $line\n";
    #ifs are sorted in decreasing order of how common a case they are
    if(    $self->mode ne 'pgls'       &&  $line =~ $self->_pattern('align') ) {
      $self->_pushback($line);
      $self->_buffer_alignment;
      return 1 if $requested_type eq 'alignment' || $requested_type eq 'either';
    }

    elsif( $self->mode ne 'alignments' && $line =~ $self->_pattern('pgl')   ) {
      $self->_pushback($line);
      $self->_buffer_pgl;
      return 1 if $requested_type eq 'pgl' || $requested_type eq 'either';
    }

    elsif( $line =~ $self->_pattern('sequence') ) {
      $self->_pushback($line);
      $self->_purge_alignment_index;
      $self->_parse_sequence_section;
    }
  }
}

# buffer_alignment
#    assumes starting at the beginning of alignment section.
#    parse the alignment section, and put the alignment feature in the alignment buffer
#    if we're attaching, also index the alignment by its signature

#parse an 'EST sequence' section of the report, up to and
#including the '^MATCH ' line, returning a feature with
#subfeatures representing the spliced cDNA alignment
sub _buffer_alignment {
  my ($self) = @_;

  my $buffer_for_alignments = $self->mode eq 'both_merged'
    ? $self->{feature_buffer}
    : $self->{alignment_buffer};

  #these uninitialized variables are filled in by the parsing below
  my $parent_feature;
  my @subfeatures;

  my $cstrand; #strandedness of the EST we're currently looking at, either '+' or '-'
  my $cid; #identifier of the EST we're looking at
  my $clength; #length of the EST we're looking at

  my %patterns = (
		  hqpgs   => qr/^\s*hqPGS_(\S+_\S+[+-])/,
		  est_seq => qr/^\s*EST\s+sequence\s+\d+\s+([+-])\s*strand\s+(?:(\d+)\s+n\s+)?\(\s*File:\s*([^\)\s]+)\s*\)/,
		  exon    => qr/^\s+Exon\s/,
		  match   => qr/^MATCH/,
		  seqline => qr/^\s+(\d+)\s+([ACTG ]+)/,
		 );

  while( my $line = $self->_readline ) {
#     chomp $line;
#     warn "cdna parsing '$line'\n";
    #EST sequence introduction
    if( $line =~ $patterns{est_seq} ) {
#      warn "cdna est line\n";
      #parse out the strand, length, and ID of the EST we're dealing with,
      #storing them in the lexicals above
      $cstrand = $1;
      $cid = $3;
      $clength = $2;
      $cstrand eq chop $cid or $self->throw("inconsistent strandedness in line '$line'");
      $cstrand = $cstrand eq '+' ?  1 :
                 $cstrand eq '-' ? -1 : $self->throw("Unknown strand direction '$cstrand'");

      #do a little error checking
      $cid or $self->throw("can't parse sequence identifier from line '$line'");
      $cstrand == 1 or $cstrand == -1 or $self->throw("can't parse EST alignment strand from line '$line'");
    }
    #try to figure out the est's length from the sequence lines
    #if it wasn't given in the 'EST sequence' line
    elsif( $line =~ $patterns{seqline} ) {
      my $startlength = $1;
      my $residues = $2;
      $residues =~ s/\s//g;
      my $newlength = $startlength + length($residues) - 1;
      unless($clength >= $newlength) {
	$clength = $newlength;
# 	chomp $line;
# 	warn "faked up clength $clength from line '$line'\n";
      }
    }
    #Exon line
    elsif( $line =~ $patterns{exon} ) {
      #parse out the genomic and cDNA start,end,length, and the score of the match
      my (undef,$gstart,$gend,undef,$cstart,$cend,undef,$exon_score)
	= _parse_numbers($line);

      #if we're looking at a reverse-complemented EST, un-reverse-complement its start and end coordinates
      unless($cstrand == 1) {
	$cstrand == -1 or $self->throw("invalid strandedness '$cstrand'");
	$clength > 0 or $self->throw("can't parse EST length from line '$line'");
	($cstart,$cend) = _reverse_complement_coords($cstart,$cend,$clength);
      }

      my $subfeature =  $self->_new_feature( -start  => $gstart,
					     -end    => $gend,
					     -score  => $exon_score,
					     -type   => 'match_part',
					     -source => 'GeneSeqer',
					     -target => { -target_id => $cid,
							  -start     => $cstart,
							  -end       => $cend,
							  -strand    => $cstrand,
							},
					   ); #note: we'll go through
                                              #and set the seq_id
                                              #later, when we get it
                                              #from the MATCH line
      push @subfeatures,$subfeature;
    }
    #MATCH line
    elsif( $line =~ $patterns{match} ) {
      my (undef,$genomic_seqname,$cdna_seqname,$alignment_score) = split /\s+/,$line;
      my $gstrand = _chop_strand(\$genomic_seqname);
      my $other_cstrand = _chop_strand(\$cdna_seqname);
      $cstrand eq $other_cstrand or $self->throw("inconsistent cDNA strandedness: $cstrand vs $other_cstrand");

      #go back over the subfeatures and error check, figure out the
      #parent feature start and end, and set the appropriate seq_id on
      #each subfeature
      my $gstart;
      my $gend;
      foreach my $subfeature (@subfeatures) {
	#check that the strandedness is correct
	$subfeature->strand eq $gstrand or $self->throw("parser bug, inconsistent strands found ('".$subfeature->strand."' vs '$gstrand')");
	#set the proper seq_id
	$subfeature->seq_id($genomic_seqname);
	#set parent feature limits
	$gstart = $subfeature->start unless $gstart && $gstart < $subfeature->start;
	$gend = $subfeature->end unless $gend && $gend > $subfeature->end;
      }

      #make an overall feature for this EST alignment
      $parent_feature = $self->_new_feature( -start  => $gstart,
					     -end    => $gend,
					     -seq_id => $genomic_seqname,
					     -source => 'GeneSeqer',
					     -score  => $alignment_score,
					     -strand => $gstrand,
					     -type   => 'match',
					   );

      #add all the subfeatures to it, reversing so they'll come out in the right order
      $parent_feature->add_SeqFeature($_) foreach @subfeatures;
    }
    elsif( $line =~ $patterns{hqpgs} ) {

      #do some consistency checks with the contents of the PGS line
      my (undef,$other_cid) = split /_/, $1;

      if( $self->attach_alignments ) {
	#now make the pgs signature string, and return it with the parent feature we made
	my (undef,@pgs_stuff) = split /\s+/,$line;

	#$pgs_signature a string GeneSeqer uses to uniquely identify
	#this alignment.  We'll use these later to connect the PGLs to
	#their supporting alignments
	my $pgs_signature = join(' ',@pgs_stuff,$other_cid);
	#      $parent_feature->add_Annotation('comment',Bio::Annotation::Comment->new(-text => $pgs_signature));
	$self->_index_alignment($pgs_signature,$parent_feature);
      }

      $parent_feature or $self->throw("parse error");

      push @$buffer_for_alignments, $parent_feature;
      return;
    }
  }
}

#parse the section of the report introducing the processing of a new
#genomic sequence.  right now, just par
sub _parse_sequence_section {
  my ($self) = @_;
  my $line = $self->_readline;

  #parse the sequence identifier out of the line
  $line =~ $self->_pattern('sequence')
    or $self->throw("improper call of _parse_sequence_section, line '$line' does not match expected pattern");

#  warn "got new seq $1\n";

  #store the sequence identifier in the current object.
  #_new_feature() uses this as the seq_id to return
  $self->{current_genomic_sequence} = $1
    or $self->throw("improper 'sequence' pattern in geneseqer parser.  it does not capture the sequence identifier from the Sequence line in \$1");
}

# buffer_pgl
#    assumes starting at the beginning of pgl section
#    parse the pgl section, put the pgl feature in the pgl buffer
#    if attach_alignments() is set, remember to attach the associated
#    alignments, getting them from the alignment index
sub _buffer_pgl {
  my $self = shift;

  while(my $line = $self->_readline) {
    chomp $line;
#    warn "pgl parse $.: $line\n";
    if( $line =~ $self->_pattern('pgl')) {
#      warn $line;
      my (undef,$pgl_start,$pgl_end) = _parse_numbers($line);
      my @ags; # list of AGSs in the current PGL.  filled in by the
               # parsing below
      my %alignments; #this is a hash by signature of alignments that
                      #are members of this PGL
      while( $line = $self->_readline) {
	if( $line =~ $self->_pattern('ags') ) {
#	  warn $line;
	  my ($ags_start) = $line =~ /\(\s*(\d+)/ or $self->throw("parse error");
	  my ($ags_end)   = $line =~ /(\d+)\s*\)/ or $self->throw("parse error");
	  my %subfeatures = $self->_parse_ags_subfeatures;

	  push @ags,$self->_new_feature( -start => $ags_start,
					 -end   => $ags_end,
					 -type  => 'processed_transcript',
					 -subfeatures => $subfeatures{exon_features},
					 supporting_alignments => $subfeatures{alignment_features},
				       );
	}
	elsif( $line =~ $self->_pattern('pgl') || $line =~ $self->_pattern('finished')) {
	  $self->_pushback($line);
	  last;
	}
      }

      @ags or $self->throw("no ags found for pgl.  premature end of file?");

      push @{$self->{feature_buffer}},
	$self->_new_feature( -start  => $pgl_start,
			     -end    => $pgl_end,
			     -type   => 'region',
			     -subfeatures => [@ags, values %alignments],
			   );
      return;
    }
  }
  $self->throw("parse error, cannot find end of PGL section");
}

#parse a single AGS entry, making subfeatures for their exons, etc
#return a hash-style list as exon_features => [feat,feat...],
# alignment_features => { signature => feat, signature => feat, ...},
sub _parse_ags_subfeatures {
  my ($self) = @_;

  #these variables are all filled in by the parsing below
  my @exon_features;
  my @supporting_alignment_features;

  while( my $line = $self->_readline ) {
    if( $line =~ /^\s*Exon\s/ ) {
      my (undef,$gstart,$gend,undef,$exon_score) = _parse_numbers($line);
      push @exon_features, $self->_new_feature( -start => $gstart,
						-end   => $gend,
						-score => $exon_score,
						-type  => 'CDS',
					      );
    }
   elsif( $line =~ /^\s*PGS\s+\(/ ) {
     if( $self->attach_alignments ) {
     #parse all the PGS's and then break out of the while loop above when done
       do {
	 my (undef,@pgs_tokens) = grep {$_} (split /\s+/,$line);
	 # 	use Data::Dumper;
	 # 	die "got tokens: ",Dumper(\@pgs_tokens);
	 my $pgs_sig = join ' ',@pgs_tokens;
	 push @supporting_alignment_features,$self->_get_indexed_alignment($pgs_sig)
	   || $self->throw("geneseqer parse error: no supporting alignment found with signature '$pgs_sig', line was '$line'");
       } while ( $line = $self->_readline and $line =~ /^\s*PGS\s+\(/ );

       $self->_pushback($line);

       #after the supporting PGS's, we are done parsing this AGS
     }
     last;
   }
  }

  return ( exon_features      =>  \@exon_features,
	   alignment_features =>  \@supporting_alignment_features,
	 );
}

#object method to create a new feature object, with some defaults and
#automation of the more repetitive bits (like adding targets and
#subfeatures)
sub _new_feature(@) {
  my ($self,%a) = @_;

#   use Data::Dumper;
#   warn "got feature: ",Dumper(\%a);

  $a{-seq_id} ||= $self->{current_genomic_sequence};

  #replace spaces in source with underscores
  $a{-source} ||= 'GeneSeqer';
  $a{-source} =~ s/\s+/_/g;

  #if no strand is given, make the proper strand and flip start and end if necessary
  @a{qw/-start -end -strand/} = _start_end_strand(@a{qw/-start -end/}) unless $a{-strand};

  #do some type mapping
  my %type_map = ( similarity => 'nucleotide_motif',
		   exon       => delete($a{is_alignment}) ? 'match_part' : 'exon',
		 );
  $a{-type} =  $type_map{ $a{-type}} || $a{-type};

  #intercept target if present
  my $target = do {
    if(my $t = delete $a{target}) {
      unless( $t->{-strand} ) {
	@{$t}{qw/-start -end -strand/} = _start_end_strand(@{$t}{qw/-start -end/});
      }

      #HACK fix up target ids for geneseqer alignments
      if( $t->{-target_id} =~ s/([+-])$//) {
	$t->{-strand} = $1;
      }

      Bio::Annotation::Target->new(%$t);
    }
  };
  my $feature = Bio::SeqFeature::Annotated->new(%a);
  $feature->add_Annotation('Target',$target) if $target;
  $feature->add_Annotation('ID',Bio::Annotation::SimpleValue->new( -value => $a{id} ) ) if $a{id};
  if( ref $a{supporting_alignments} eq 'ARRAY' ) {
    foreach ( @{$a{-subfeatures}} ) {
      $feature->add_Annotation('supporting_alignment',Bio::Annotation::SimpleValue->new( -value => $_ ));
#      $feature->add_Annotation('Parent',Bio::Annotation::SimpleValue->new( -value => $_ ));
    }
  }
  return $feature;
}


#object method that, given two (one-based) coordinates on a sequence
#and its length, returns the reverse complement of the coordinates in
#a two-element list
sub _reverse_complement_coords {
  my ($s,$e,$l) = @_;
  return ( $l-$e+1, $l-$s+1 );
}

#make a gff3-compliant feature start, end, and strand
#from a gamexml-style start and end that might be backwards
sub _start_end_strand(@) {
  my ($start,$end) = @_;
  if($start > $end) {
    return ($end,$start,-1);
  } else {
    return ($start,$end,1);
  }
}

#extract all the (possibly fractional) numbers from a line of text,
#return them as a list
sub _parse_numbers {
  my ($line) = @_;
  my @nums;
  while( $line =~ /(\d+(?:\.\d+)?)/g ) {
    push @nums, $1;
  }
  return @nums;
}

# lookup_alignment
# get_alignment
# purge_alignments
sub _index_alignment {
  my ($self,$key,$feature) = @_;
#  warn "indexing with '$key'\n";
  $self->{alignment_features}{$key} = $feature;
}
sub _purge_alignment_index {
  shift->{alignment_features} = {};
}
sub _get_indexed_alignment {
  my ($self,$key) = @_;
  return $self->{alignment_features}{$key};
}

#chop the strand (+ or -) off of a seq name and return it as 1 for +
#or -1 for - note that this has the side effect of modifying the value
#of the thing that's passed to it
sub _chop_strand {
  my ($ident) = @_;
  my $strand = chop $$ident;
  if( $strand eq '+' ) {
    return 1;
  }
  elsif( $strand eq '-' ) {
    return -1;
  }
  die "Invalid strand '$strand' at end of identifier '$$ident$strand'";
}

###
1;# do not remove
###

