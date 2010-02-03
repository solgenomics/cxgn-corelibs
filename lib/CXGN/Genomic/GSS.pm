package CXGN::Genomic::GSS;
use strict;
use English;
use Carp;
use Data::BitMask;
#use Date::Format;

use Bio::SeqFeature::Generic;

=head1 NAME

    CXGN::Genomic::GSS -
       genomic.gss object abstraction

=head1 DESCRIPTION

genomic.gss holds sequences derived from the chromatogram files
catalogued in genomic.chromat.  It also holds some information
about the characteristics of those sequences.

=head1 SYNOPSIS

none yet

=head1 DATA FIELDS

  Primary Keys:
      gss_id

  Columns:
      gss_id
      chromat_id
      version
      basecaller
      seq
      qual
      call_positions
      status
      flags
      date

  Sequence:
      (genomic base schema).gss_gss_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table('genomic' . '.gss');

our @primary_key_names =
    qw/
      gss_id
      /;

our @column_names =
    qw/
      gss_id
      chromat_id
      version
      basecaller
      seq
      qual
      call_positions
      status
      flags
      date
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('genomic').'.gss_gss_id_seq' );

__PACKAGE__->columns(Essential => qw/ gss_id seq status flags /);

=head1 METHODS

=cut

BEGIN {
  #SET UP A WHOLE LOT OF STATUS AND QC FLAGS

  #available status flags
  #if you add a flag, add it to the end
  #if you delete a flag, rebuild the gss and qc_report tables with the genomic pipeline
  our @statusflags = qw(legacy discarded deprecated censored vec_unk contam_unk chimera_unk repeats_unk);
  our %statusflags_strings;
  @statusflags_strings{@statusflags} = ( 'Legacy',
					 'Discarded',
					 'Deprecated',
					 'Manually censored',
					 'Not screened for cloning vector',
					 'Not screened for contaminants',
					 'Not screened for chimera',
					 'Not screened for repetitive elements',
				       );

  #available other flags
  #if you add a flag, add it to the end
  #if you delete a flag, rebuild the gss and qc_report tables with the genomic pipeline
  our @otherflags = qw(anomaly chimera1 short error complexity hostcontam repeat chimera2);
  our %otherflags_strings;
  @otherflags_strings{@otherflags} = ( 'Anomalous sequence (probable bad read)',
				       'Probable chimera (detection method 1)',
				       'Short cloning insert',
				       'High predicted error rate',
				       'Low complexity',
				       'Probable foreign DNA contamination',
				       'Probable repetitive elements',
				       'Probable chimera (detection method 2)',
				       'Manually censored',
				     );
}

BEGIN {
  ## given a list of flags,
  ## generate a mask definition for consumption
  ## by the constructor of a Data::BitMask object
  sub _generate_maskdef {
    map {($_,eval $_)} @_;
  }

  our @statusflags;
  use enum ('BITMASK:',@statusflags);
  our $statusBM = Data::BitMask->new( &_generate_maskdef(@statusflags) );

  our @otherflags;
  use enum ('BITMASK:',@otherflags);
  our $otherBM  = Data::BitMask->new( &_generate_maskdef(@otherflags ) );
}

#need to declare variables like this
#both inside and outside the BEGIN block
our %statusflags_strings;
our %otherflags_strings;
our $statusBM;
our $otherBM;

our $tablename = __PACKAGE__->table;
our @persistentfields = map {["$_"]} __PACKAGE__->columns;
our $persistent_field_count = @persistentfields;
our $dbname = 'genomic';


=head2 chromat_id

  Desc: L<Class::DBI> has_a relationship to L<CXGN::Genomic::Chromat>
  Args: none
  Ret : the L<CXGN::Genomic::Chromat> associated with this GSS
  Side Effects: none
  Example:

  my $chromat = $gss->chromat_id

=cut

__PACKAGE__->has_a(chromat_id => 'CXGN::Genomic::Chromat');

=head2 chromat_object

Alias for chromat_id() above.

=cut

sub chromat_object {
  shift->chromat_id(@_);
}

=head2 retrieve_from_parsed_name

  Usage: my $gss = retrieve_from_parsed_name($parsed_name);
  Desc : retrieve a gss using the information in a hash ref of the
         kind returned by L<CXGN::Genomic::CloneNameParser>
  Ret  : a gss object, or undef if no gss objects matched
  Args : hash ref of the type returned by L<CXGN::Genomic::CloneNameParser>
  Side Effects: none
  Example:

  Uses search_by_chromat_and_version internally

=cut

sub retrieve_from_parsed_name {
  my $class = shift;
  my $parsed = shift;

  ref $parsed eq 'HASH'
    or croak 'retrieve_from_parsed_name() takes a hashref argument';

  my @matching =
    $class->search_by_chromat_and_version(@{$parsed}{qw/chromat_id version/});

  @matching == 1 or return undef;

  return $matching[0];
}


=head2 search_by_chromat_and_version

  Usage: my @clones = search_by_chromat_and_version($chromat_id,
                                                    $version,
                                                   );
  Desc : find the gss(s) with the given chromat_id and version
  Ret  : array of matching gss(s).  This array should probably always contain
         just one object.
  Args : chromat id, version number
  Side Effects: looks things up in the database
  Example:

=cut

my $genomic = 'genomic';
__PACKAGE__->set_sql(by_chromat_and_version => <<EOSQL);
SELECT __ESSENTIAL__
FROM __TABLE__
JOIN $genomic.chromat as chr
  USING(chromat_id)
WHERE       chr.chromat_id = ?
  AND __TABLE__.version    = ?
EOSQL

=head2 gss_submitted_to_genbank_objects

  Args:	none
  Ret :	list of gss_submitted_to_genbank rows associated with this gss,
        in order of ascending gss_submitted_to_genbank_id values,
        or an empty list if none found
  Side Effects: none

=cut

__PACKAGE__->has_many(gss_submitted_to_genbank_objects => 'CXGN::Genomic::GSSSubmittedToGenbank',
		      { order_by => 'gss_submitted_to_genbank_id' },
		     );

######## STATUS ACCESSORS ############

=head1 FLAGS ACCESSORS

The GSS object has two numeric fields that contain integers interpreted
as bitmasks.  This means that each bit of the integer's binary representation
is considered a separate value of either 0 or 1, and the set/unset status of
each bit indicates whether some condition is present.  The names, bit offsets,
and meanings of each flag are given below.

Fortunately, users of this object do not have to deal with these bits
themselves. Flags access is in the form of hashes whose keys are the names of
the flags, with values being either 1 or 0.

=over 12

=head2 Status Flags (genomic.gss.status)

=item legacy - 0x1

Whether this GSS is considered to be old and crufty.

=item discarded - 0x2

If set, this GSS is considered to be in the trash can, without actually
having been deleted.

=item deprecated - 0x4

This GSS is valid, but has been superseded by another (e.g. another
basecalling of the same chromatogram)

=item censored - 0x8

This GSS has been manually censored for some reason, and should not be used.

=item vec_unk - 0x10

This GSS has not yet been screened and trimmed for vector sequence.

=item contam_unk - 0x20

This GSS has not been screened for sequence associated with contaminants
like E.Coli, mitochondria, etc.

=item chimera_unk - 0x40

This GSS has not been screened to determine whether it is chimeric.

=item repeats_unk - 0x80

This GSS has not been screened for repetitive sequence.

=back

=head2 status

  Desc: get the status flags of this object in the form of a hash
  Args: (optional) new status hash. This completely replaces the old status.
  Ret : new value of the status, as a hash:
        {  status name => 1,
        }
        If a flag is not set, it will not appear as a key in the hash.
  Side Effects: if argument provided, sets that value in the object

=cut

sub status {
    my $this = shift;

    return $this->_generic_flags_accessor($statusBM,'status',@_);
}

=head2 gen_status_mask

  Desc: given a hash status representation, return the integer bitmask
        representation of it.  Can be used either as a package method
        OR an object method.  This method is basically a wrapper for
        L<Data::BitMask>::build_mask()
  Args: string representation of what flags to make a mask for, as:
     ' flag_name | flag_name | flag_name '
  Ret : bitmask integer
  Side Effects: none
  Example:

    #roll your own query to get all GSSs that still need vector screening
    my $desired_status = $gss->gen_status_mask({ vec_unk => 1});
    my $ids_ar = $dbh->selectcol_arrayref(
      'SELECT gss_id FROM genomic.gss WHERE status & ? != 0',
      undef,
      $desired_status);


=cut

sub gen_status_mask {
  shift if UNIVERSAL::isa($_[0],'CXGN::Genomic::GSS');
  return _generic_mask_generator($statusBM,@_);
}

=head2 unset_status

  Desc: unset one or more status flags on this object
  Args: string representing which flags to unset, of the form
        ' flag_name | flag_name | flag_name '
  Ret : hash ref of current flag settings as
       { flag_name => 1,
         flag_name => 1,
       }
  Side Effects: sets internal status flags, will be saved to the DB
    in the manner of any other L<Class::DBI> data.
  Example:

    foreach (@gss_i_have_vector_screened)x {
      $_->unset_status('vec_unk');
      $_->update;
    }

=cut

sub unset_status {
    my $this = shift;
    return $this->_generic_flag_set($statusBM,'status',0,@_);
}

=head2 set_status

Same as above, except set the given flags.

=cut

sub set_status {
    my $this = shift;
    return $this->_generic_flag_set($statusBM,'status',1,@_);
}

=head2 status2str

  Desc: get a string representation of the status flags on this GSS.
        Can be called as either an object method or standalone
        as __PACKAGE__::status2str
  Args: if called as an object method:
           none
        if called as a standalone method:
           ref to hash of status flags
  Ret : list of strings describing each flag that is set
  Side Effects: none
  Example:

     #print an HTML unordered list of all the statuses on a given GSS
     #object
     my @status_strings = $gss->status2str;
     print join("\n", ('<ul>', map {"<li>$_</li>"} @status_strings, '</ul>'));

=cut

sub status2str {
    _generic_flags2str(@_,'status',\%statusflags_strings);
}

=head2 set_status_global

  Desc: like set_status, except this operates on ALL members
        in the database table.  Can be called as either a
        regular sub or as an object method.
  Args: string representation of status to set
  Ret : 1, no matter what
  Side Effects: globally sets things in the database
  Example:

  #mark everything as needing contaminant screening
  $gss->set_status_global('contam_unk');

=cut

sub set_status_global {
    my $this = shift;
    ref $this || unshift @_,$this;

    $this->_generic_global_flag_set($statusBM,'status',1,@_);
}

=head2 unset_status_global

Same as set_status_global() above, except the status flags are
unset.

=cut

sub unset_status_global {
    my $this = shift;
    ref $this || unshift @_,$this;

    $this->_generic_global_flag_set($statusBM,'status',0,@_);
}

#####FLAGS ACCESSORS
=head2 Quality Flags (genomic.gss.flags)

=over 12

=item anomaly - 0x1

This sequence is anomalous in some way and shouldn't be trusted.

=item chimera1 - 0x2

This sequence was classified as chimeric (method 1).
NOTE: chimera screening has not been implemented for GSS
sequences, and it might never be.

=item short - 0x4

The non-vector part of this sequence is too short to be considered
reliable.

=item error - 0x8

Based on the quality scores from basecalling, the predicted error of
this sequence is high.

=item complexity - 0x10

This sequence's complexity (measured in terms of the entropy present
in the sequence letters themselves) is too low for the sequence to
be considered reliable.

=item hostcontam - 0x20

This GSS seems to contain sequence associated with a known contaminant,
like E.Coli or the like.

=item repeat - 0x40

This GSS seems to be repetitive in nature, whether as part of a known
repetitive sequence, or through de novo repeat detection.

=item chimera2 - 0x80

This clone seems to be chimeric (method 2).
NOTE: chimera screening has not been implemented

=back

=head2 flags

Same as status() above, but for the quality flags field.

=cut

sub flags {
    return shift->_generic_flags_accessor($otherBM,'flags',@_);
}

=head2 gen_flags_mask

Same as gen_status_mask() above, but for quality flags.

=cut

sub gen_flags_mask {
  shift if UNIVERSAL::isa($_[0],'CXGN::Genomic::GSS');
  return _generic_mask_generator($otherBM,@_);
}

=head2 unset_flags

Same as unset_status() above, but for quality flags.

=cut

sub unset_flags {
    my $this = shift;
    return $this->_generic_flag_set($otherBM,'flags',0,@_);
}

=head2 set_flags

Same as set_status() above, but for quality flags.

=cut

sub set_flags {
    my $this = shift;
    return $this->_generic_flag_set($otherBM,'flags',1,@_);
}

=head2 flags2str

Same as status2str() above, but for quality flags.

=cut

sub flags2str {
    return _generic_flags2str(@_,'flags',\%otherflags_strings);
}

=head2 set_flags_global

Same as set_status_global() above, but for quality flags.

=cut

sub set_flags_global {
    my $this = shift;

    $this->_generic_global_flag_set($otherBM,'flags',1,@_);
}

=head2 unset_flags_global

Same as unset_flags_global() above, but for quality flags.

=cut

sub unset_flags_global {
    my $this = shift;

    $this->_generic_global_flag_set($otherBM,'flags',0,@_);
}

###### GENERIC FLAGS HANDLERS ######
### used for both status and flags fields ####
sub _generic_flags_accessor {
  my $this = shift;
  my $bm_handler = shift;
  my $var = shift;

  if(@_) {
    my $newmask = $bm_handler->build_mask(@_);
    $this->set($var => $newmask);
    return $this->$var;
  } else {
    my $curmask = $this->get($var);
    my $exp = $bm_handler->break_mask($curmask);
    return $exp;
  }
}
sub _generic_mask_generator {
    my $bm_handler = shift;
    return $bm_handler->build_mask(@_);
}
sub _generic_flag_set {
    my ($this,$bm_handler,$var,$setval,$flags_str) = @_;

    my %curflags = %{$bm_handler->break_mask($this->get($var))};

    foreach my $f (split /\s*\|\s*/,$flags_str) {
	$curflags{$f} = $setval; #1 or 0
    }

    $this->set($var => $bm_handler->build_mask(\%curflags));
    return \%curflags;
}

sub _generic_global_flag_set {
    my ($this,$bm_handler,$var,$setval,$flags_str) = @_;

    #check that the field we are supposed to be
    #setting is a valid one
    grep {$var eq $_} qw/ flags status /
      or die "Unknown var name '$var'";

    my %flags = map {$_ => 1} (split /\s*\|\s*/,$flags_str);

    ### make the mask to apply globally ###
    my $mask = $bm_handler->build_mask(\%flags);
    my $op;
    my $opname;
    if($setval) {
	$op = '|';
	$opname = 'or';
    } else {
	$op = '&';
	$opname = 'and';
	$mask = ~($mask);
    }

    ### if we haven't already, define a query to do this ###
    #the advantage of this is that the __TABLE__ name is inheritable
    my $methodname = "_global_set_${var}_${opname}";
    unless (defined &{__PACKAGE__."\::$methodname"}) {
      __PACKAGE__->set_sql($methodname,'UPDATE __TABLE__ SET $var = $var $op ?');
      #see Class::DBI's set_sql method
    }

    ### now set all the flags ###
    $this->$methodname($mask);

    return 1;
}
sub _generic_flags2str {
    my $this = shift;
    my $strings_hr;
    my $flags_hr;
    my $var;
    if(ref($this) =~ /GSS$/i) {
	$var = shift;
	$flags_hr = $this->$var;
    } else {
	$flags_hr = $this
	  or croak 'Improper number of arguments.';
	$var = shift;
    }
    $strings_hr = shift;

    my @strings = ();
    while(my ($flag,$setting) = each %$flags_hr) {
	push @strings,$strings_hr->{$flag} if $setting;
    }
    return @strings;
}
################################################
################################################
################################################

#gets this GSS's qc_report object, if any.
#returns undef if no qc_report object found

=head2 qc_report_object

  Desc: get the L<CXGN::Genomic::QCReport> object associated with this GSS
  Args: none
  Ret : L<CXGN::Genomic::QCReport> object
  Side Effects: croaks if more than one QCReport is found for this GSS
  Example:

  my $qcr = $gss->qc_report_object;
  print $qcr->summary_html;

=cut

__PACKAGE__->has_many(_qc_report_objects => 'CXGN::Genomic::QCReport');
sub qc_report_object {
    my $this = shift;

    my @reports = $this->_qc_report_objects;
    my $matches = @reports;

    croak "$matches QCReport objects found with gss_id=".$this->gss_id
      if $matches > 1;

    return undef 
      if $matches < 1;

    return $reports[0];
}

=head2 flags_html

  Desc: get an html representation of the flags on this GSS
  Args: none
  Ret : HTML string representing what flags this thing has on it
  Side Effects: none
  Example:
    print $gss->flags_html;

=cut

sub flags_html {
    my $this = shift;

    my @flags_str = $this->flags2str;
    my $numflags = scalar(@flags_str);

    my @status_str = $this->status2str;
    my $numstatus = scalar(@status_str);

    my $flags_html = '<table width="100%"><tr>';
    if($numflags > 0) {
	$flags_html .= '<td valign="top"><span class="fieldname" style="color: red; display: block">Problems:</span><ul><li>'.join("</li>\n<li>",@flags_str)."</li>\n</ul>\n</td>";
    }
    if($numstatus > 0) {
	$flags_html .= qq{<td valign="top">\n  <span class="fieldname" style="color: #BBBB00; display: block">Warnings:</span>\n<ul>\n<li>}.join("</li>\n<li>",@status_str)."</li>\n</ul>\n</td>";
    }
    if(!($numflags > 0) && !($numstatus > 0)) {
	$flags_html .= '<td valign="top"></td>';
    }
    $flags_html .= '</tr></table>';

    return $flags_html;
}


=head2 oneline_summary

  Desc:
  Args: none
  Ret : in scalar context, get a few-word string describing this read's status
           in a nutshell.
        in list context, get the string and a string containing some CSS
           styles for it
  Side Effects: none
  Example:
    print $gss->oneline_summary;

=cut

sub oneline_summary {
    my $this = shift;

    my $status = $this->status;
    my $flags = $this->flags;

    ### in this case, grep {$_} <hash slice> will eval to  ###
    ### true if any of the values in the slice are 1       ###
    my ($tag,$css);
    if(grep {$_} @{$status}{qw/legacy discarded deprecated censored/}) {
      $tag = 'Bad';
      $css = 'font-weight: bold; color: #BB0000;';
    } elsif(grep {$_} @{$status}{qw/ vec_unk contam_unk /}) {
      #NOTE: repeats_unk and chimera_unk don't affect the status reported here
      $tag = 'Screening not complete'; #has some status issues
      $css = '';
    } elsif(grep {$_} values %$flags) {
	$tag = 'Problems'; #has some flags set
	$css = 'font-weight: bold; color: #BBBB00;';
    } else {
	$tag = 'Good';
	$css = 'font-weight: bold;color: #00BB00;';
    }

    return ($tag,$css) if wantarray;
    return $tag;
}


##### SEQUENCE ACCESSORS

=head2 trim_coords

  Desc: get the start and length of the high-quality insert sequence in this GSS
  Args: none
  Ret : (starting index of HQI, length of HQI)
  Side Effects: none
  Example:

    my ($hqi_start,$hqi_length) = $gss->trim_coords;

=cut

sub trim_coords {
    my $this = shift;
    my $qc = $this->qc_report_object;

    return '' unless ($this->seq && $qc->hqi_length > 0);

    return ($qc->hqi_start,$qc->hqi_length);
}

=head2 trimmed_seq

  Desc: get the high-quality portion of the sequence in this GSS object
  Args: none
  Ret : string containing only high-quality sequence
  Side Effects: none
  Example:

    my $trimmedseq = $gss->trimmed_seq;

=cut

sub trimmed_seq {
    my $this = shift;

    my ($hqs,$hql) = $this->trim_coords;

    return '' unless defined $hqs && defined $hql;

    return substr($this->seq,$hqs,$hql);
}

=head2 trimmed_qual

  Desc: get the corresponding quality values for each base of the 
        high-quality trimmed sequence in this GSS
  Args: none
  Ret : string containing space-separated list of qual values
  Side Effects: none
  Example:
    my $seq  = $gss->trimmed_seq;
    my $qual = $gss->trimmed_qual;
    length($seq) == split /\s/,$qual
      or die 'this should never happen';


=cut

sub trimmed_qual {
    my $this = shift;
    my $qual = $this->qual;
    my ($hqs,$hql) = $this->trim_coords;

    return undef unless defined $qual && defined $hqs && defined $hql;

    my $range_end = $hqs+$hql-1;
    return join(' ',(split ' ',$qual)[$hqs..$range_end]);
}

=head2 trimmed_regions

  Desc: get the parts of the raw sequence that have been trimmed in
        quality processing
  Args: none
  Ret : list of [begin,end] inclusive pairs of TRIMMED OUT regions
        in the seq and qual of this GSS
  Side Effects: none
  Example:

    my @trimmed_regions = $gss->trimmed_regions;
    print "trimmed out $_->[0] to $_->[1]\n"
       foreach @trimmed_regions;

=cut

sub trimmed_regions {
    my $this = shift;
    my $qc = $this->qc_report_object;
    return () unless $qc;
    my $hqs = $qc->hqi_start;
    my $hql = $qc->hqi_length;
    my $len = length($this->seq);
    my @regions = ();

    if($hql > 0) {
	if($hqs > 0) {
	    #find the first trimmed out region
	    push @regions,[0,$hqs-1];
	}

	if($hqs+$hql < $len) {
	    push @regions,[$hqs+$hql,$len-1];
	}
    } else {
	push @regions,[0,$len-1];
    }

    return @regions;
}

=head2 external_identifier

  Desc: get a string containing the complete stable external identifier
        for this GSS, e.g. LE_HBa0023A12_SP6_12345_2
  Args: none
  Ret : string containing the external ident
  Side Effects: none
  Example:
    my $extid = $gss->external_identifier;
    print "<b>GSS:</b> $extid";

=cut

sub external_identifier {
    my $this = shift;
    my $read_ident = $this->chromat_object->clone_read_external_identifier;

    ($this->version > 1) ? $read_ident.'_'.$this->version : $read_ident
}

=head2 external_identifier_sql

  Desc: get SQL to assemble a proper GSS sequence external identifier
        in your own queries
  Args: SQL expressions that yield the following:
        (library shortname, clone plate, clone well row, clone well column,
         sequencing primer, chromat id number, GSS version)
  Ret : string of SQL that will properly assemble these pieces of data into a
        well-formed GSS external identifier
  Side Effects: none
  Example:

    my $identifier_sql = CXGN::Genomic::GSS->
                         clone_read_external_identifier_sql(qw/ l.shortname
                                                                c.platenum
								c.wellrow
								c.wellcol
								chr.primer
								chr.chromat_id
							      /);
    my $query = <<EOSQL;
  SELECT $identifier_sql
  FROM genomic.chromat as chr
  JOIN genomic.clone as c
    USING(clone_id)
  JOIN genomic.library as l
    USING(library_id)
  LIMIT 10
  EOSQL

  Note: this can be called as a package method (CXGN...GSS->external...), OR
        an object method ($gss->external...)
        OR directly from this package like CXGN...GSS::external...

=cut

sub external_identifier_sql {
  my $thing = shift;
  unless(UNIVERSAL::isa($thing,__PACKAGE__)) {
    unshift @_,$thing;
  } #can be called in any way you want

  #check arguments
  @_ == 7 or croak "external_identifier_sql takes 7 arguments\n";
  grep !$_,@_[0..6] and croak "all arguments to external_identifier_sql must be column name strings\n";

  my ($lib,$plate,$row,$col,$primer,$chromat,$version) = @_;
  my $chromat_name =
    CXGN::Genomic::Chromat::clone_read_external_identifier_sql($lib,
							       $plate,
							       $row,
							       $col,
							       $primer,
							       $chromat);
  my $version_sql = "CASE $version WHEN 1 THEN '' ELSE '_' || $version END";
  return "($chromat_name || $version_sql)";
}

=head2 unixtime

  Desc: get and set this object's date field in seconds-since-epoch format
  Args: (optional) new unixtime
  Ret : integer unix time
  Side Effects: if argument, sets this object's time
  Example:

    my $time = $gss->unixtime;
    $time += 100000;
    $gss->unixtime($time);
    $gss->update;

=cut

sub unixtime {
    my $this = shift;

    if(@_) {
	### setting ###
	my $newtime = shift;
	my @time = (localtime(shift))[0..5];
	$this->date(sprintf('%s-%s-%s %s:%s:%s', $time[5]+1900, $time[4]+1, $time[3], $time[2], $time[1], $time[0]))
	  or return undef;
#	$this->date(time2str('%Y-%m-%d %k:%M:%S',shift))

    }

    my $sqldate = $this->date;
    my @time = ( (map { substr($sqldate,$_,2) } (17,14,11,8,5)), 
		 substr($sqldate,0,4) );

    my $ftime = POSIX::strftime('%s',@time);
    return $ftime;
}


=head2 to_bio_seq

  Desc:
  Args: bioperl-style hash-style list of:
        (  -factory => a L<Bio::Seq::SeqFactory> object to use to create
                       the new L<Bio::Seq> object,
        )
  Ret : a L<Bio::Seq> object loaded with most of this GSS object information.
  Side Effects: none
  Example:

    my $bioseq = $gss->to_bio_seq( -factory => Bio::Seq::SeqFactory->new );

=cut

sub to_bio_seq {
    my $this = shift;

    my %args = @_;
    my $fac = $args{-factory};

    ### check the type of the -factory arg using isa() ###
    UNIVERSAL::isa($fac,'Bio::Seq::SeqFactory')
	or croak 'Wrong type for -factory argument - must be a Bio::Seq::SeqFactory or a subclass';

    my $bioseq = $fac->create(
			      -seq           => $this->seq,
			      -primary_id    => $this->gss_id,
			      -display_id    => $this->external_identifier,
			      -qual          => $this->qual,
			      -trace_indices => $this->call_positions,
			      -desc          => 'Chromat_file:'
			                        .($this->chromat_object->filename || 'none')
			                        .' SGN_GSS_ID:'.$this->gss_id,
			      -alphabet      => 'dna',
			      -direct        => 1,
			      -namespace     => 'sgn genomic',
			      -authority     => 'http://sgn.cornell.edu',
			     );

    ### set this object as its origin gss object ###
    $bioseq->gss_object($this);

    return $bioseq
}

=head1 AUTHOR

Robert Buels

=cut

####
1; # do not remove
####


