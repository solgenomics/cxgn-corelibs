package CXGN::CDBI::SGN::CloningVector;
use strict;

=head1 DESCRIPTION

CXGN::CDBI::SGN::CloningVector - object abstraction for rows in the sgn.cloning_vector table.

=head1 DATA FIELDS

  Primary Keys:
      cloning_vector_id

  Columns:
      cloning_vector_id
      name
      seq

  Sequence:
      (sgn base schema).cloning_vector_cloning_vector_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table(__PACKAGE__->qualify_schema('sgn') . '.cloning_vector');

our @primary_key_names =
    qw/
      cloning_vector_id
      /;

our @column_names =
    qw/
      cloning_vector_id
      name
      seq
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->SUPER::sequence( __PACKAGE__->base_schema('sgn').'.cloning_vector_cloning_vector_id_seq' );

sub link_html {
  my $this = shift;

  return qq|<a href="/maps/physical/vector_info.pl?id=|.$this->cloning_vector_id.qq|">|.$this->name."</a>";

}

=head1 AUTHOR

Robert Buels

=cut

###
1;#do not remove
###
