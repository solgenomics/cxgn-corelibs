package SGN::Schema::DeprecatedMap;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("deprecated_maps");
__PACKAGE__->add_columns(
  "map_id",
  {
    data_type => "integer",
    default_value => "nextval('deprecated_maps_map_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "legacy_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "short_name",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 50,
  },
  "long_name",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 250,
  },
  "number_chromosomes",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "default_threshold",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "header",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "abstract",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "genetic_cross",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "population_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "population_size",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "seed_available",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "seed_url",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "deprecated_by",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 1,
    size => 8,
  },
  "map_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 7,
  },
);
__PACKAGE__->set_primary_key("map_id");
__PACKAGE__->has_many(
  "deprecated_linkage_groups",
  "SGN::Schema::DeprecatedLinkageGroup",
  { "foreign.map_id" => "self.map_id" },
);
__PACKAGE__->has_many(
  "deprecated_map_crosses",
  "SGN::Schema::DeprecatedMapCross",
  { "foreign.map_id" => "self.map_id" },
);
__PACKAGE__->has_many(
  "deprecated_mapdatas",
  "SGN::Schema::DeprecatedMapdata",
  { "foreign.map_id" => "self.map_id" },
);
__PACKAGE__->has_many(
  "fish_results",
  "SGN::Schema::FishResult",
  { "foreign.map_id" => "self.map_id" },
);
__PACKAGE__->has_many(
  "temp_map_correspondences",
  "SGN::Schema::TempMapCorrespondence",
  { "foreign.old_map_id" => "self.map_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZOA9St2Q2s4BDPphigt3FA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
