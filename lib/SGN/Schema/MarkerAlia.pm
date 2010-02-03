package SGN::Schema::MarkerAlia;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("marker_alias");
__PACKAGE__->add_columns(
  "alias_id",
  {
    data_type => "integer",
    default_value => "nextval('marker_alias_alias_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "alias",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "marker_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "preferred",
  {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 1,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("alias_id");
__PACKAGE__->add_unique_constraint("marker_alias_alias_key", ["alias"]);
__PACKAGE__->belongs_to("marker", "SGN::Schema::Marker", { marker_id => "marker_id" });


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QiT4n0BXlEhVqNqhBIsRzw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
