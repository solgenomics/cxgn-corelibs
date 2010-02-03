package SGN::Schema::DeprecatedMapdata;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("deprecated_mapdata");
__PACKAGE__->add_columns(
  "loc_id",
  {
    data_type => "integer",
    default_value => "nextval('deprecated_mapdata_loc_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "map_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 8,
  },
  "lg_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "offset",
  {
    data_type => "numeric",
    default_value => undef,
    is_nullable => 1,
    size => "5,8",
  },
  "loc_type",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "loc_order",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("loc_id");
__PACKAGE__->belongs_to("map", "SGN::Schema::DeprecatedMap", { map_id => "map_id" });
__PACKAGE__->belongs_to(
  "lg",
  "SGN::Schema::DeprecatedLinkageGroup",
  { lg_id => "lg_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->has_many(
  "deprecated_marker_locations",
  "SGN::Schema::DeprecatedMarkerLocation",
  { "foreign.loc_id" => "self.loc_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:h90SRjb5LA8LUlGbg0tQqg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
