package CXGN::CDBI::Auto::SGN::DeprecatedMapCross;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::SGN::DeprecatedMapCross - object abstraction for rows in the sgn.deprecated_map_cross table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      map_cross_id

  Columns:
      map_cross_id
      map_id
      organism_id

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'sgn.deprecated_map_cross' );

our @primary_key_names =
    qw/
      map_cross_id
      /;

our @column_names =
    qw/
      map_cross_id
      map_id
      organism_id
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###
