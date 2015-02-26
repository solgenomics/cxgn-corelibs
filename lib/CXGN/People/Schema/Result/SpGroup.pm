use utf8;
package CXGN::People::Schema::Result::SpGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpGroup

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_group>

=cut

__PACKAGE__->table("sp_group");

=head1 ACCESSORS

=head2 sp_group_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_group_sp_group_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sp_group_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_group_sp_group_id_seq",
  },
  "name",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "description",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_group_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_group_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<sp_group_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("sp_group_name_key", ["name"]);

=head1 RELATIONS

=head2 sp_group_members

Type: has_many

Related object: L<CXGN::People::Schema::Result::SpGroupMember>

=cut

__PACKAGE__->has_many(
  "sp_group_members",
  "CXGN::People::Schema::Result::SpGroupMember",
  { "foreign.sp_group_id" => "self.sp_group_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-26 16:04:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VcLdsFnMHifiH+sTcmDm5w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
