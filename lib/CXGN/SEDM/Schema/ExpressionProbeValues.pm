package CXGN::SEDM::Schema::ExpressionProbeValues;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("expression_probe_values");
__PACKAGE__->add_columns(
  "expression_probe_value_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.expression_probe_values_expression_probe_value_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "target_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "probe_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "signal",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "signal_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "background",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "background_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "flag",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("expression_probe_value_id");
__PACKAGE__->add_unique_constraint("expression_probe_values_pkey", ["expression_probe_value_id"]);
__PACKAGE__->belongs_to(
  "probe_id",
  "CXGN::SEDM::Schema::Probes",
  { probe_id => "probe_id" },
);
__PACKAGE__->belongs_to(
  "target_id",
  "CXGN::SEDM::Schema::Targets",
  { target_id => "target_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HDa+gysNtnUMoRYkHlKLeQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
