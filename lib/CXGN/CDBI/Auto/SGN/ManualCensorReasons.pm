package CXGN::CDBI::Auto::SGN::ManualCensorReasons;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::SGN::ManualCensorReasons - object abstraction for rows in the sgn.manual_censor_reasons table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      censor_id

  Columns:
      censor_id
      reason

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'sgn.manual_censor_reasons' );

our @primary_key_names =
    qw/
      censor_id
      /;

our @column_names =
    qw/
      censor_id
      reason
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###
