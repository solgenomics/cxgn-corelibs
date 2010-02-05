package CXGN::CDBI::Auto::TomatoGFF::Ftype;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::TomatoGFF::Ftype - object abstraction for rows in the tomato_gff.ftype table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      ftypeid

  Columns:
      ftypeid
      fmethod
      fsource

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'tomato_gff.ftype' );

our @primary_key_names =
    qw/
      ftypeid
      /;

our @column_names =
    qw/
      ftypeid
      fmethod
      fsource
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###