package CXGN::SEDM::Schema::ClusterExpressionProfiles;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("cluster_expression_profiles");
__PACKAGE__->add_columns(
  "cluster_expression_profile_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.cluster_expression_profiles_cluster_expression_profile_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "cluster_expression_analysis_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "member_nr",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "profile_source",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("cluster_expression_profile_id");
__PACKAGE__->add_unique_constraint(
  "cluster_expression_profiles_pkey",
  ["cluster_expression_profile_id"],
);
__PACKAGE__->has_many(
  "cluster_expression_members",
  "CXGN::SEDM::Schema::ClusterExpressionMembers",
  {
    "foreign.cluster_expression_profile_id" => "self.cluster_expression_profile_id",
  },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->belongs_to(
  "cluster_expression_analysis_id",
  "CXGN::SEDM::Schema::ClusterExpressionAnalysis",
  {
    "cluster_expression_analysis_id" => "cluster_expression_analysis_id",
  },
);
__PACKAGE__->has_many(
  "profile_elements",
  "CXGN::SEDM::Schema::ProfileElements",
  {
    "foreign.cluster_expression_profile_id" => "self.cluster_expression_profile_id",
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HDspz7G192tGttkrt88O0Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
