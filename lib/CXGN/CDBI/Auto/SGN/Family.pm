package CXGN::CDBI::Auto::SGN::Family;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::SGN::Family - object abstraction for rows in the sgn.family table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      family_id

  Columns:
      family_id
      family_build_id
      family_annotation
      tree_log_file_location
      tree_file_location
      tree_taxa_number
      tree_overlap_length
      family_nr
      member_count

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'sgn.family' );

our @primary_key_names =
    qw/
      family_id
      /;

our @column_names =
    qw/
      family_id
      family_build_id
      family_annotation
      tree_log_file_location
      tree_file_location
      tree_taxa_number
      tree_overlap_length
      family_nr
      member_count
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###
