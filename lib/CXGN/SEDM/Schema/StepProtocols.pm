package CXGN::SEDM::Schema::StepProtocols;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("step_protocols");
__PACKAGE__->add_columns(
  "step_protocol_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.step_protocols_step_protocol_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "protocol_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "step",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "action",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "tool_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "tool_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "tool_dbxref",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("step_protocol_id");
__PACKAGE__->add_unique_constraint("step_protocols_pkey", ["step_protocol_id"]);
__PACKAGE__->has_many(
  "step_protocol_parameters",
  "CXGN::SEDM::Schema::StepProtocolParameters",
  { "foreign.step_protocol_id" => "self.step_protocol_id" },
);
__PACKAGE__->belongs_to(
  "protocol_id",
  "CXGN::SEDM::Schema::Protocols",
  { protocol_id => "protocol_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:m03d0bMQ7UBWDq6sEv/njA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
