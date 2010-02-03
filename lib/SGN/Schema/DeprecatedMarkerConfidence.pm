package SGN::Schema::DeprecatedMarkerConfidence;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("deprecated_marker_confidences");
__PACKAGE__->add_columns(
  "confidence_id",
  {
    data_type => "integer",
    default_value => "nextval('deprecated_marker_confidences_confidence_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "confidence_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 16,
  },
  "legacy_conf_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("confidence_id");
__PACKAGE__->add_unique_constraint("legacy_conf_id_unique", ["legacy_conf_id"]);
__PACKAGE__->has_many(
  "deprecated_marker_locations",
  "SGN::Schema::DeprecatedMarkerLocation",
  { "foreign.confidence" => "self.legacy_conf_id" },
);
__PACKAGE__->has_many(
  "map_versions",
  "SGN::Schema::MapVersion",
  { "foreign.default_threshold" => "self.confidence_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IawmsThhrP8yotxukwjC5A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
