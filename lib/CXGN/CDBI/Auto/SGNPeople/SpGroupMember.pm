package CXGN::CDBI::Auto::SGNPeople::SpGroupMember;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::SGNPeople::SpGroupMember - object abstraction for rows in the sgn_people.sp_group_member table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:


  Columns:
      sp_person_id
      sp_group_id
      status

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'sgn_people.sp_group_member' );

our @primary_key_names =
    qw/

      /;

our @column_names =
    qw/
      sp_person_id
      sp_group_id
      status
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###
