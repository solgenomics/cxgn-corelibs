package SGN::Schema::Family;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Family

=cut

__PACKAGE__->table("family");

=head1 ACCESSORS

=head2 family_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'family_family_id_seq'

=head2 family_build_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 family_annotation

  data_type: 'text'
  is_nullable: 1

=head2 tree_log_file_location

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 tree_file_location

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 tree_taxa_number

  data_type: 'integer'
  is_nullable: 1

=head2 tree_overlap_length

  data_type: 'integer'
  is_nullable: 1

=head2 family_nr

  data_type: 'integer'
  is_nullable: 1

=head2 member_count

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "family_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "family_family_id_seq",
  },
  "family_build_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "family_annotation",
  { data_type => "text", is_nullable => 1 },
  "tree_log_file_location",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "tree_file_location",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "tree_taxa_number",
  { data_type => "integer", is_nullable => 1 },
  "tree_overlap_length",
  { data_type => "integer", is_nullable => 1 },
  "family_nr",
  { data_type => "integer", is_nullable => 1 },
  "member_count",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("family_id");

=head1 RELATIONS

=head2 family_build

Type: belongs_to

Related object: L<SGN::Schema::FamilyBuild>

=cut

__PACKAGE__->belongs_to(
  "family_build",
  "SGN::Schema::FamilyBuild",
  { family_build_id => "family_build_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 family_members

Type: has_many

Related object: L<SGN::Schema::FamilyMember>

=cut

__PACKAGE__->has_many(
  "family_members",
  "SGN::Schema::FamilyMember",
  { "foreign.family_id" => "self.family_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 family_trees

Type: has_many

Related object: L<SGN::Schema::FamilyTree>

=cut

__PACKAGE__->has_many(
  "family_trees",
  "SGN::Schema::FamilyTree",
  { "foreign.family_id" => "self.family_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:b0V0phWXlABHu1CSjK8XfA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
