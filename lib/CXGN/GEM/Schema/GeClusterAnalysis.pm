package CXGN::GEM::Schema::GeClusterAnalysis;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_cluster_analysis");
__PACKAGE__->add_columns(
  "cluster_analysis_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_cluster_analysis_cluster_analysis_id_seq'::regclass)",
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
  "protocol_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
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
__PACKAGE__->set_primary_key("cluster_analysis_id");
__PACKAGE__->add_unique_constraint("ge_cluster_analysis_pkey", ["cluster_analysis_id"]);
__PACKAGE__->belongs_to(
  "correlation_analysis_id",
  "CXGN::GEM::Schema::GeCorrelationAnalysis",
  { "correlation_analysis_id" => "correlation_analysis_id" },
);
__PACKAGE__->belongs_to(
  "experiment_analysis_group_id",
  "CXGN::GEM::Schema::GeExperimentAnalysisGroup",
  {
    "experiment_analysis_group_id" => "experiment_analysis_group_id",
  },
);
__PACKAGE__->has_many(
  "ge_cluster_profiles",
  "CXGN::GEM::Schema::GeClusterProfile",
  { "foreign.cluster_analysis_id" => "self.cluster_analysis_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-24 17:00:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:T7sMdua7/co/YXVJWplKUA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
