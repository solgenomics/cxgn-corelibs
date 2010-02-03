package CXGN::GEM::Schema::GeCorrelationAnalysis;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_correlation_analysis");
__PACKAGE__->add_columns(
  "correlation_analysis_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_correlation_analysis_correlation_analysis_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "experiment_analysis_group_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "methodology",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
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
__PACKAGE__->add_unique_constraint("ge_correlation_analysis_pkey", ["correlation_analysis_id"]);
__PACKAGE__->has_many(
  "ge_cluster_analyses",
  "CXGN::GEM::Schema::GeClusterAnalysis",
  {
    "foreign.correlation_analysis_id" => "self.correlation_analysis_id",
  },
);
__PACKAGE__->belongs_to(
  "experiment_analysis_group_id",
  "CXGN::GEM::Schema::GeExperimentAnalysisGroup",
  {
    "experiment_analysis_group_id" => "experiment_analysis_group_id",
  },
);
__PACKAGE__->has_many(
  "ge_correlation_members",
  "CXGN::GEM::Schema::GeCorrelationMember",
  {
    "foreign.correlation_analysis_id" => "self.correlation_analysis_id",
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-24 17:00:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7wu2Nexw9l8Y822nQoTyfA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
