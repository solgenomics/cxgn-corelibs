package CXGN::Genomic::BlastQuery;

=head1 NAME

    CXGN::Genomic::BlastQuery - genomic.blast_query object abstraction

=head1 DESCRIPTION

none yet

=head1 SYNOPSIS

none yet

=head1 METHODS

=cut

use strict;
use English;
use Carp;


=head1 DATA FIELDS

  Primary Keys:
      blast_query_id

  Columns:
      blast_query_id
      source_id
      query_source_type_id
      blast_db_id
      total_hits
      stored_hits
      last_updated

  Sequence:
      (genomic base schema).blast_query_blast_query_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table('genomic' . '.blast_query');

our @primary_key_names =
    qw/
      blast_query_id
      /;

our @column_names =
    qw/
      blast_query_id
      source_id
      query_source_type_id
      blast_db_id
      total_hits
      stored_hits
      last_updated
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('genomic').'.blast_query_blast_query_id_seq' );

our $tablename = __PACKAGE__->table;
our @persistentfields = map {[$_]} __PACKAGE__->columns;
our $persistent_field_count = @persistentfields;
our $dbname = 'genomic';

__PACKAGE__->has_a(query_source_type_id => 'CXGN::Genomic::QuerySourceType');
__PACKAGE__->has_a(blast_db_id          => 'CXGN::BlastDB');


=head2 get_sourcetype_id_by_shortname

  Desc: gets the source_type from the query_source_type table
  Args: sourcetype shortname
  Ret : the sourcetype id
  Side Effects:
  Example:

  THIS METHOD IS DEPRECATED.  You should just get this ID yourself
  using the L<CXGN::Genomic::QuerySourceType> class or a subclass
  thereof.

=cut

sub get_sourcetype_id_by_shortname {
  my $this = shift;
  my $shortname = shift;


  my ($class) = CXGN::CDBI::Genomic::QuerySourceType->search(shortname => $shortname);

  return ref($class) ? $class->query_source_type_id : undef;
}

=head2 for_gss

  Desc: get blast queries for a certain GSS object
  Args: L<CXGN::Genomic::GSS> object
  Ret : array of BlastQuery objects that correspond to the given gss
  Side Effects: none
  Example:

   my @queries = CXGN::Genomic::BlastQuery->for_gss($gss);

=cut

__PACKAGE__->set_sql(queries_by_type_and_source => <<EOSQL);
SELECT __ESSENTIAL__
FROM   __TABLE__
JOIN genomic.query_source_type as qst
  USING(query_source_type_id)
WHERE source_id = ?
  AND qst.shortname = ?
EOSQL

sub for_gss {
  my $class = shift;
  my $gss = shift;
  UNIVERSAL::isa($gss,'CXGN::Genomic::GSS')
      or croak __PACKAGE__."::for_gss takes a CXGN::Genomic::GSS as argument";

  return __PACKAGE__->search_queries_by_type_and_source($gss->gss_id,'gss');
}



=head2 db_object

  Alias for blast_db_id() method, which is a L<Class::DBI> has_a
  relation.

=cut

sub db_object {
  shift->blast_db_id(@_);
}


=head2 blast_hit_objects

  Desc: get the set of L<CXGN::Genomic::BlastHit> objects that are associated with this
        BlastQuery
  Args: optional limit of number of hits to return
  Ret : ref to array of blast hit objects associated with this query, in descending order by
        hit score

=cut

__PACKAGE__->has_many(_blast_hit_objects => 'CXGN::Genomic::BlastHit', { order_by => 'score DESC' });
sub blast_hit_objects {

  my $this = shift;
  my $limit = shift;

  $this->blast_query_id
    or croak 'this function requires a loaded/populated BlastQuery object';
  !defined($limit) or $limit > 0
    or croak 'results limit must be a positive integer';

  my @hits = $this->_blast_hit_objects;
  #go through a little acrobatics, because if you do @hits[0..($limit-1)] and
  #@hits is empty it gives (undef)x($limit).  Bleh.
  return (@hits && $limit && @hits > $limit) ? @hits[0..($limit-1)] : @hits;
}

=head2 query_len

  Desc: get the length of the query sequence for this object.
        Figures out where to find this info using its source_id and
        query_source_type_id
  Args: none
  Ret : the length of the query sequence (in base pairs or amino acids)

=cut

sub query_len {
  my $this = shift;

  my $type_shortname = $this->query_source_type_id->shortname;

  if($type_shortname eq 'gss') {
   my $gss = CXGN::Genomic::GSS->retrieve($this->source_id);
    $gss or croak 'For BlastQuery number '.$this->blast_query_id.', could not find associated CXGN::Genomic::GSS object (seeking gss_id of '.$this->source_id.')';
    return $gss->qc_report_object->hqi_length;

#   ADD NEW SOURCE TYPES HERE
#   } elsif($type_shortname eq 'somethingelse') {
#     #return the length in some other way
  }
  die "Unknown type shortname '$type_shortname'.  You probably need to add an 'elsif' for it here";
}



=head1 AUTHOR

Robert Buels

=cut

###
1;#do not remove
###

