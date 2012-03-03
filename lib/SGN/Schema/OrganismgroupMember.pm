package SGN::Schema::OrganismgroupMember;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::OrganismgroupMember

=cut

__PACKAGE__->table("organismgroup_member");

=head1 ACCESSORS

=head2 organismgroup_member_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'organismgroup_member_organismgroup_member_id_seq'

=head2 organismgroup_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 organism_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "organismgroup_member_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "organismgroup_member_organismgroup_member_id_seq",
  },
  "organismgroup_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "organism_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("organismgroup_member_id");

=head1 RELATIONS

=head2 organismgroup

Type: belongs_to

Related object: L<SGN::Schema::Organismgroup>

=cut

__PACKAGE__->belongs_to(
  "organismgroup",
  "SGN::Schema::Organismgroup",
  { organismgroup_id => "organismgroup_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iQB7M/6+aoBB0vMOkJfWZQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
