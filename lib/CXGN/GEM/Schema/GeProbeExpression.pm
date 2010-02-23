package CXGN::GEM::Schema::GeProbeExpression;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_probe_expression");
__PACKAGE__->add_columns(
  "probe_expression_id",
  {
    data_type => "bigint",
    default_value => "nextval('gem.ge_probe_expression_probe_expression_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "target_element_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
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
  "dataset_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("probe_expression_id");
__PACKAGE__->add_unique_constraint("ge_probe_expression_pkey", ["probe_expression_id"]);
__PACKAGE__->belongs_to(
  "probe_id",
  "CXGN::GEM::Schema::GeProbe",
  { probe_id => "probe_id" },
);
__PACKAGE__->belongs_to(
  "target_element_id",
  "CXGN::GEM::Schema::GeTargetElement",
  { target_element_id => "target_element_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-02-01 11:35:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:j+aaCq9qNPWHUOQRZzNMhw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
