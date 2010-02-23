package CXGN::GEM::Schema::GeProfileElement;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_profile_element");
__PACKAGE__->add_columns(
  "profile_element_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_profile_element_profile_element_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "cluster_profile_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "experiment_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
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
__PACKAGE__->add_unique_constraint("ge_profile_element_pkey", ["profile_element_id"]);
__PACKAGE__->belongs_to(
  "experiment_id",
  "CXGN::GEM::Schema::GeExperiment",
  { experiment_id => "experiment_id" },
);
__PACKAGE__->belongs_to(
  "cluster_profile_id",
  "CXGN::GEM::Schema::GeClusterProfile",
  { cluster_profile_id => "cluster_profile_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-02-01 11:35:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:41J+FBVVE0O/jid1/z0ngA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
