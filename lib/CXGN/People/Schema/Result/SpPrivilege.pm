use utf8;
package CXGN::People::Schema::Result::SpPrivilege;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpPrivilege

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_privilege>

=cut

__PACKAGE__->table("sp_privilege");

=head1 ACCESSORS

=head2 sp_privilege_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_privilege_sp_privilege_id_seq'

=head2 sp_resource_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 sp_role_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 sp_access_level_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 require_ownership

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
    "sp_privilege_id",
    {
	data_type         => "integer",
	is_auto_increment => 1,
	is_nullable       => 0,
	sequence          => "sgn_people.sp_privilege_sp_privilege_id_seq",
    },
    "sp_resource_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
    "sp_role_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
    "sp_access_level_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
    "require_ownership",
    { data_type => "boolean", default_value => \"false", is_nullable => 1 },
    
    );

=head1 PRIMARY KEY

=over 4

=item * L</sp_privilege_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_privilege_id");

=head1 RELATIONS

=head2 sp_access_level

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpAccessLevel>

=cut

__PACKAGE__->belongs_to(
  "sp_access_level",
  "CXGN::People::Schema::Result::SpAccessLevel",
  { sp_access_level_id => "sp_access_level_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 sp_resource

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpResource>

=cut

__PACKAGE__->belongs_to(
  "sp_resource",
  "CXGN::People::Schema::Result::SpResource",
  { sp_resource_id => "sp_resource_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 sp_role

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpRole>

=cut

__PACKAGE__->belongs_to(
  "sp_role",
  "CXGN::People::Schema::Result::SpRole",
  { sp_role_id => "sp_role_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2023-12-31 10:26:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sZ7S5DkgTKFQdiy2pfdUmA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
