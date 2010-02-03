package CXGN::Genomic::Library;

=head1 NAME

    CXGN::Genomic::Library - genomic.library object, based on L<Class::DBI>

=head1 DESCRIPTION

none yet

=head1 SYNOPSIS

none yet

=head1 METHODS

=cut

use strict;

use English;
use Carp;

use CXGN::CDBI::SGN::CloningVector;
use CXGN::CDBI::SGN::Organism;

=head1 DATA FIELDS

  Primary Keys:
      library_id

  Columns:
      library_id
      clone_type_id
      name
      shortname
      accession_id
      subclone_of
      organism_id

  Sequence:
      (genomic base schema).library_library_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table('genomic.library');

our @primary_key_names =
    qw/
      library_id
      /;

our @column_names =
    qw/
       library_id
       clone_type_id
       name
       shortname
       accession_id
       subclone_of
       cloning_host
       rs1
       rs2
       vector_ligation_1
       vector_ligation_2
       vector
       left_primer_id
       right_primer_id
       organism_id
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('genomic').'.library_library_id_seq' );

our $tablename = __PACKAGE__->table;
our @persistentfields = map {[$_]} __PACKAGE__->columns;
our $persistent_field_count = @persistentfields;
our $dbname = 'genomic';

__PACKAGE__->has_a( clone_type_id     => 'CXGN::Genomic::CloneType'    );
__PACKAGE__->has_a( accession_id      => 'CXGN::CDBI::SGN::Accession'  );

#this is a many-to-many relation through the LibraryAnnotationDB linking table
__PACKAGE__->has_many( annotation_dbs =>
		        [ 'CXGN::Genomic::LibraryAnnotationDB' =>
			  'blast_db_id'
			],
		     );

=head2 clone_type_object

  Desc:
  Args:
  Ret : the CloneType object associated with this Library

=cut

sub clone_type_object {
  shift->clone_type_id(@_);
}

=head2 cloning_vector_object

  Usage: my $vec = $lib->cloning_vector_object
  Desc :
  Ret  : the L<CXGN::CDBI::SGN::CloningVector> for this library
  Args : none
  Side Effects: none
  Example:

=cut

sub cloning_vector_object {
    my $this = shift;

    my @vectors = CXGN::CDBI::SGN::CloningVector->search(name => $this->vector);
    @vectors == 1 or die 'More than one vector found with name '.$this->vector;

    return $vectors[0];
}

=head2 accession_name

  in list context, return the
   (accession name, organism name, and common accession name)
  in scalar context, return the accession name

=cut

sub accession_name {
    my $this = shift;

    my $accession = $this->accession_id or die "no accession id for library ".$this->library_id;
    if(wantarray) {
      my $organism = CXGN::CDBI::SGN::Organism->retrieve($accession->organism_id)
	or die "Could not find Organism for organism id ".$accession->organism_id;

      return ($accession->accession_name,
	      $organism->organism_name,
	      $accession->common_name,
	     );
    } else {
	return $accession->accession_name;
    }
}

=head2 superclone_object

  Desc: if this Library was made by subcloning another clone, get the
        clone that is the superclone of this library
  Args: (optional) clone object
  Ret : the L<CXGN::Genomic::Clone> object, or undef if none
  Side Effects:
  Example:

=cut

sub superclone_object {
    my $this = shift;
    #superclone stuff is not implemented, but could be relatively quickly
    warn __PACKAGE__.'::superclone_object is not implemented';
    return undef;
}

=head2 organism_name

  Desc:
  Args:
  Ret : string containing this library's organism name
  Side Effects:
  Example:

=cut

sub organism_name {
  my (undef,$oname,undef)  = shift->accession_name;
  return $oname;
}

=head2 annotation_blast_dbs

  Desc:
  Args:
  Ret : an array of BlastDB objects that against which this library
        should be annotated
  Side Effects:
  Example:

=cut

sub annotation_blast_dbs {
  my $this=shift;
    $this->_get_blast_dbs('library_id='.$this->library_id
			  .' AND (is_contaminant = 0 OR is_contaminant IS NULL)',
			 );
}

=head2 contamination_blast_dbs

  Desc:
  Args:
  Ret : an array of L<CXGN::BlastDB> objects that against which this library
        should be screened for contaminants
  Side Effects:
  Example:

=cut

sub contamination_blast_dbs {
  my $this = shift;
  $this->_get_blast_dbs('library_id='.$this->library_id
			.' AND (is_contaminant != 0 AND is_contaminant IS NOT NULL)',
		       );
}

=head2 all_blast_dbs

  Desc:
  Args:
  Ret : an array of L<CXGN::BlastDB> objects that against which this library
        should be annotated.  This is the union of
        contamination_blast_dbs and annotation_blast_dbs.
  Side Effects: none
  Example:

=cut

sub all_blast_dbs {
  my $this = shift;
  $this->_get_blast_dbs('library_id='.$this->library_id);
}

#return an array of BlastDB objects related to this lib with the given criteria
sub _get_blast_dbs {
    my $this = shift;
    my $whereclause = shift;

    my $id = $this->library_id;

    #get the IDs of the BLAST dbs for this library
    my @annots = CXGN::Genomic::LibraryAnnotationDB->retrieve_from_sql($whereclause);

    return map {$_->blast_db_id} @annots;
}

=head2 clone_count

  Args:	none
  Ret :	number of clones in this library

=cut

sub clone_count {
  my $this = shift;

  @_ and croak "clone_count doesn't take any arguments";

  my ($cnt) = $this->db_Main->selectrow_array(<<EOQ,undef,$this->library_id);
select count(*) from genomic.clone where library_id=?
EOQ

  return $cnt;
}

=head2 gss_count

  Args:	none
  Ret :	absolute number of GSS from the clones in this library
        without regard to whether they are good sequences or anything

=cut

sub gss_count {
  my $this = shift;

  @_ and croak "gss_count doesn't take any arguments";

  my ($cnt) = $this->db_Main->selectrow_array(<<EOQ,undef,$this->library_id);
select count(*)
from genomic.clone
join genomic.chromat using(clone_id)
join genomic.gss using(chromat_id)
where library_id=?
EOQ
  return $cnt;
}

=head2 search_by_clone_type_shortname

  Desc: get all libraries whose clone type has the given shortname
  Args: a clone_type shortname, e.g. 'bac'
  Ret : array of libraries containing clones of that type
  Side Effects: none
  Example:

    my @baclibs = CXGN::Genomic::Library->search_by_clone_type_shortname('bac');
    print "LIST OF BAC LIBRARIES\n";
    print $_->name."\n" foreach @baclibs;

=cut

my $ct_table = CXGN::Genomic::CloneType->table;
__PACKAGE__->set_sql(by_clone_type_shortname => <<EOSQL);
SELECT __ESSENTIAL__
FROM __TABLE__
JOIN $ct_table as ct
  USING(clone_type_id)
WHERE ct.shortname = ?
EOSQL

=head1 AUTHOR

Robert Buels

=cut

####
1; # do not remove
####
