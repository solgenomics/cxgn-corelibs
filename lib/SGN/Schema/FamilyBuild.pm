package SGN::Schema::FamilyBuild;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("family_build");
__PACKAGE__->add_columns(
  "family_build_id",
  {
    data_type => "bigint",
    default_value => "nextval('family_build_family_build_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "group_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "build_nr",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "i_value",
  {
    data_type => "double precision",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "build_date",
  {
    data_type => "timestamp without time zone",
    default_value => "('now'::text)::timestamp(6) with time zone",
    is_nullable => 0,
    size => 8,
  },
  "status",
  {
    data_type => "character",
    default_value => "'C'::bpchar",
    is_nullable => 1,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("family_build_id");
__PACKAGE__->has_many(
  "families",
  "SGN::Schema::Family",
  { "foreign.family_build_id" => "self.family_build_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7wifZAmGXzBAUd7SfYY/ag


# You can replace this text with custom content, and it will be preserved on regeneration
1;
