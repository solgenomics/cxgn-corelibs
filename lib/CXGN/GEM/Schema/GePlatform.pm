package CXGN::GEM::Schema::GePlatform;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_platform");
__PACKAGE__->add_columns(
  "platform_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_platform_platform_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "technology_type_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
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
  "contact_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("platform_id");
__PACKAGE__->add_unique_constraint("ge_platform_pkey", ["platform_id"]);
__PACKAGE__->has_many(
  "ge_hybridizations",
  "CXGN::GEM::Schema::GeHybridization",
  { "foreign.platform_id" => "self.platform_id" },
);
__PACKAGE__->belongs_to(
  "technology_type_id",
  "CXGN::GEM::Schema::GeTechnologyType",
  { technology_type_id => "technology_type_id" },
);
__PACKAGE__->has_many(
  "ge_platform_dbxrefs",
  "CXGN::GEM::Schema::GePlatformDbxref",
  { "foreign.platform_id" => "self.platform_id" },
);
__PACKAGE__->has_many(
  "ge_platform_designs",
  "CXGN::GEM::Schema::GePlatformDesign",
  { "foreign.platform_id" => "self.platform_id" },
);
__PACKAGE__->has_many(
  "ge_platform_pubs",
  "CXGN::GEM::Schema::GePlatformPub",
  { "foreign.platform_id" => "self.platform_id" },
);
__PACKAGE__->has_many(
  "ge_probes",
  "CXGN::GEM::Schema::GeProbe",
  { "foreign.platform_id" => "self.platform_id" },
);
__PACKAGE__->has_many(
  "ge_templates",
  "CXGN::GEM::Schema::GeTemplate",
  { "foreign.platform_id" => "self.platform_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-02-01 11:35:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dilAUcPQeaqgYYxEpWrTGw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
