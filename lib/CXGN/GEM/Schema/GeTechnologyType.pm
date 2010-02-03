package CXGN::GEM::Schema::GeTechnologyType;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_technology_type");
__PACKAGE__->add_columns(
  "technology_type_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_technology_type_technology_type_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "technology_name",
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
__PACKAGE__->set_primary_key("technology_type_id");
__PACKAGE__->add_unique_constraint("ge_technology_type_pkey", ["technology_type_id"]);
__PACKAGE__->has_many(
  "ge_platforms",
  "CXGN::GEM::Schema::GePlatform",
  { "foreign.technology_type_id" => "self.technology_type_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-24 17:00:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:O+TZKGacQJXDCyyFD8Ejnw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
