package CXGN::CDBI::Auto::SGN::SsrRepeats;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::SGN::SsrRepeats - object abstraction for rows in the sgn.ssr_repeats table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      repeat_id

  Columns:
      repeat_id
      ssr_id
      repeat_motif
      reapeat_nr
      marker_id

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'sgn.ssr_repeats' );

our @primary_key_names =
    qw/
      repeat_id
      /;

our @column_names =
    qw/
      repeat_id
      ssr_id
      repeat_motif
      reapeat_nr
      marker_id
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###