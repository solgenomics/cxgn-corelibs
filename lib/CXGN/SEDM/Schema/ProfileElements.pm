package CXGN::SEDM::Schema::ProfileElements;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("profile_elements");
__PACKAGE__->add_columns(
  "profile_element_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.profile_elements_profile_element_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "cluster_expression_profile_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "experiment_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "experiment_predefined_position",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "element_mean_value",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "element_median_value",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "element_sd",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "element_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "previous_element_ratio",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("profile_element_id");
__PACKAGE__->add_unique_constraint("profile_elements_pkey", ["profile_element_id"]);
__PACKAGE__->belongs_to(
  "cluster_expression_profile_id",
  "CXGN::SEDM::Schema::ClusterExpressionProfiles",
  {
    "cluster_expression_profile_id" => "cluster_expression_profile_id",
  },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->belongs_to(
  "experiment_id",
  "CXGN::SEDM::Schema::Experiments",
  { experiment_id => "experiment_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BGfQLosPAhDJoO//C+KOQg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
