package CXGN::CDBI::Auto::SGN::PMarkers;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::SGN::PMarkers - object abstraction for rows in the sgn.p_markers table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      pid

  Columns:
      pid
      marker_id
      est_clone_id
      p_mrkr_name

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'sgn.p_markers' );

our @primary_key_names =
    qw/
      pid
      /;

our @column_names =
    qw/
      pid
      marker_id
      est_clone_id
      p_mrkr_name
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###