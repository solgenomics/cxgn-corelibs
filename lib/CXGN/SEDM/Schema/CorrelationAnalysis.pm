package CXGN::SEDM::Schema::CorrelationAnalysis;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("correlation_analysis");
__PACKAGE__->add_columns(
  "correlation_analysis_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.correlation_analysis_correlation_analysis_id_seq'::regclass)",
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
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("correlation_analysis_id");
__PACKAGE__->add_unique_constraint("correlation_analysis_pkey", ["correlation_analysis_id"]);
__PACKAGE__->has_many(
  "cluster_expression_analyses",
  "CXGN::SEDM::Schema::ClusterExpressionAnalysis",
  {
    "foreign.correlation_analysis_id" => "self.correlation_analysis_id",
  },
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
__PACKAGE__->belongs_to(
  "experiment_group_id",
  "CXGN::SEDM::Schema::Groups",
  { group_id => "experiment_group_id" },
);
__PACKAGE__->has_many(
  "correlation_analysis_members",
  "CXGN::SEDM::Schema::CorrelationAnalysisMembers",
  {
    "foreign.correlation_analysis_id" => "self.correlation_analysis_id",
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OmnH3IzaJq4eOkmdcFphEA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
