use utf8;
package CXGN::People::Schema::Result::SpGroupMember;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpGroupMember

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_group_member>

=cut

__PACKAGE__->table("sp_group_member");

=head1 ACCESSORS

=head2 sp_person_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 sp_group_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 status

  data_type: 'text'
  default_value: 'active'
  is_nullable: 0
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "sp_person_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "sp_group_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "status",
  {
    data_type     => "text",
    default_value => "active",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
);

=head1 RELATIONS

=head2 sp_group

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpGroup>

=cut

__PACKAGE__->belongs_to(
  "sp_group",
  "CXGN::People::Schema::Result::SpGroup",
  { sp_group_id => "sp_group_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);

=head2 sp_person

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpPerson>

=cut

__PACKAGE__->belongs_to(
  "sp_person",
  "CXGN::People::Schema::Result::SpPerson",
  { sp_person_id => "sp_person_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-26 16:04:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gKKvufUo/yM6TtPGUuH5Rw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
