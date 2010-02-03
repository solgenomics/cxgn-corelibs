package CXGN::SEDM::Schema::GroupLinkage;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("group_linkage");
__PACKAGE__->add_columns(
  "group_linkage_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.group_linkage_group_linkage_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "group_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "member_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "member_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("group_linkage_id");
__PACKAGE__->add_unique_constraint("group_linkage_pkey", ["group_linkage_id"]);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->belongs_to(
  "group_id",
  "CXGN::SEDM::Schema::Groups",
  { group_id => "group_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QVmoEsoT+oZL3d4iGXLADg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
