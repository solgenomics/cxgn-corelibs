package SGN::Schema::DerivedFromSource;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("derived_from_source");
__PACKAGE__->add_columns(
  "derived_from_source_id",
  {
    data_type => "integer",
    default_value => "nextval('derived_from_source_derived_from_source_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "source_name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
    accessor => 'src_name',
  },
  "source_schema",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "source_table",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "source_col",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("derived_from_source_id");
__PACKAGE__->add_unique_constraint(
  "derived_from_source_source_schema_key",
  ["source_schema", "source_table", "source_col"],
);
__PACKAGE__->has_many(
  "marker_derived_froms",
  "SGN::Schema::MarkerDerivedFrom",
  {
    "foreign.derived_from_source_id" => "self.derived_from_source_id",
  },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iO+7Ly1A1UJAl8Me2IPnEg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
