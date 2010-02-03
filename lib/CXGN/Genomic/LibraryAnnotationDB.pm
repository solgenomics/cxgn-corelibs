package CXGN::Genomic::LibraryAnnotationDB;

=head1 NAME

    CXGN::Genomic::LibraryAnnotationDB -
       genomic.library_annotation_db object abstraction

=head1 DESCRIPTION

       genomic.library_annotation_db is a linking table between library
       and sgn.blast_db

=head1 SYNOPSIS

none yet

=head1 METHODS

=cut

use strict;
use English;


=head1 DATA FIELDS

  Primary Keys:
      library_annotation_db_id

  Columns:
      library_annotation_db_id
      library_id
      blast_db_id
      is_contaminant

  Sequence:
      (genomic base schema).library_annotation_db_library_annotation_db_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table('genomic' . '.library_annotation_db');

our @primary_key_names =
    qw/
      library_annotation_db_id
      /;

our @column_names =
    qw/
      library_annotation_db_id
      library_id
      blast_db_id
      is_contaminant
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('genomic').'.library_annotation_db_library_annotation_db_id_seq' );

our $tablename = __PACKAGE__->table;
our @persistentfields = map {[$_]} __PACKAGE__->columns;
our $persistent_field_count = @persistentfields;
our $dbname = 'genomic';

__PACKAGE__->has_a( blast_db_id => 'CXGN::BlastDB');
__PACKAGE__->has_a( library_id  => 'CXGN::Genomic::Library');

=head1 AUTHOR

Robert Buels

=cut

####
1; # do not remove
####
