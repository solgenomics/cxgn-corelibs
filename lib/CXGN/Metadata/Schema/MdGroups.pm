package CXGN::Metadata::Schema::MdGroups;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("md_groups");
__PACKAGE__->add_columns(
  "group_id",
  {
    data_type => "bigint",
    default_value => "nextval('md_groups_group_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "group_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "group_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "group_description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("group_id");
__PACKAGE__->add_unique_constraint("md_groups_pkey", ["group_id"]);
__PACKAGE__->add_unique_constraint("md_groups_group_name_key", ["group_name"]);
__PACKAGE__->has_many(
  "md_groupmembers",
  "CXGN::DB::Metadata::Schema::MdGroupmembers",
  { "foreign.group_id" => "self.group_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::DB::Metadata::Schema::MdMetadata",
  { metadata_id => "metadata_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-01 09:34:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:C/nDhOnK4uJjn/P61Ol3Ig


# You can replace this text with custom content, and it will be preserved on regeneration
1;
