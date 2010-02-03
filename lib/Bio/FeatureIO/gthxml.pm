=pod

=head1 NAME

Bio::FeatureIO::gthxml - FeatureIO parser for GenomeThreader XML reports

=head1 SYNOPSIS

  my $feature_in = Bio::FeatureIO->new(-format => 'gthxml',
                                       -file   => 'myfile.gth.xml',
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

Parses GenomeThreader XML reports, returning L<Bio::SeqFeature::Annotated>
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
ignored, meaning only next_alignment() will work, next_feature() will
return nothing.

=item 'both_separate'

Both PGLs and alignments will be parsed.  next_feature() will return
PGLs only, and next_alignment() will return the alignments

=item 'both_merged'

Both PGLs and alignments will be parsed.  next_feature() will return
B<both> PGLs and alignments.  next_alignment will always return undef

=item 'alignments_merged'

Like 'alignments', except the alignments come out of next_feature()
instead of next_alignment()

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
features have subfeatures) that represent the GenomeThreader output.
The feature hierarchy for PGLs is arranged as:

  gene                       - the PGL
   |- mRNA - each alternative gene structure (AGS) in the PGL
       |- five_prime_UTR (only present if there is one)
       |- exon    - each exon in that AGS
       |- CDS     - coding sequences in that AGS
       |- three_prime_UTR (only present if there is one)
       |- (optional) match     - included if attach_alignments is on
                      |- match_part

and for alignments it is

  match          - spliced alignment of an EST/protein to the ref seq
   |- match_part - each exon in the spliced alignment

Note that the alignments (match and match_part features) will only be
attached to the gene features if attach_alignments() is set to true.
Attaching the aligments to the gene features requires keeping all of
the alignments in memory, and if you're parsing a very large
GenomeThreader report, that may not be possible.  Therefore,
attach_alignments() defaults to off().

=head1 REDUCING MEMORY REQUIREMENTS

If you find yourself running out of memory while parsing large
GenomeThreader output files with this parser, there are a couple of things
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

package Bio::FeatureIO::gthxml;
use strict;
use English;

use base qw(Bio::FeatureIO);

use XML::Twig;

use Bio::SeqFeature::Annotated;
use Bio::Annotation::Target;

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


  my $alignment_buffer = $self->mode eq 'both_merged' || $self->mode eq 'alignments_merged'
    ? $self->{feature_buffer}
    : $self->{alignment_buffer};
  my @spliced_alignment_twig = $self->mode eq 'pgls'
    ? ()
    : (spliced_alignment => sub {
	 push @$alignment_buffer,
	   $self->_parse_alignment(@_);
	 shift->purge;
       });
  my @pgl_twig  = $self->mode eq 'alignments' || $self->mode eq 'alignments_merged'
    ? ()
    : (predicted_gene_location => sub {
	 push @{$self->{feature_buffer}},
	   $self->_parse_pgl(@_);
	 shift->purge;
       });

  #now parse the entire input file, buffering pgls and alignments
  eval {
    XML::Twig->new( twig_roots =>
		    {
		     @spliced_alignment_twig,
		     @pgl_twig,
		    }
		  )->parse($self->_fh);
  };
  if( $EVAL_ERROR ) {
    $self->throw("error parsing GTH XML file '".$self->file."': $EVAL_ERROR");
  }

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
    grep {$_ eq $newmode} qw/alignments pgls both_separate both_merged alignments_merged/
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
 Function: returns the next available feature, which is either a PGL
           or an alignment, depending on mode() (see above).  Features
           will be returned in the same order as they appear in the file.
 Returns : a predicted gene location (PGL) feature, of class
           L<Bio::SeqFeature::Annotated>
 Args    : none

=cut

# next_feature
#    return 'pgl/alignment' if in buffer
#    else buffer 'pgl/alignment' and return it
sub next_feature {
  my ($self,$featuretype) = @_;
  $featuretype ||= 'pgl';

  $self->_validate_settings;

  return $self->next_alignment if $featuretype eq 'alignment';

  $self->throw("invalid featuretype '$featuretype'") unless $featuretype eq 'pgl';

  return shift @{$self->{feature_buffer}};
}

=head2 next_alignment()

  Usage: my $feature = $fio->next_alignment
  Desc : get the next EST/protein alignment feature from the
         GenomeThreader report.  The alignments will be returned in
         the same order in which they appear in the file.
  Ret  : an alignment feature, or undef if there are no more
  Args : none

=cut

# next_alignment
#    alias for next_feature('alignment')
sub next_alignment {
  my ($self) = @_;

  $self->_validate_settings;

  return shift @{$self->{alignment_buffer}};
}

sub _validate_settings {
  my $self = shift;
  #validate attach_alignments and mode selections
  if( $self->attach_alignments && $self->mode !~ /^both_/ ) {
    $self->throw("mode must be set to 'both_separate' or 'both_merged' if attach_alignments() is set to true");
  }
}

=head2 write_feature()

Not implemented.

=cut

sub write_feature {
  shift->throw_not_implemented;
}

#given the featureio object, an XML::Twig object, and an XML::Twig
#element representing a <spliced_alignment> element, make a
#feature for this alignment
sub _parse_alignment {
  my ($self,$twig,$element) = @_;

  ### parse out some basic things about the main alignment
  my $matchline  = $element->first_descendant('MATCH_line');
  my ($seq_id,$target_id) = map {$matchline->att($_)} qw/gen_id ref_id/;
  my $score = $matchline->first_child('total_alignment_score')->text;

  ### get the strandedness w.r.t. the reference seq
  my $rstrand = $element->first_child('reference')->att('ref_strand');

  #make features for all the sub-alignments
  my @rstarts;
  my @rends;
  my ($start,$end);
  my @subfeats = map {
    my $gen = $_->first_child('gDNA_exon_boundary');
    my $ref = $_->first_child('reference_exon_boundary');
    my ($gstart,$gend,$gstrand) = _start_end_strand($gen->att('g_start'), $gen->att('g_stop'));
    my ($rstart,$rend) = ($ref->att('r_start'), $ref->att('r_stop'));
    push @rstarts,$rstart; push @rends,$rend;
    my $subscore = $ref->att('r_score');
    $start = $gstart if ! defined $start || $start > $gstart;
    $end = $gend if ! defined $end || $end < $gend;
    $self->_new_feature( -start  => $gstart, -end => $gend, -strand => $gstrand, -score => $subscore,
			 -seq_id => $seq_id,
			 -type   => 'match_part',
			 -target => { -target_id => $target_id,
				      -start     => $rstart, -end => $rend, -strand => $rstrand,
				    },
		       );
  } $element->first_child('predicted_gene_structure')->first_child('exon-intron_info')->children('exon');

  my $strand = $subfeats[0]->strand;

  #now make the main alignment
  my $alignment = $self->_new_feature( -start  => $start, -end => $end, -strand => $strand,
				       -score  => $score,
				       -seq_id => $seq_id,
				       -type   => 'match',
				       -target  => { -target_id => $target_id,
						     -start     => (sort {$a<=>$b} @rstarts)[0],
						     -end       => (sort {$b<=>$a} @rends)[0],
						     -strand    => $rstrand,
						   },
				       -subfeatures => \@subfeats,
				     );

  #if we're attaching alignments to the PGLs that use them,
  #index this alignment for later use
  if( $self->attach_alignments ) {
    my $pgs_sig = $self->_pgs_line_to_sig($element->first_descendant('PGS_line'));
    $self->_index_alignment($pgs_sig,$alignment);
  }

  return $alignment;
}

#given a <PGS_line> element and an optional ID of the genomic sequence
#we're looking at, either from a PGL or an alignment section, parse it
#and return a string that can serve as the unique key for a hash of
#alignments
sub _pgs_line_to_sig {
  my ($self,$pgsline_element,$genomic_id) = @_;
  my $ref_id = do {
    if(my $elem = $pgsline_element->first_child('rDNA')) {
      $elem->att('rDNA_id')
    }
    elsif($elem = $pgsline_element->first_child('referenceDNA') ) {
      $elem->att('id')
    }
  };
  $genomic_id ||= ($pgsline_element->first_child('gDNA') or $self->throw('parse error'))->att('gen_id');
  return join ',',
    ( $ref_id,
      $genomic_id,
      map {
	( $_->att('e_start') || $_->att('start'),
	  $_->att('e_stop') || $_->att('stop'),
	)
      } $pgsline_element->descendants('exon'),
    );
}

#given the featureio object, the twig object, and a twig element for a
#<predicted_gene_location>, make a feature and subfeatures for that
#pgl
sub _parse_pgl {
  my ($self,$twig,$element) = @_;

  my @subfeats = map {
    $self->_parse_ags($twig,$_);
  } $element->children('AGS_information');

  return () unless @subfeats;

  #parse out the start, end, and strand of this PGL
  my ($start,$end,$strand) = do {
    my $pgl_line = $element->first_child('PGL_line');
    map {$pgl_line->att($_)} qw/PGL_start PGL_stop PGL_strand/;
  };
  my $strand2;
  ($start,$end,$strand2) = _start_end_strand($start,$end);
  $strand2 = $strand2 == 1 ? '+' : $strand2 == -1 ? '-' : $self->throw("invalid strand $strand2");
  $strand2 eq $strand or $self->throw("parsing consistency error ('$strand' vs '$strand2'");

  my $pgl_feature =  $self->_new_feature( -start  => $start,
					  -end    => $end,
					  -strand => $strand,
					  -seq_id => $subfeats[0]->seq_id,
					  -type   => 'gene',
					  -subfeatures => \@subfeats,
					);
  if( $self->attach_alignments ) {
    foreach my $pgsline ($element->first_descendant('supporting_evidence')->children('PGS_line')) {
      #use the <PGS_line> to look up the alignment features that were
      #used for this, and attach them to this feature
      my $pgs_sig = $self->_pgs_line_to_sig($pgsline,$subfeats[0]->seq_id);
      my $alignment_feature = $self->_get_indexed_alignment($pgs_sig)
	or $self->throw("parse error, cannot look up alignment with signature '$pgs_sig', available sigs are\n".join("\n",keys %{$self->{alignment_features}}));
      $pgl_feature->add_Annotation('supporting_alignment',
				   Bio::Annotation::SimpleValue->new( -value => $alignment_feature ),
				  );
    }
  }
  return $pgl_feature;
}

sub _parse_ags {
  my ($self,$twig,$element) = @_;


  my $seq_id = do {
    if(my $gdna = $element->first_descendant('gDNA')) {
      $gdna->att('id');
    }
    elsif($gdna = $element->first_descendant('none')) {
      $gdna->att('gDNA_id');
    }
  };
  unless($seq_id) {
    $self->warn('WARNING: could not determine genomic sequence ID for AGS with no probable_ORFs.  This XML output issue is fixed in genomethreader 0.9.54 and later, please consider upgrading.');
    return ();
  }


  my @exons = map {
    my $e = $_;
    my $boundary = $e->first_child('gDNA_exon_boundary');
    my ($start,$end,$strand) = _start_end_strand($boundary->att('e_start'), $boundary->att('e_stop'));
    my $score = $e->att('e_score');
    $self->_new_feature( -start => $start, -end => $end, -strand => $strand,
			 -score => $score,
			 -seq_id=>$seq_id,
			 -type => 'exon',
		       );
  } $element->first_child('exon-intron_info')->children('exon');

  my ($start,$end,$strand) = do {
    my $coords = $element->first_child('AGS_line')->first_child('exon_coordinates');
    _start_end_strand( $coords->first_child('exon')->att('e_start'),
		       $coords->last_child('exon')->att('e_stop'),
		     )
  };

  return $self->_new_feature( -start  => $start,
			      -end => $end,
			      -strand => $strand,
			      -seq_id => $seq_id,
			      -type   => 'mRNA',
			      -subfeatures => \@exons,
			    );
}

#object method to create a new feature object, with some defaults and
#automation of the more repetitive bits (like adding targets and
#subfeatures)
sub _new_feature(@) {
  my ($self,%a) = @_;

  UNIVERSAL::isa($self,__PACKAGE__)
      or die('_new_feature is an object method, silly');

#   use Data::Dumper;
#   warn "got feature: ",Dumper(\%a);

  $a{-seq_id} ||= $self->{current_genomic_sequence};

  #replace spaces in source with underscores
  $a{-source} ||= 'GenomeThreader';
  $a{-source} =~ s/\s+/_/g;

  #if no strand is given, make the proper strand and flip start and
  #end if necessary
  @a{qw/-start -end -strand/} = _start_end_strand(@a{qw/-start -end/}) unless $a{-strand};

  #do some type mapping
  my %type_map = ( similarity => 'nucleotide_motif',
		   exon       => delete($a{is_alignment}) ? 'match_part' : 'exon',
		 );
  $a{-type} =  $type_map{ $a{-type}} || $a{-type};

  #intercept target if present
  my $target = do {
    if(my $t = delete $a{-target}) {
      unless( $t->{-strand} ) {
	@{$t}{qw/-start -end -strand/} = _start_end_strand(@{$t}{qw/-start -end/});
      }

      #HACK fix up target ids for alignments
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

