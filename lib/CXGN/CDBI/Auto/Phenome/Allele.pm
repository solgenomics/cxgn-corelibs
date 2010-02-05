package CXGN::CDBI::Auto::Phenome::Allele;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::Phenome::Allele - object abstraction for rows in the phenome.allele table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      allele_id

  Columns:
      allele_id
      locus_id
      allele_symbol
      allele_name
      mode_of_inheritance
      allele_synonym
      allele_phenotype
      allele_notes
      obsolete
      sp_person_id
      create_date
      modified_date
      updated_by
      is_default
      sequence

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'phenome.allele' );

our @primary_key_names =
    qw/
      allele_id
      /;

our @column_names =
    qw/
      allele_id
      locus_id
      allele_symbol
      allele_name
      mode_of_inheritance
      allele_synonym
      allele_phenotype
      allele_notes
      obsolete
      sp_person_id
      create_date
      modified_date
      updated_by
      is_default
      sequence
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###