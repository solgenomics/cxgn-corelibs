package SGN::Schema::MarkerToMap;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("marker_to_map");
__PACKAGE__->add_columns(
  "marker_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "protocol",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "location_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "lg_name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "lg_order",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "position",
  {
    data_type => "numeric",
    default_value => undef,
    is_nullable => 1,
    size => "5,8",
  },
  "confidence_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "subscript",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
  "map_version_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "map_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "parent_1",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "parent_2",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "current_version",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EhyPmMx26Gdh59ZgLYvItg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
