package SGN::Schema::Family;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("family");
__PACKAGE__->add_columns(
  "family_id",
  {
    data_type => "bigint",
    default_value => "nextval('family_family_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "family_build_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "family_annotation",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "tree_log_file_location",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "tree_file_location",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "tree_taxa_number",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "tree_overlap_length",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "family_nr",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "member_count",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("family_id");
__PACKAGE__->belongs_to(
  "family_build",
  "SGN::Schema::FamilyBuild",
  { family_build_id => "family_build_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->has_many(
  "family_members",
  "SGN::Schema::FamilyMember",
  { "foreign.family_id" => "self.family_id" },
);
__PACKAGE__->has_many(
  "family_trees",
  "SGN::Schema::FamilyTree",
  { "foreign.family_id" => "self.family_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rkeY5UCmUyMW1xuxxozDAA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
