package CXGN::CDBI::Auto::SGN::CosMarkers;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::SGN::CosMarkers - object abstraction for rows in the sgn.cos_markers table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      cos_marker_id

  Columns:
      cos_marker_id
      marker_id
      est_read_id
      cos_id
      at_match
      bac_id
      at_position
      best_gb_prot_hit
      at_evalue
      at_identities
      mips_cat
      description
      comment
      tomato_copy_number
      gbprot_evalue
      gbprot_identities

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'sgn.cos_markers' );

our @primary_key_names =
    qw/
      cos_marker_id
      /;

our @column_names =
    qw/
      cos_marker_id
      marker_id
      est_read_id
      cos_id
      at_match
      bac_id
      at_position
      best_gb_prot_hit
      at_evalue
      at_identities
      mips_cat
      description
      comment
      tomato_copy_number
      gbprot_evalue
      gbprot_identities
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###