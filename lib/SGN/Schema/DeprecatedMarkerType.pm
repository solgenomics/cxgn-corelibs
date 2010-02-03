package SGN::Schema::DeprecatedMarkerType;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("deprecated_marker_types");
__PACKAGE__->add_columns(
  "marker_type_id",
  {
    data_type => "integer",
    default_value => "nextval('deprecated_marker_types_marker_type_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "type_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "marker_table",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 128,
  },
);
__PACKAGE__->set_primary_key("marker_type_id");
__PACKAGE__->has_many(
  "deprecated_markers",
  "SGN::Schema::DeprecatedMarker",
  { "foreign.marker_type" => "self.marker_type_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MEeU2MrFDDFa1DfBsXv6Mw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
