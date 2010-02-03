package CXGN::CDBI::SGN::UnigeneMember;
use strict;


=head1 DATA FIELDS

  Primary Keys:
      unigene_member_id

  Columns:
      unigene_member_id
      unigene_id
      est_id
      start
      stop
      qstart
      qend
      dir

  Sequence:
      (sgn base schema).unigene_member_unigene_member_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table(__PACKAGE__->qualify_schema('sgn') . '.unigene_member');

our @primary_key_names =
    qw/
      unigene_member_id
      /;

our @column_names =
    qw/
      unigene_member_id
      unigene_id
      est_id
      start
      stop
      qstart
      qend
      dir
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('sgn').'.unigene_member_unigene_member_id_seq' );


__PACKAGE__->has_a(unigene_id => 'CXGN::CDBI::SGN::Unigene');
__PACKAGE__->has_a(est_id => 'CXGN::CDBI::SGN::EST');

sub est_object {
  shift->est_id(@_);
}

###
1;#do not remove
###
