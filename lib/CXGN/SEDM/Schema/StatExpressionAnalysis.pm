package CXGN::SEDM::Schema::StatExpressionAnalysis;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("stat_expression_analysis");
__PACKAGE__->add_columns(
  "stat_expression_analysis_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.stat_expression_analysis_stat_expression_analysis_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "experiment_group_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "method",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "protocol_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "stat_significance_cutoff",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "stat_significance_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("stat_expression_analysis_id");
__PACKAGE__->add_unique_constraint(
  "stat_expression_analysis_pkey",
  ["stat_expression_analysis_id"],
);
__PACKAGE__->belongs_to(
  "experiment_group_id",
  "CXGN::SEDM::Schema::Groups",
  { group_id => "experiment_group_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->belongs_to(
  "protocol_id",
  "CXGN::SEDM::Schema::Protocols",
  { protocol_id => "protocol_id" },
);
__PACKAGE__->has_many(
  "stat_expression_template_values",
  "CXGN::SEDM::Schema::StatExpressionTemplateValues",
  {
    "foreign.stat_expression_analysis_id" => "self.stat_expression_analysis_id",
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7q4Rq7RoDqRx6I2j3JLA2g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
