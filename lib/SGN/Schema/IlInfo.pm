package SGN::Schema::IlInfo;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("il_info");
__PACKAGE__->add_columns(
  "ns_marker_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "sn_marker_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "map_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "map_version_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "population_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "ns_position",
  {
    data_type => "numeric",
    default_value => undef,
    is_nullable => 1,
    size => "5,8",
  },
  "sn_position",
  {
    data_type => "numeric",
    default_value => undef,
    is_nullable => 1,
    size => "5,8",
  },
  "name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "ns_alias",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "sn_alias",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "lg_name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Y2aYOpBgSIUTs+CFBn4Z2A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
