package CXGN::CDBI::Auto::SGNPeople::SpOrganizationPerson;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::SGNPeople::SpOrganizationPerson - object abstraction for rows in the sgn_people.sp_organization_person table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      sp_organization_person_id

  Columns:
      sp_organization_person_id
      sp_organization_id
      sp_person_id

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'sgn_people.sp_organization_person' );

our @primary_key_names =
    qw/
      sp_organization_person_id
      /;

our @column_names =
    qw/
      sp_organization_person_id
      sp_organization_id
      sp_person_id
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###
