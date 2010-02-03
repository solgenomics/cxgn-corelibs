package SGN::Schema::GroupLinkage;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("group_linkage");
__PACKAGE__->add_columns(
  "group_linkage_id",
  {
    data_type => "integer",
    default_value => "nextval('group_linkage_group_linkage_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "group_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "member_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "member_type",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "member_value",
  {
    data_type => "bytea",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("group_linkage_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:x7MyQMDgy4P+S5MdYUYXqg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
