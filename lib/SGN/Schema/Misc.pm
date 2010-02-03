package SGN::Schema::Misc;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("misc");
__PACKAGE__->add_columns(
  "misc_unique_id",
  {
    data_type => "integer",
    default_value => "nextval('misc_misc_unique_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "misc_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "value",
  {
    data_type => "bytea",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("misc_unique_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GdAgcG0jEjfTEGFmBJnCYg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
