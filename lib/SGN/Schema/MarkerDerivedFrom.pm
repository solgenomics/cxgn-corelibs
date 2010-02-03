package SGN::Schema::MarkerDerivedFrom;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("marker_derived_from");
__PACKAGE__->add_columns(
  "marker_derived_dummy_id",
  {
    data_type => "integer",
    default_value => "nextval('marker_derived_from_marker_derived_dummy_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "marker_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "derived_from_source_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "id_in_source",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("marker_derived_dummy_id");
__PACKAGE__->belongs_to(
  "derived_from_source",
  "SGN::Schema::DerivedFromSource",
  { "derived_from_source_id" => "derived_from_source_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "marker",
  "SGN::Schema::DeprecatedMarker",
  { marker_id => "marker_id" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:r92tl5lsU17+QAaDcwDA+A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
