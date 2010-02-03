package CXGN::Genomic::QCReport;
use strict;
use English;
use Carp;

=head1 NAME

    CXGN::Genomic::QCReport -
       genomic.qc_report object abstraction

=head1 DESCRIPTION

genomic.qc_report holds quality information about the sequences in
genomic.gss (which are abstracted by L<CXGN::Genomic::GSS>).

=head1 SYNOPSIS

none yet

=cut

use base qw/ Exporter/;

=head1 DATA FIELDS

  Primary Keys:
      qc_report_id

  Columns:
      qc_report_id
      gss_id
      vs_status
      qstart
      qend
      istart
      iend
      hqi_start
      hqi_length
      entropy
      expected_error
      qual_trim_threshold
      vector_tokens

  Sequence:
      (genomic base schema).qc_report_qc_report_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table('genomic' . '.qc_report');

our @primary_key_names =
    qw/
      qc_report_id
      /;

our @column_names =
    qw/
      qc_report_id
      gss_id
      vs_status
      qstart
      qend
      istart
      iend
      hqi_start
      hqi_length
      entropy
      expected_error
      qual_trim_threshold
      vector_tokens
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('genomic').'.qc_report_qc_report_id_seq' );


BEGIN { our @EXPORT_OK = qw/qc_num qc_key/;  }
our @EXPORT_OK;

=head1 EXPORTED STATIC METHODS

=cut

our $tablename = __PACKAGE__->table;
our @persistentfields = map {["$_"]} __PACKAGE__->columns;
our $persistent_field_count = @persistentfields;
our $dbname = 'genomic';


#short string, numerical, and long string representations of vector signatures
my @keys = qw/good5 good3 novec short5 short3
              noinsert5 noinsert3 chimera unknown
             /;
my @nums = 0..(@keys-1);
my @strings  = ('5\' read, flanking vector found',
		'3\' read, flanking vector found',
		'flanking vector not found in read',
		'5\' read, short insert',
		'3\' read, short insert',
		'5\' read, no insert found (only flanking vectors)',
		'3\' read, no insert found (only flanking vectors)',
		'Chimeric sequence (multiple cloning site sequence found)',
		'Unknown anomalous vector sequence pattern',
	       );

### make maps for looking up the correspondences above ###
my %qc_nums;
my %qc_keys;
my %qc_strings;
@qc_nums{@keys}    = @nums;
@qc_keys{@nums}    = @keys;
@qc_strings{@keys} = @strings;


=head2 qc_num

  Desc: given a short string description key of a vector signature,
        return its corresponding index number
  Args: short string name, e.g. 'good3'
  Ret : numerical index of that status

  works as either a method or a class sub

=cut

sub qc_num {
    my $this = shift;
    my $key = shift;
    unless(ref($this)) {
	$key = $this;
    }
    return $qc_nums{$key};
}

=head2 qc_key

  Desc: given an index number of a vector signature,
        return its short string 'key'
  Args: index number
  Ret : string key
  Side Effects: none

  translate from a qc number to a qc key
  used mostly in loading pipeline load-insert-parsed-data.pl
  works as either a method or a class sub

=cut

sub qc_key {
    my $this = shift;
    my $num = shift;
    unless(ref($this)) {
	$num = $this;
    }
    return $qc_keys{$num};
}

=head1 METHODS

=head2 vecsig

  Desc: get the descriptive string representation of this quality report's
        vector signature
  Args: none
  Ret : the plain english vector signature
  Side Effects: none
  Example:

    print $qcr->vecsig;
    #will print something like "3' read, no insert"

=cut

sub vecsig {
    my $this=shift;
    ref($this) or croak 'vecsig is an object method!';
    @_ and croak 'vecsig takes no arguments';
    return $qc_strings{$qc_keys{$this->vs_status}};
}

=head2 gss_id

  Desc: L<Class::DBI> has_a relation to L<CXGN::Genomic::GSS>
  Args: none
  Ret : this QCReport's associated L<CXGN::Genomic::GSS> object
  Side Effects: none
  Example:

  my $gss = $qcreport->gss_id;
  print $gss->clone_object->clone_read_external_identifier;

=cut

__PACKAGE__->has_a(gss_id => 'CXGN::Genomic::GSS');

=head2 gss_object

Alias for gss_id() above.

=cut

sub gss_object {
  shift->gss_id(@_);
}


=head1 AUTHOR

Robert Buels

=cut

####
1; # do not remove
####
