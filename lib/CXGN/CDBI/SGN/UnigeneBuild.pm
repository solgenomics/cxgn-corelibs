package CXGN::CDBI::SGN::UnigeneBuild;
use strict;


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

  Sequence:
      (sgn base schema).unigene_build_unigene_build_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table(__PACKAGE__->qualify_schema('sgn') . '.unigene_build');

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
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('sgn').'.unigene_build_unigene_build_id_seq' );


__PACKAGE__->has_many(unigenes => 'CXGN::CDBI::SGN::Unigene');
__PACKAGE__->has_a(organism_group_id => 'CXGN::CDBI::SGN::Groups');

sub organism_group_name {
  shift->organism_group_id->comment;
}

###
1;#do not remove
###
