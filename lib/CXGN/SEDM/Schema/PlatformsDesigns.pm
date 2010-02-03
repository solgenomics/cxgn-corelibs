package CXGN::SEDM::Schema::PlatformsDesigns;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("platforms_designs");
__PACKAGE__->add_columns(
  "platform_design_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.platforms_designs_platform_design_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "platform_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "organism_group_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "sequence_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "dbiref_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "dbiref_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("platform_design_id");
__PACKAGE__->add_unique_constraint("platforms_designs_pkey", ["platform_design_id"]);
__PACKAGE__->belongs_to(
  "platform_id",
  "CXGN::SEDM::Schema::Platforms",
  { platform_id => "platform_id" },
);
__PACKAGE__->belongs_to(
  "organism_group_id",
  "CXGN::SEDM::Schema::Groups",
  { group_id => "organism_group_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kGudLEgjElsezyAW3NiS0A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
