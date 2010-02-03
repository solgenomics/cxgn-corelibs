package SGN::Schema::Type;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("types");
__PACKAGE__->add_columns(
  "type_id",
  {
    data_type => "integer",
    default_value => "nextval('types_type_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "comment",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("type_id");
__PACKAGE__->has_many(
  "libraries",
  "SGN::Schema::Library",
  { "foreign.type" => "self.type_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bTeFTSAMcuk7+ABAxsNGDw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
