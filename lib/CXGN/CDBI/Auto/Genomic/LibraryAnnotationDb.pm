package CXGN::CDBI::Auto::Genomic::LibraryAnnotationDb;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::Genomic::LibraryAnnotationDb - object abstraction for rows in the genomic.library_annotation_db table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      library_annotation_db_id

  Columns:
      library_annotation_db_id
      library_id
      blast_db_id
      is_contaminant

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'genomic.library_annotation_db' );

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


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###