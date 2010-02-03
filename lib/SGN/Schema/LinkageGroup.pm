package SGN::Schema::LinkageGroup;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("linkage_group");
__PACKAGE__->add_columns(
  "lg_id",
  {
    data_type => "integer",
    default_value => "nextval('linkage_group_lg_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "map_version_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "lg_order",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "lg_name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "north_location_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "south_location_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
);
__PACKAGE__->set_primary_key("lg_id");
__PACKAGE__->add_unique_constraint(
  "linkage_group_map_version_id_key",
  ["map_version_id", "lg_order"],
);
__PACKAGE__->add_unique_constraint(
  "linkage_group_map_version_id_key1",
  ["map_version_id", "lg_name"],
);
__PACKAGE__->belongs_to(
  "north_location",
  "SGN::Schema::MarkerLocation",
  { location_id => "north_location_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "map_version",
  "SGN::Schema::MapVersion",
  { map_version_id => "map_version_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "south_location",
  "SGN::Schema::MarkerLocation",
  { location_id => "south_location_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->has_many(
  "marker_locations",
  "SGN::Schema::MarkerLocation",
  { "foreign.lg_id" => "self.lg_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kh9JvYZOT21+HyY29JBGdA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
