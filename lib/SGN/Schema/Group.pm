package SGN::Schema::Group;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("groups");
__PACKAGE__->add_columns(
  "group_id",
  {
    data_type => "integer",
    default_value => "nextval('groups_group_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "type",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "comment",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("group_id");
__PACKAGE__->has_many(
  "unigene_builds",
  "SGN::Schema::UnigeneBuild",
  { "foreign.organism_group_id" => "self.group_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yOXQC5bAqXvLNXXk/+buAQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
