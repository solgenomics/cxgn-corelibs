package CXGN::GEM::Schema::GeExperimentAnalysisGroup;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_experiment_analysis_group");
__PACKAGE__->add_columns(
  "experiment_analysis_group_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_experiment_analysis_group_experiment_analysis_group_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "group_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "group_description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("experiment_analysis_group_id");
__PACKAGE__->add_unique_constraint(
  "ge_experiment_analysis_group_pkey",
  ["experiment_analysis_group_id"],
);
__PACKAGE__->has_many(
  "ge_cluster_analyses",
  "CXGN::GEM::Schema::GeClusterAnalysis",
  {
    "foreign.experiment_analysis_group_id" => "self.experiment_analysis_group_id",
  },
);
__PACKAGE__->has_many(
  "ge_correlation_analyses",
  "CXGN::GEM::Schema::GeCorrelationAnalysis",
  {
    "foreign.experiment_analysis_group_id" => "self.experiment_analysis_group_id",
  },
);
__PACKAGE__->has_many(
  "ge_diff_expressions",
  "CXGN::GEM::Schema::GeDiffExpression",
  {
    "foreign.experiment_analysis_group_id" => "self.experiment_analysis_group_id",
  },
);
__PACKAGE__->has_many(
  "ge_experiment_analysis_members",
  "CXGN::GEM::Schema::GeExperimentAnalysisMember",
  {
    "foreign.experiment_analysis_group_id" => "self.experiment_analysis_group_id",
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-24 17:00:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+DcLWnoiMoAzeIhLbM/Vbw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
