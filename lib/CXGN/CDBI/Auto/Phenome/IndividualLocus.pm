package CXGN::CDBI::Auto::Phenome::IndividualLocus;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::Phenome::IndividualLocus - object abstraction for rows in the phenome.individual_locus table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      individual_locus_id

  Columns:
      individual_locus_id
      individual_id
      locus_id
      sp_person_id
      create_date
      modified_date
      obsolete

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'phenome.individual_locus' );

our @primary_key_names =
    qw/
      individual_locus_id
      /;

our @column_names =
    qw/
      individual_locus_id
      individual_id
      locus_id
      sp_person_id
      create_date
      modified_date
      obsolete
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###
