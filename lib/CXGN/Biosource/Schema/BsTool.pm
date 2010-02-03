package CXGN::Biosource::Schema::BsTool;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("bs_tool");
__PACKAGE__->add_columns(
  "tool_id",
  {
    data_type => "integer",
    default_value => "nextval('biosource.bs_tool_tool_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "tool_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "tool_version",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "tool_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "tool_description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "tool_weblink",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "file_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("tool_id");
__PACKAGE__->add_unique_constraint("bs_tool_pkey", ["tool_id"]);
__PACKAGE__->has_many(
  "bs_protocol_steps",
  "CXGN::Biosource::Schema::BsProtocolStep",
  { "foreign.tool_id" => "self.tool_id" },
);
__PACKAGE__->has_many(
  "bs_tool_pubs",
  "CXGN::Biosource::Schema::BsToolPub",
  { "foreign.tool_id" => "self.tool_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-18 11:49:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:802ntSmx/I0HpneucCiFzg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
