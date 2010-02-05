package CXGN::CDBI::Auto::Physical::TentativeOvergoAssociations;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::Physical::TentativeOvergoAssociations - object abstraction for rows in the physical.tentative_overgo_associations table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      tentative_assoc_id

  Columns:
      tentative_assoc_id
      overgo_version
      overgo_probe_id
      bac_id

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'physical.tentative_overgo_associations' );

our @primary_key_names =
    qw/
      tentative_assoc_id
      /;

our @column_names =
    qw/
      tentative_assoc_id
      overgo_version
      overgo_probe_id
      bac_id
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###