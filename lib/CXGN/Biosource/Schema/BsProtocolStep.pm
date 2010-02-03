package CXGN::Biosource::Schema::BsProtocolStep;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("bs_protocol_step");
__PACKAGE__->add_columns(
  "protocol_step_id",
  {
    data_type => "integer",
    default_value => "nextval('biosource.bs_protocol_step_protocol_step_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "protocol_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "step",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "action",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "execution",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "tool_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "begin_date",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "end_date",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "location",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("protocol_step_id");
__PACKAGE__->add_unique_constraint("bs_protocol_step_pkey", ["protocol_step_id"]);
__PACKAGE__->belongs_to(
  "protocol_id",
  "CXGN::Biosource::Schema::BsProtocol",
  { protocol_id => "protocol_id" },
);
__PACKAGE__->belongs_to(
  "tool_id",
  "CXGN::Biosource::Schema::BsTool",
  { tool_id => "tool_id" },
);
__PACKAGE__->has_many(
  "bs_protocol_step_dbxrefs",
  "CXGN::Biosource::Schema::BsProtocolStepDbxref",
  { "foreign.protocol_step_id" => "self.protocol_step_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-18 11:49:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tIhirU0zvFTmSymsqUjOXw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
