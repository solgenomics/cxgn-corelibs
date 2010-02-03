package SGN::Schema::MapVersion;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("map_version");
__PACKAGE__->add_columns(
  "map_version_id",
  {
    data_type => "integer",
    default_value => "nextval('map_version_map_version_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "map_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "date_loaded",
  { data_type => "date", default_value => undef, is_nullable => 1, size => 4 },
  "current_version",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
  "default_threshold",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "has_il",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
  "has_physical",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("map_version_id");
__PACKAGE__->has_many(
  "linkage_groups",
  "SGN::Schema::LinkageGroup",
  { "foreign.map_version_id" => "self.map_version_id" },
);
__PACKAGE__->belongs_to(
  "map",
  "SGN::Schema::Map",
  { map_id => "map_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "default_threshold",
  "SGN::Schema::DeprecatedMarkerConfidence",
  { confidence_id => "default_threshold" },
  { join_type => "LEFT" },
);
__PACKAGE__->has_many(
  "marker_locations",
  "SGN::Schema::MarkerLocation",
  { "foreign.map_version_id" => "self.map_version_id" },
);
__PACKAGE__->has_many(
  "temp_map_correspondences",
  "SGN::Schema::TempMapCorrespondence",
  { "foreign.map_version_id" => "self.map_version_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pmMIeYu513Kw/Cu3g6n72w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
