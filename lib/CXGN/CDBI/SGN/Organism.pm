package CXGN::CDBI::SGN::Organism;

use strict;
use warnings;


=head1 DATA FIELDS

  Primary Keys:
      organism_id

  Columns:
      organism_id
      organism_name
      common_name_id

  Sequence:
      (sgn base schema).organism_organism_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table(__PACKAGE__->qualify_schema('sgn') . '.organism');

our @primary_key_names =
    qw/
      organism_id
      /;

our @column_names =
    qw/
      organism_id
      organism_name
      common_name_id
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('sgn').'.organism_organism_id_seq' );


###
1;#do not remove
###

