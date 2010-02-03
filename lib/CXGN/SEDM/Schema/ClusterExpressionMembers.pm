package CXGN::SEDM::Schema::ClusterExpressionMembers;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("cluster_expression_members");
__PACKAGE__->add_columns(
  "cluster_expression_member_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.cluster_expression_members_cluster_expression_member_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "template_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "cluster_expression_profile_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("cluster_expression_member_id");
__PACKAGE__->add_unique_constraint(
  "cluster_expression_members_pkey",
  ["cluster_expression_member_id"],
);
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
  "template_id",
  "CXGN::SEDM::Schema::Templates",
  { template_id => "template_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6ycbPx7zCpUm8KryfWp+bw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
