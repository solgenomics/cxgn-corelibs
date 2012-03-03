package SGN::Schema::Organismgroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Organismgroup

=cut

__PACKAGE__->table("organismgroup");

=head1 ACCESSORS

=head2 organismgroup_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'organismgroup_organismgroup_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 type

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "organismgroup_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "organismgroup_organismgroup_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "type",
  { data_type => "varchar", is_nullable => 1, size => 32 },
);
__PACKAGE__->set_primary_key("organismgroup_id");

=head1 RELATIONS

=head2 organismgroup_members

Type: has_many

Related object: L<SGN::Schema::OrganismgroupMember>

=cut

__PACKAGE__->has_many(
  "organismgroup_members",
  "SGN::Schema::OrganismgroupMember",
  { "foreign.organismgroup_id" => "self.organismgroup_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QLDS19A29tivXEZCMuRwTQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
