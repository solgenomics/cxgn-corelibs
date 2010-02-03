package CXGN::CDBI::SGN::Accession;

=head1 DATA FIELDS

  Primary Keys:
      accession_id

  Columns:
      accession_id
      organism_id
      common_name
      accession_name_id

  Sequence:
      (sgn base schema).accession_accession_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table(__PACKAGE__->qualify_schema('sgn') . '.accession');

our @primary_key_names =
    qw/
      accession_id
      /;

our @column_names =
    qw/
      accession_id
      organism_id
      common_name
      accession_name_id
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('sgn').'.accession_accession_id_seq' );


__PACKAGE__->has_a('accession_name_id' => 'CXGN::CDBI::SGN::AccessionNames');

sub accession_name {
  my $self = shift;
  return $self->accession_name_id->accession_name;
}

###
1;#do not remove
###

