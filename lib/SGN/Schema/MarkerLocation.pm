package SGN::Schema::MarkerLocation;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("marker_location");
__PACKAGE__->add_columns(
  "location_id",
  {
    data_type => "integer",
    default_value => "nextval('marker_location_location_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "lg_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "map_version_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "position",
  {
    data_type => "numeric",
    default_value => undef,
    is_nullable => 0,
    size => "5,8",
  },
  "confidence_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "subscript",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("location_id");
__PACKAGE__->has_many(
  "linkage_group_north_location_ids",
  "SGN::Schema::LinkageGroup",
  { "foreign.north_location_id" => "self.location_id" },
);
__PACKAGE__->has_many(
  "linkage_group_south_location_ids",
  "SGN::Schema::LinkageGroup",
  { "foreign.south_location_id" => "self.location_id" },
);
__PACKAGE__->has_many(
  "marker_experiments",
  "SGN::Schema::MarkerExperiment",
  { "foreign.location_id" => "self.location_id" },
);
__PACKAGE__->belongs_to("lg", "SGN::Schema::LinkageGroup", { lg_id => "lg_id" });
__PACKAGE__->belongs_to(
  "confidence",
  "SGN::Schema::MarkerConfidence",
  { confidence_id => "confidence_id" },
);
__PACKAGE__->belongs_to(
  "map_version",
  "SGN::Schema::MapVersion",
  { map_version_id => "map_version_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hU7wmPdERZMKq01VIQMbXw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
