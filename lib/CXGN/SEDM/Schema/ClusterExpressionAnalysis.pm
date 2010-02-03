package CXGN::SEDM::Schema::ClusterExpressionAnalysis;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("cluster_expression_analysis");
__PACKAGE__->add_columns(
  "cluster_expression_analysis_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.cluster_expression_analysis_cluster_expression_analysis_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "experiment_group_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "methodology",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "protocol_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "correlation_analysis_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("cluster_expression_analysis_id");
__PACKAGE__->add_unique_constraint(
  "cluster_expression_analysis_pkey",
  ["cluster_expression_analysis_id"],
);
__PACKAGE__->belongs_to(
  "experiment_group_id",
  "CXGN::SEDM::Schema::Groups",
  { group_id => "experiment_group_id" },
);
__PACKAGE__->belongs_to(
  "correlation_analysis_id",
  "CXGN::SEDM::Schema::CorrelationAnalysis",
  { "correlation_analysis_id" => "correlation_analysis_id" },
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
__PACKAGE__->has_many(
  "cluster_expression_profiles",
  "CXGN::SEDM::Schema::ClusterExpressionProfiles",
  {
    "foreign.cluster_expression_analysis_id" => "self.cluster_expression_analysis_id",
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:G0H8+XjWWpXaiUdyxy90UA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
