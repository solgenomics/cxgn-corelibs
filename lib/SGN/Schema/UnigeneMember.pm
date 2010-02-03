package SGN::Schema::UnigeneMember;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("unigene_member");
__PACKAGE__->add_columns(
  "unigene_member_id",
  {
    data_type => "integer",
    default_value => "nextval('unigene_member_unigene_member_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "unigene_id",
  {
    data_type => "integer",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "est_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "start",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "stop",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "qstart",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "qend",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "dir",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("unigene_member_id");
__PACKAGE__->belongs_to(
  "unigene",
  "SGN::Schema::Unigene",
  { unigene_id => "unigene_id" },
);
__PACKAGE__->belongs_to(
  "est",
  "SGN::Schema::Est",
  { est_id => "est_id" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uGZKXAJHQWGHbYkl4yCpZw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
