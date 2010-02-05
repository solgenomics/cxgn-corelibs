package CXGN::CDBI::Auto::Phenome::Variant;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::Phenome::Variant - object abstraction for rows in the phenome.variant table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      variant_id

  Columns:
      variant_id
      locus_id
      variant_name
      variant_gi
      variant_notes

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'phenome.variant' );

our @primary_key_names =
    qw/
      variant_id
      /;

our @column_names =
    qw/
      variant_id
      locus_id
      variant_name
      variant_gi
      variant_notes
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###