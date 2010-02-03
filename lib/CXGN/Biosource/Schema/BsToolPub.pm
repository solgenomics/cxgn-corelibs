package CXGN::Biosource::Schema::BsToolPub;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("bs_tool_pub");
__PACKAGE__->add_columns(
  "tool_pub_id",
  {
    data_type => "integer",
    default_value => "nextval('biosource.bs_tool_pub_tool_pub_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "tool_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "pub_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("tool_pub_id");
__PACKAGE__->add_unique_constraint("bs_tool_pub_pkey", ["tool_pub_id"]);
__PACKAGE__->belongs_to(
  "tool_id",
  "CXGN::Biosource::Schema::BsTool",
  { tool_id => "tool_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-18 11:49:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:A50ntnJq0jGolqqrFr0VoQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
