package SGN::Schema::Group;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Group

=cut

__PACKAGE__->table("groups");

=head1 ACCESSORS

=head2 group_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'groups_group_id_seq'

=head2 type

  data_type: 'integer'
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "group_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "groups_group_id_seq",
  },
  "type",
  { data_type => "integer", is_nullable => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("group_id");

=head1 RELATIONS

=head2 unigenes_build

Type: has_many

Related object: L<SGN::Schema::UnigeneBuild>

=cut

__PACKAGE__->has_many(
  "unigenes_build",
  "SGN::Schema::UnigeneBuild",
  { "foreign.organism_group_id" => "self.group_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hLfMQICZ6B5wCnRaeNh3Ag


# You can replace this text with custom content, and it will be preserved on regeneration
1;
