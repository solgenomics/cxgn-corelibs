package CXGN::CDBI::Auto::TomatoGFF::Fmeta;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::TomatoGFF::Fmeta - object abstraction for rows in the tomato_gff.fmeta table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      fname

  Columns:
      fname
      fvalue

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'tomato_gff.fmeta' );

our @primary_key_names =
    qw/
      fname
      /;

our @column_names =
    qw/
      fname
      fvalue
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###