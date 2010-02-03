package SGN::Schema::Clone;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("clone");
__PACKAGE__->add_columns(
  "clone_id",
  {
    data_type => "integer",
    default_value => "nextval('clone_clone_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "library_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "clone_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "clone_group_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("clone_id");
__PACKAGE__->add_unique_constraint("clone_name_library_id_unique", ["clone_name", "library_id"]);
__PACKAGE__->add_unique_constraint("library_id_clone_name_key", ["library_id", "clone_name"]);
__PACKAGE__->belongs_to(
  "library",
  "SGN::Schema::Library",
  { library_id => "library_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->has_many(
  "seqreads",
  "SGN::Schema::Seqread",
  { "foreign.clone_id" => "self.clone_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WutXkVOk1ZLogdSm2dveXA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
