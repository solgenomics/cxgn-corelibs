package CXGN::SEDM::Schema::Platforms;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("platforms");
__PACKAGE__->add_columns(
  "platform_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.platforms_platform_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "technology_type_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "platform_name",
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
  "contact_person_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("platform_id");
__PACKAGE__->add_unique_constraint("platforms_pkey", ["platform_id"]);
__PACKAGE__->has_many(
  "hybridizations",
  "CXGN::SEDM::Schema::Hybridizations",
  { "foreign.platform_id" => "self.platform_id" },
);
__PACKAGE__->belongs_to(
  "technology_type_id",
  "CXGN::SEDM::Schema::TechnologyTypes",
  { technology_type_id => "technology_type_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->has_many(
  "platforms_dbxrefs",
  "CXGN::SEDM::Schema::PlatformsDbxref",
  { "foreign.platform_id" => "self.platform_id" },
);
__PACKAGE__->has_many(
  "platforms_designs",
  "CXGN::SEDM::Schema::PlatformsDesigns",
  { "foreign.platform_id" => "self.platform_id" },
);
__PACKAGE__->has_many(
  "probes",
  "CXGN::SEDM::Schema::Probes",
  { "foreign.platform_id" => "self.platform_id" },
);
__PACKAGE__->has_many(
  "templates",
  "CXGN::SEDM::Schema::Templates",
  { "foreign.platform_id" => "self.platform_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6zlLeJWn3idd1qQ83qqRpg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
