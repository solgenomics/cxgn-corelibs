package SGN::Schema::DeprecatedLinkageGroup;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("deprecated_linkage_groups");
__PACKAGE__->add_columns(
  "lg_id",
  {
    data_type => "bigint",
    default_value => "nextval('deprecated_linkage_groups_lg_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "map_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "lg_order",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "lg_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("lg_id");
__PACKAGE__->belongs_to(
  "map",
  "SGN::Schema::DeprecatedMap",
  { map_id => "map_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->has_many(
  "deprecated_mapdatas",
  "SGN::Schema::DeprecatedMapdata",
  { "foreign.lg_id" => "self.lg_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IxQiafwdCA59zz8+SsrNyg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
