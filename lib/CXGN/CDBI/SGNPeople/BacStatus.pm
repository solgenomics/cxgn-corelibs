package CXGN::CDBI::SGNPeople::BacStatus;


=head1 DATA FIELDS

  Primary Keys:
      bac_status_id

  Columns:
      bac_status_id
      bac_id
      person_id
      status
      genbank_status
      timestamp

  Sequence:
      sgn_people.bac_status_bac_status_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table('sgn_people.bac_status');

our @primary_key_names =
    qw/
      bac_status_id
      /;

our @column_names =
    qw/
      bac_status_id
      bac_id
      person_id
      status
      genbank_status
      timestamp
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( 'sgn_people.bac_status_bac_status_id_seq' );



###
1;#do not remove
###
