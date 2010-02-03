package SGN::Schema::DeprecatedMarker;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("deprecated_markers");
__PACKAGE__->add_columns(
  "marker_id",
  {
    data_type => "integer",
    default_value => "nextval('deprecated_markers_marker_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "marker_type",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 8,
  },
  "marker_name",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 32,
  },
);
__PACKAGE__->set_primary_key("marker_id");
__PACKAGE__->has_many(
  "deprecated_marker_locations",
  "SGN::Schema::DeprecatedMarkerLocation",
  { "foreign.marker_id" => "self.marker_id" },
);
__PACKAGE__->belongs_to(
  "marker_type",
  "SGN::Schema::DeprecatedMarkerType",
  { marker_type_id => "marker_type" },
);
__PACKAGE__->has_many(
  "marker_derived_froms",
  "SGN::Schema::MarkerDerivedFrom",
  { "foreign.marker_id" => "self.marker_id" },
);
__PACKAGE__->has_many(
  "temp_marker_correspondences",
  "SGN::Schema::TempMarkerCorrespondence",
  { "foreign.old_marker_id" => "self.marker_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iq+mw1tzL17MWwDwqZaCIQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
