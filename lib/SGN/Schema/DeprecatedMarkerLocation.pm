package SGN::Schema::DeprecatedMarkerLocation;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("deprecated_marker_locations");
__PACKAGE__->add_columns(
  "marker_location_id",
  {
    data_type => "integer",
    default_value => "nextval('deprecated_marker_locations_marker_location_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "marker_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 8,
  },
  "loc_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 8,
  },
  "confidence",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 8,
  },
  "order_in_loc",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "location_subscript",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "mapmaker_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("marker_location_id");
__PACKAGE__->belongs_to(
  "loc",
  "SGN::Schema::DeprecatedMapdata",
  { loc_id => "loc_id" },
);
__PACKAGE__->belongs_to(
  "marker",
  "SGN::Schema::DeprecatedMarker",
  { marker_id => "marker_id" },
);
__PACKAGE__->belongs_to(
  "confidence",
  "SGN::Schema::DeprecatedMarkerConfidence",
  { legacy_conf_id => "confidence" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:E10c2r+ogjGVYXh/P5MTZQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
