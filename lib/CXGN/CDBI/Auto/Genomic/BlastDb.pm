package CXGN::CDBI::Auto::Genomic::BlastDb;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::Genomic::BlastDb - object abstraction for rows in the genomic.blast_db table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      blast_db_id

  Columns:
      blast_db_id
      subdir
      file_basename
      db_title
      blast_program
      source_url
      lookup_url

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'genomic.blast_db' );

our @primary_key_names =
    qw/
      blast_db_id
      /;

our @column_names =
    qw/
      blast_db_id
      subdir
      file_basename
      db_title
      blast_program
      source_url
      lookup_url
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###
