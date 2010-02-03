package CXGN::Metadata::Schema::MdTag;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("md_tag");
__PACKAGE__->add_columns(
  "tag_id",
  {
    data_type => "integer",
    default_value => "nextval('md_tag_tag_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "sp_person_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "modified_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "create_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "obsolete",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("tag_id");
__PACKAGE__->add_unique_constraint("md_tag_pkey", ["tag_id"]);
__PACKAGE__->has_many(
  "md_tag_images",
  "CXGN::Metadata::Schema::MdTagImage",
  { "foreign.tag_id" => "self.tag_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-18 10:50:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ngL7OqK6fpnujYtxlUa8Yg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
