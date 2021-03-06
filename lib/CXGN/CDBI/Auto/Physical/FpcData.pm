package CXGN::CDBI::Auto::Physical::FpcData;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::Physical::FpcData - object abstraction for rows in the physical.fpc_data table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      fpc_datum_id

  Columns:
      fpc_datum_id
      bac_id
      bac_name
      gel_number
      map_ctg_left
      map_ctg_right
      map_ends_left
      map_ends_right
      creation_date
      modification_date
      bac_contig_id_left
      bac_contig_id_right

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'physical.fpc_data' );

our @primary_key_names =
    qw/
      fpc_datum_id
      /;

our @column_names =
    qw/
      fpc_datum_id
      bac_id
      bac_name
      gel_number
      map_ctg_left
      map_ctg_right
      map_ends_left
      map_ends_right
      creation_date
      modification_date
      bac_contig_id_left
      bac_contig_id_right
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###
