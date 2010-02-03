package SGN::Schema::DeprecatedMapCross;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("deprecated_map_cross");
__PACKAGE__->add_columns(
  "map_cross_id",
  {
    data_type => "integer",
    default_value => "nextval('deprecated_map_cross_map_cross_id_seq'::regclass)",
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
  "organism_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("map_cross_id");
__PACKAGE__->belongs_to(
  "organism",
  "SGN::Schema::Organism",
  { organism_id => "organism_id" },
);
__PACKAGE__->belongs_to("map", "SGN::Schema::DeprecatedMap", { map_id => "map_id" });


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LjKtQDgffWt7h7U8ST83Lw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
