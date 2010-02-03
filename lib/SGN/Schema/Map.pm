package SGN::Schema::Map;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("map");
__PACKAGE__->add_columns(
  "map_id",
  {
    data_type => "integer",
    default_value => "nextval('map_map_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "short_name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "long_name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "abstract",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "map_type",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "parent_1",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "parent_2",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "units",
  {
    data_type => "text",
    default_value => "'cM'::text",
    is_nullable => 1,
    size => undef,
  },
  "ancestor",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
);
__PACKAGE__->set_primary_key("map_id");
__PACKAGE__->belongs_to(
  "ancestor",
  "SGN::Schema::Accession",
  { accession_id => "ancestor" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "parent_2",
  "SGN::Schema::Accession",
  { accession_id => "parent_2" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "parent_1",
  "SGN::Schema::Accession",
  { accession_id => "parent_1" },
  { join_type => "LEFT" },
);
__PACKAGE__->has_many(
  "map_versions",
  "SGN::Schema::MapVersion",
  { "foreign.map_id" => "self.map_id" },
);
__PACKAGE__->has_many(
  "pcr_experiments",
  "SGN::Schema::PcrExperiment",
  { "foreign.map_id" => "self.map_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VAbpsHO3jE5BVJ77K8dd5Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
