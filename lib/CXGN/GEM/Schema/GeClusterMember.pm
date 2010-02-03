package CXGN::GEM::Schema::GeClusterMember;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_cluster_member");
__PACKAGE__->add_columns(
  "cluster_member_id",
  {
    data_type => "bigint",
    default_value => "nextval('gem.ge_cluster_member_cluster_member_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "template_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "cluster_profile_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("cluster_member_id");
__PACKAGE__->add_unique_constraint("ge_cluster_member_pkey", ["cluster_member_id"]);
__PACKAGE__->belongs_to(
  "template_id",
  "CXGN::GEM::Schema::GeTemplate",
  { template_id => "template_id" },
);
__PACKAGE__->belongs_to(
  "cluster_profile_id",
  "CXGN::GEM::Schema::GeClusterProfile",
  { cluster_profile_id => "cluster_profile_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-24 17:00:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oCgFQ2Dla+c6HeLrn4eG4g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
