package SGN::Schema::BlastDb;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("blast_db");
__PACKAGE__->add_columns(
  "blast_db_id",
  {
    data_type => "integer",
    default_value => "nextval('blast_db_blast_db_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "file_base",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 120,
  },
  "title",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 80,
  },
  "type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "source_url",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "lookup_url",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "update_freq",
  {
    data_type => "character varying",
    default_value => "'monthly'::character varying",
    is_nullable => 0,
    size => 80,
  },
  "info_url",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "index_seqs",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
  "blast_db_group_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "web_interface_visible",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("blast_db_id");
__PACKAGE__->add_unique_constraint("blast_db_file_base_key", ["file_base"]);
__PACKAGE__->belongs_to(
  "blast_db_group",
  "SGN::Schema::BlastDbGroup",
  { blast_db_group_id => "blast_db_group_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->has_many(
  "unigene_builds",
  "SGN::Schema::UnigeneBuild",
  { "foreign.blast_db_id" => "self.blast_db_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dgwbxWK+Txu+tex3qf0BFg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
