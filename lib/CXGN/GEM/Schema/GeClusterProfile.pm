package CXGN::GEM::Schema::GeClusterProfile;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_cluster_profile");
__PACKAGE__->add_columns(
  "cluster_profile_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_cluster_profile_cluster_profile_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "cluster_analysis_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "member_nr",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "file_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("cluster_profile_id");
__PACKAGE__->add_unique_constraint("ge_cluster_profile_pkey", ["cluster_profile_id"]);
__PACKAGE__->has_many(
  "ge_cluster_members",
  "CXGN::GEM::Schema::GeClusterMember",
  { "foreign.cluster_profile_id" => "self.cluster_profile_id" },
);
__PACKAGE__->belongs_to(
  "cluster_analysis_id",
  "CXGN::GEM::Schema::GeClusterAnalysis",
  { cluster_analysis_id => "cluster_analysis_id" },
);
__PACKAGE__->has_many(
  "ge_profile_elements",
  "CXGN::GEM::Schema::GeProfileElement",
  { "foreign.cluster_profile_id" => "self.cluster_profile_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-24 17:00:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7o0j4QTPgaB3rLmcecKdbA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
