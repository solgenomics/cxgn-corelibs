package CXGN::CDBI::Auto::SGN::UnigeneBuild;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::SGN::UnigeneBuild - object abstraction for rows in the sgn.unigene_build table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      unigene_build_id

  Columns:
      unigene_build_id
      source_data_group_id
      organism_group_id
      build_nr
      build_date
      method_id
      status
      comment
      superseding_build_id
      next_build_id
      latest_build_id
      blast_db_id

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'sgn.unigene_build' );

our @primary_key_names =
    qw/
      unigene_build_id
      /;

our @column_names =
    qw/
      unigene_build_id
      source_data_group_id
      organism_group_id
      build_nr
      build_date
      method_id
      status
      comment
      superseding_build_id
      next_build_id
      latest_build_id
      blast_db_id
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###
