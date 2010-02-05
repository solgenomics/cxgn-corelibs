package CXGN::CDBI::Auto::Phenome::AlleleDbxref;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::Phenome::AlleleDbxref - object abstraction for rows in the phenome.allele_dbxref table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      allele_dbxref_id

  Columns:
      allele_dbxref_id
      allele_id
      dbxref_id
      obsolete
      sp_person_id
      create_date
      modified_date

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'phenome.allele_dbxref' );

our @primary_key_names =
    qw/
      allele_dbxref_id
      /;

our @column_names =
    qw/
      allele_dbxref_id
      allele_id
      dbxref_id
      obsolete
      sp_person_id
      create_date
      modified_date
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###