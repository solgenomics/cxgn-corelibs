package SGN::Schema::UnigeneBuild;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("unigene_build");
__PACKAGE__->add_columns(
  "unigene_build_id",
  {
    data_type => "integer",
    default_value => "nextval('unigene_build_unigene_build_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "source_data_group_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "organism_group_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "build_nr",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "build_date",
  { data_type => "date", default_value => "now()", is_nullable => 1, size => 4 },
  "method_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "status",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
  "comment",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "superseding_build_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "next_build_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "latest_build_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "blast_db_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
);
__PACKAGE__->set_primary_key("unigene_build_id");
__PACKAGE__->has_many(
  "unigenes",
  "SGN::Schema::Unigene",
  { "foreign.unigene_build_id" => "self.unigene_build_id" },
);
__PACKAGE__->belongs_to(
  "superseding_build",
  "SGN::Schema::UnigeneBuild",
  { unigene_build_id => "superseding_build_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->has_many(
  "unigene_build_superseding_build_ids",
  "SGN::Schema::UnigeneBuild",
  { "foreign.superseding_build_id" => "self.unigene_build_id" },
);
__PACKAGE__->belongs_to(
  "organism_group",
  "SGN::Schema::Group",
  { group_id => "organism_group_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "next_build",
  "SGN::Schema::UnigeneBuild",
  { unigene_build_id => "next_build_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->has_many(
  "unigene_build_next_build_ids",
  "SGN::Schema::UnigeneBuild",
  { "foreign.next_build_id" => "self.unigene_build_id" },
);
__PACKAGE__->belongs_to(
  "latest_build",
  "SGN::Schema::UnigeneBuild",
  { unigene_build_id => "latest_build_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->has_many(
  "unigene_build_latest_build_ids",
  "SGN::Schema::UnigeneBuild",
  { "foreign.latest_build_id" => "self.unigene_build_id" },
);
__PACKAGE__->belongs_to(
  "blast_db",
  "SGN::Schema::BlastDb",
  { blast_db_id => "blast_db_id" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mO2nyOFlE+C9IHPdBeygug


# You can replace this text with custom content, and it will be preserved on regeneration
1;
