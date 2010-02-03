package CXGN::CDBI::SGN::AccessionNames;


=head1 DATA FIELDS

  Primary Keys:
      accession_name_id

  Columns:
      accession_name_id
      accession_name
      accession_id

  Sequence:
      (sgn base schema).accession_names_accession_name_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table(__PACKAGE__->qualify_schema('sgn') . '.accession_names');

our @primary_key_names =
    qw/
      accession_name_id
      /;

our @column_names =
    qw/
      accession_name_id
      accession_name
      accession_id
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('sgn').'.accession_names_accession_name_id_seq' );


#__PACKAGE__->has_a(accession_id => 'CXGN::CDBI::SGN::Accession');

###
1;#do not remove
###
