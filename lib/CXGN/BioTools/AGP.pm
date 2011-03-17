package CXGN::BioTools::AGP;
use strict;
use warnings;
use English;
use Carp;

use File::Basename;

use Bio::PrimarySeq;
use Bio::Seq::LargePrimarySeq;
use Bio::SeqFeature::Annotated;

use CXGN::Tools::List qw/str_in/;
use CXGN::Tools::Identifiers qw/identifier_namespace/;
use CXGN::Tools::File qw/is_filehandle/;

=head1 NAME

CXGN::BioTools::AGP - functions for dealing with AGP files

=head1 SYNOPSIS

 $bio_large_seq = agp_to_seq($agp_file_name);

 $lines_arrayref = agp_parse('my_agp_file.agp');

 agp_write( $lines => 'my_agp_file.agp');

 $seq = agp_contig_seq( $mycontig,
                        fetch_bac_sequences => sub {...}
                       )

=head1 DESCRIPTION

functions for working with AGP files.

=head1 FUNCTIONS

All functions below are EXPORT_OK.

=cut

use base qw/ Exporter /;

our @EXPORT_OK;
BEGIN {
  @EXPORT_OK = qw(
                  agp_parse

                  agp_to_seq
                  agp_to_seqs

                  agp_write
                  agp_format_part

                  agp_contigs

                  agp_contig_seq

                  agp_to_features
                 );
}


=head2 agp_parse

  Usage: my $lines = agp_parse('~/myagp.agp',validate_syntax => 1, validate_identifiers => 1);
  Desc : parse an agp file
  Args : filename or filehandle, hash-style list of options as 
                       validate_syntax => if true, error
                           if there are any syntax errors,
                       validate_identifiers => if true, error
                          if there are any identifiers that
                          CXGN::Tools::Identifiers doesn't recognize
                          IMPLIES validate_syntax
                       error_array => an arrayref.  if given, will push
                          error descriptions onto this array instead of
                          using warn to print them to stderr
  Ret  : undef if error, otherwise return an
         arrayref containing line records, each of which is like:
         { comment => 'text' } if a comment,
         or if a data line:
         {  objname  => the name of the object being assembled
                       (same for every record),
            ostart   => start coordinate for this component (object),
            oend     => end coordinate for this component   (object),
            partnum  => the part number appearing in the 4th column,
            linenum  => the line number in the file,
            type     => letter type present in the file (/[ADFGNOPUW]/),
            typedesc => description of the type, one of:
                         - (A) active_finishing
                         - (D) draft
                         - (F) finished
                         - (G) wgs_finishing
                         - (N) known_gap
                         - (O) other
                         - (P) predraft
                         - (U) unknown_gap
                         - (W) wgs_contig
            ident    => identifier of the component, if any,
            length   => length of the component,
            is_gap   => 1 if the line is some kind of gap, 0 if it
                        is covered by a component,
            gap_type => one of:
                 fragment: gap between two sequence contigs (also
                    called a "sequence gap"),
                 clone: a gap between two clones that do not overlap.
  		 contig: a gap between clone contigs (also called a
  		    "layout gap").
  		 centromere: a gap inserted for the centromere.
  		 short_arm: a gap inserted at the start of an
  		    acrocentric chromosome.
  		 heterochromatin: a gap inserted for an especially
     		    large region of heterochromatic sequence (may also
  		    include the centromere).
  		 telomere: a gap inserted for the telomere.
  		 repeat: an unresolvable repeat.
            cstart   => start coordinate relative to the component,
            cend     => end coordinate relative to the component,
            linkage  => 'yes' or 'no', only set for type of 'N',
            orient   => '+', '-', 0, or 'na'
                        orientation of the component
                        relative to the object,
         }

  Side Effects: unless error_array is given, will print error
                descriptions to STDERR with warn()
  Example:

=cut

sub agp_parse {
  my $agpfile = shift;
  our %opt = @_;

  $agpfile or croak 'must provide an AGP filename';

  if($opt{validate_identifiers}) {
    $opt{validate_syntax} = 1;
  }

  #if the argument is a filehandle, use it, otherwise try to use it as
  #a filename
  my $agp_in; #< filehandle for reading AGP
  our $bn;    #< basename of file we're parsing
  ($agp_in,$bn) = do {
    if( is_filehandle($agpfile) ) {
      ($agpfile,'<AGP>')
    } else {
      open my $f,$agpfile
	or die "$! opening '$agpfile'\n";
      ($f,$agpfile)
    }
  };

  our $parse_error_flag = 0;
  sub parse_error(@) {

    return unless $opt{validate_syntax};

    $parse_error_flag = 1;
    my $errstr = "$bn:$.: ".join('',@_)."\n";
    #if we're pushing errors onto an error_array, do that
    if ($opt{error_array}) {
      push @{$opt{error_array}},$errstr;
    } else { # otherwise just warn
      warn $errstr;
    }
  }

  my @records;

  my $last_end;
  my $last_partnum;
  my $last_objname;

  my $assembled_sequence = '';
  while (my $line = <$agp_in>) {
    no warnings 'uninitialized';
#    warn "parsing $line";
    chomp $line;
    $line =~ s/\r//g; #remove windows \r chars

    #deal with comments
    if($line =~ /#/) {
      if( $line =~ s/^#// ) {
	push @records, { comment => $line };
	next;
      }
      parse_error("not a valid comment line, # must be first character on line");
      next;
    }

    my @fields = split /\t/,$line,10;
    @fields == 9
      or parse_error "This line contains ".scalar(@fields)." columns.  All lines must have 9 columns.";

    #if there just really aren't many columns, this probably isn't a valid AGP line
    next unless @fields >= 5 && @fields <= 10;

    my %r = (linenum => $.); #< the record we're building for this line, starting with line number

    #parse and check the first 5 cols
    @r{qw( objname ostart oend partnum type )} = splice @fields,0,5;
    $r{objname}
      or parse_error "'$r{obj_name}' is a valid object name";
    #end
    if ( defined $last_end && defined $last_objname && $r{objname} eq $last_objname ) {
      $r{ostart} == $last_end+1
	or parse_error "start coordinate not contiguous with previous line's end";
    }
    $last_end = $r{oend};
    $last_objname = $r{objname};

    #start
    $r{oend} >= $r{ostart} or parse_error("end must be >= start");

    #part num
    $last_partnum ||= 0;
    $r{partnum} == $last_partnum + 1
      or parse_error("part numbers not sequential");

    $last_partnum = $r{partnum};

    #type
    if ( $r{type} =~ /^[NU]$/ ) {
      (@r{qw( length gap_type linkage)}, my $empty, my $undefined) = @fields;
      @fields = ();
      my %descmap = qw/ U unknown_gap N known_gap /;
      $r{typedesc} = $descmap{$r{type}}
	or parse_error("unregistered type $r{type}");
      $r{is_gap}   = 1;

      my $gap_size_to_use = $opt{gap_length} || $r{length};

      $r{length} == $r{oend} - $r{ostart} + 1
	or parse_error("gap size of '$r{length}' does not agree with ostart, oend of ($r{ostart},$r{oend})");

      str_in($r{gap_type},qw/fragment clone contig centromere short_arm heterochromatin telomere repeat/)
	or parse_error("invalid gap type '$r{gap_type}'");

      str_in($r{linkage},qw/yes no/)
	or parse_error("linkage (column 8) should be 'yes' or 'no'\n");

      defined $empty && $empty eq ''
	or parse_error("9th column should be present and empty\n");

      push @records,\%r;

  } elsif ( $r{type} =~ /^[ADFGOPW]$/ ) {
      my %descmap = qw/A active_finishing D draft F finished G wgs_finishing N known_gap O other P predraft U unknown_gap W wgs_contig/;
      $r{typedesc} = $descmap{$r{type}}
	or parse_error("unregistered type $r{type}");
      $r{is_gap} = 0;

      @r{qw(ident cstart cend orient)} = @fields;
      if($opt{validate_identifiers}) {
	my $comp_type = identifier_namespace($r{ident})
	  or parse_error("cannot guess type of '$r{ident}'");
      } else {
	$r{ident} or parse_error("invalid identifier '$r{ident}'");
      }

      str_in($r{orient},qw/+ - 0 na/)
	or parse_error("orientation must be one of +,-,0,na");

      $r{cstart} >= 1 && $r{cend} > $r{cstart}
	or parse_error("invalid component start and/or end ($r{cstart},$r{cend})");

      $r{length} = $r{cend}-$r{cstart}+1;

      $r{length} == $r{oend} - $r{ostart} + 1
	or parse_error("distance between object start, end ($r{ostart},$r{oend}) does not agree with distance between component start, end ($r{cstart},$r{cend})");

      push @records, \%r;
    } else {
      parse_error("invalid component type '$r{type}', it should be one of {A D F G N O P U W}");
    }
  }

  return if $parse_error_flag;

  #otherwise, everything was well
  return \@records;
}


=head2 agp_write

  Usage: agp_write($lines,$file);
  Desc : writes a properly formatted AGP file
  Args : arrayref of line records to write, with the line records being
             in the same format as those returned by agp_parse above,
         filename or filehandle to write to,
  Ret :  nothing meaningful

  Side Effects: dies on failure.  if you gave it a filehandle, does
                not close it
  Example:

=cut

sub agp_write {
  my ($lines,$file) = @_;
  $file or confess "must provide file to write to!\n";

  my $out_fh = is_filehandle($file) ? $file
    : do {
      open my $f,">$file" or croak "$! opening '$file' for writing";
      $f
    };

  foreach my $line (@$lines) {
      print $out_fh agp_format_part( $line );
  }

  return;
}

=head2 agp_format_part( $record )

Format a single AGP part line (string terminated with a newline) from
the given record hashref.

=cut

sub agp_format_part {
    my ( $line ) = @_;

    return "#$line->{comment}\n" if $line->{comment};

    #and all other lines
    my @fields = @{$line}{qw(objname ostart oend partnum type)};
    if( $line->{type} =~ /^[NU]$/ ) {
      push @fields, @{$line}{qw(length gap_type linkage)},'';
    } else {
      push @fields, @{$line}{qw(ident cstart cend orient)};
    }

    return join("\t", @fields)."\n";
}


=head2 agp_contigs

  Usage: my @contigs = agp_contigs( agp_parse($agp_filename) );
  Desc : extract and number contigs from a parsed AGP file
  Args : arrayref of AGP lines, like those returned by agp_parse() above
  Ret  : list of contigs, in the same order as they occur in the
         file, formatted as:
            [ agp_line_hashref, agp_line_hashref, ... ],
            [ agp_line_hashref, agp_line_hashref, ... ],
            ...

=cut

sub agp_contigs {
  my $lines = shift;

  my @contigs = ([]);
  foreach my $l (@$lines) {
    next if $l->{comment};
    if( $l->{typedesc} =~ /_gap$/ ) {
      push @contigs,[] if @{$contigs[-1]};
    } else {
      push @{$contigs[-1]},$l;
    }
  }
  pop @contigs if @{$contigs[-1]} == 0;
  return @contigs;
}


=head2 agp_contig_seq

  Usage: my $seqs = agp_contig_seq($contig, %options);
  Desc : given a contig arrayref like those returned by agp_contigs,
         fetch the sequence
  Args : a contig arrayref like [agp_file_line, agp_file_line, ...],
         hash-style list of options like
           fetch_<ns> => sub { }
                          # function for fetching sequences
                          # in namespace <ns> as returned by
                          # CXGN::Tools::Identifiers::identifier_namespace
                          # MANDATORY for each kind of identifier present
                          #  in the agp file
                          # takes 1 arg, the identifier string, returns
                          # the sequence as a string
                          # if fetch_default
           lowercase   => 1,   #< force lower-case sequence,
                                  defaults to force uppercase
           pad_short_sequences => 0, #< if true, N-pad sequences that are too
                                     #  short to cover a region in the
                                     #  AGP file.  otherwise, die for
                                     #  seqs that are too short.
                                     #  default false.

  Ret  : a string sequence (not a Bio::SeqI object)
  Side Effects: calls the fetch_* functions you provide
  Example:

    #get the contigs for a chromosome
    my %contigs = named_contigs(4);
    #and now make all the consensus sequences
    my %sequences;
    while( my ($contig_name,$contig) = each(%contigs) ) {
      $sequences{$contig_name} = consensus_sequence($contig);
    }

=cut

sub agp_contig_seq {
  my ($members,%opt) = @_;

  my $seq = '';
  foreach my $member (sort {$a->{ostart} <=> $b->{ostart}} @$members) {
    my $comp_type = identifier_namespace($member->{ident}) || 'default';
    my $fetch_func = $opt{"fetch_$comp_type"}
      or croak "cannot fetch sequence for $member->{ident} in namespace $comp_type, please provide a fetch_$comp_type, or check that this is the correct namespace";
    my $comp_seq = $fetch_func->($member->{ident})
      or croak "failed to fetch sequence for '$member->{ident}'";

    unless( length($comp_seq) >= $member->{cstart}-1+$member->{length}) {
      if( $opt{pad_short_sequences} ) {
	my $pad_length = ($member->{cstart}-1+$member->{length}) - length($comp_seq);
	$comp_seq .= 'N'x$pad_length;
      } else {
	die "making object $member->{objname}: invalid coordinates (start $member->{cstart},length $member->{length}) for $member->{ident} (".length($comp_seq)." bases)";
      }
    }
    $comp_seq = substr($comp_seq,$member->{cstart}-1,$member->{length});
    if($member->{orient} eq '-') {
      $comp_seq = Bio::PrimarySeq->new( -seq => $comp_seq, -id => 'foo')->revcom->seq;
      # warn "revcom for $member->{ident}\n";
    }
    $seq .= $opt{lowercase} ? lc $comp_seq : uc $comp_seq;
  }

  return $seq;
}


=head2 agp_to_seqs

  Usage: my $seq = agp_to_seq( $filename, %options );
  Desc : parse an AGP file (or filehandle) and make a pseudomolecule sequence with
         it, fetching sequences using the given subroutine(s)
  Args : the AGP filename, plus hash-style options as:
           lowercase   => 1,   #< force lower-case sequence,
                                  defaults to force uppercase
           no_seq_char => 'N', #< character to use to fill gaps
           gap_length   => 0,  #< override to make all gaps this
                                  length, defaults to 0, meaning
                                  make gaps as big as the file
                                  says
           no_large_seqs => 0, #< don't use Bio::Seq::LargePrimarySeq
                                  objects to hold object sequences.
                                  If there are many short objects,
                                  using LargePrimarySeq objects for
                                  them can sometimes use up all the
                                  system's file descriptors.
           fetch_<ns> => sub { }
                               #function for fetching sequences
                               #in namespace <ns> as returned by
                               #CXGN::Tools::Identifiers::identifier_namespace
           pad_short_sequences => 0 # for sequences that are too
                                    # short to cover the region
                                    # specified in the AGP,
                                    # pad with Ns if true,
                                    # die if false.  default
                                    # false (die)
  Ret  : list of Bio::Seq::LargePrimarySeq objects
  Side Effects: warns and dies on errors

=cut

sub agp_to_seqs {
  my ($agpfile,%opt) = @_;
  $opt{gap_length} ||= 0;
  $opt{lowercase} ||= 0;
  $opt{no_seq_char} ||= $opt{lowercase} ? 'n' : 'N';

  my $agplines = agp_parse($agpfile)
    or die "error parsing AGP file $agpfile\n";

  my $seq_class =
      $opt{no_large_seqs} ? 'Bio::PrimarySeq'
                          : 'Bio::Seq::LargePrimarySeq';

  my @seqs;

  for my $line (@$agplines) {
    next if exists $line->{comment}; #< skip comments

    push @seqs, $seq_class->new( -id => $line->{objname} )
        unless $seqs[-1] && $seqs[-1]->id eq $line->{objname};

    my $seq_obj = $seqs[-1];

    if ( $line->{typedesc} =~ /^(un)?known_gap$/ ) {
        my $gap_size_to_use = $opt{gap_length} || $line->{length};
        _add_sequence_as_string( $seq_obj, $opt{no_seq_char} x $gap_size_to_use );
    } else {
        _add_sequence_as_string( $seq_obj, agp_contig_seq([$line], %opt) );
    }
  }

  return @seqs;
}


sub _add_sequence_as_string {
    my ( $seq_obj, $additional_seq ) = @_;

    if( $seq_obj->can('add_sequence_as_string') ) {
        $seq_obj->add_sequence_as_string( $additional_seq );
    } else {
        my $s = $seq_obj->seq || '';
        $seq_obj->seq( $s . $additional_seq );
    }
}

=head2 agp_to_seq

Like agp_to_seq, except only returns the first sequence in the AGP
file.  Deprecated, but still exists for backward compatibility.

=cut

sub agp_to_seq {
    ( shift->agp_to_seq(@_) )[0]
}


=head2 agp_to_features

  Usage: my @features = agp_to_features( $agp_file );
  Desc : parse the AGP file (or filehandle) and return it as a list of
         features located on the object that's being
         built
  Args : AGP file name,
         gap_type => feature type for gaps, default: gap,
                     set undef to omit gap features
         component_type => feature type for components, default: clone
                        set undef to omit component features
         source_name => name to use for 'source' column,
                        default AGP,
  Ret  : list of Bio::SeqFeature::Annotated objects
  Side Effects: none

=cut

sub agp_to_features {
  my ( $agp_file, %opts ) = @_;

  # set defaults for options
  $opts{source_name} ||= 'AGP';
  $opts{gap_type}       = 'gap'   unless exists $opts{gap_type};
  $opts{component_type} = 'clone' unless exists $opts{component_type};

  my $parsed_agp = agp_parse( $agp_file )
    or die "could not parse AGP file '$agp_file'";

  my @features;
  foreach my $line ( @$parsed_agp ) {
    next if $line->{comment};

    if( $line->{is_gap} && $opts{gap_type} ) {
      push @features,
	Bio::SeqFeature::Annotated->new( -start => $line->{ostart},
					 -end   => $line->{oend},
					 #-score => undef,
					 -type  => $opts{gap_type},
					 -source => $opts{source_name},
					 -seq_id => $line->{objname},
					 #-annots => { ID => $self->_unique_bio_annotation_id("${hname}_${fwdrev}_alignment"),
					 #	   },
				     );

    } elsif( $opts{component_type} ) {
      push @features,
	Bio::SeqFeature::Annotated->new( -start => $line->{ostart},
					 -end   => $line->{oend},
					 #-score => undef,
					 -type  => $opts{component_type},
					 -source => $opts{source_name},
					 -seq_id => $line->{objname},
					 -target => { -start => $line->{cstart},
						      -end   => $line->{cend},
						      -target_id => $line->{ident},
						    },
					 #-annots => { ID => $self->_unique_bio_annotation_id("${hname}_${fwdrev}_alignment"),
					 #	   },
				       );
    }
  }

  return @features;
}

=head1 AUTHOR(S)

Robert Buels

=cut

###
1;#do not remove
###
