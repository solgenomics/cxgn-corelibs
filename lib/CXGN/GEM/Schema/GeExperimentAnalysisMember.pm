package CXGN::GEM::Schema::GeExperimentAnalysisMember;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_experiment_analysis_member");
__PACKAGE__->add_columns(
  "experiment_analysis_member_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_experiment_analysis_member_experiment_analysis_member_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "experiment_analysis_group_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "experiment_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("experiment_analysis_member_id");
__PACKAGE__->add_unique_constraint(
  "ge_experiment_analysis_member_pkey",
  ["experiment_analysis_member_id"],
);
__PACKAGE__->belongs_to(
  "experiment_analysis_group_id",
  "CXGN::GEM::Schema::GeExperimentAnalysisGroup",
  {
    "experiment_analysis_group_id" => "experiment_analysis_group_id",
  },
);
__PACKAGE__->belongs_to(
  "experiment_id",
  "CXGN::GEM::Schema::GeExperiment",
  { experiment_id => "experiment_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-24 17:00:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8S6leVxUR5alHK9zBVN4Zg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
