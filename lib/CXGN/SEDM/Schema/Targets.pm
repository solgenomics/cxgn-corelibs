package CXGN::SEDM::Schema::Targets;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("targets");
__PACKAGE__->add_columns(
  "target_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.targets_target_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "target_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "experiment_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "sample_group_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "dye",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "datasource_url",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "dbxref_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("target_id");
__PACKAGE__->add_unique_constraint("targets_pkey", ["target_id"]);
__PACKAGE__->has_many(
  "expression_probe_values",
  "CXGN::SEDM::Schema::ExpressionProbeValues",
  { "foreign.target_id" => "self.target_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->belongs_to(
  "sample_group_id",
  "CXGN::SEDM::Schema::Groups",
  { group_id => "sample_group_id" },
);
__PACKAGE__->belongs_to(
  "experiment_id",
  "CXGN::SEDM::Schema::Experiments",
  { experiment_id => "experiment_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jO+WfB/Hk0BFvF1YvV7j9Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
