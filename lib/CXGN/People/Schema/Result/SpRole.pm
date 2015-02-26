use utf8;
package CXGN::People::Schema::Result::SpRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpRole

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_roles>

=cut

__PACKAGE__->table("sp_roles");

=head1 ACCESSORS

=head2 sp_role_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_roles_sp_role_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=cut

__PACKAGE__->add_columns(
  "sp_role_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_roles_sp_role_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 20 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_role_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_role_id");

=head1 RELATIONS

=head2 sp_person_roles

Type: has_many

Related object: L<CXGN::People::Schema::Result::SpPersonRole>

=cut

__PACKAGE__->has_many(
  "sp_person_roles",
  "CXGN::People::Schema::Result::SpPersonRole",
  { "foreign.sp_role_id" => "self.sp_role_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-26 16:04:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:I+bCiKDCv7EkcJV/8tMtPg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
