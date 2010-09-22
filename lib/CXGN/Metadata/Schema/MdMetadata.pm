package CXGN::Metadata::Schema::MdMetadata;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("md_metadata");
__PACKAGE__->add_columns(
  "metadata_id",
  {
    data_type => "bigint",
    default_value => "nextval('metadata.md_metadata_metadata_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "create_date",
  {
    data_type => "timestamp with time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "create_person_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "modified_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "modified_person_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "modification_note",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "previous_metadata_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "obsolete",
  { data_type => "integer", default_value => 0, is_nullable => 1, size => 4 },
  "obsolete_note",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "permission_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("metadata_id");
__PACKAGE__->add_unique_constraint("md_metadata_pkey", ["metadata_id"]);
__PACKAGE__->has_many(
  "md_dbipaths",
  "CXGN::DB::Metadata::Schema::MdDbipath",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "md_dbirefs",
  "CXGN::DB::Metadata::Schema::MdDbiref",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "md_dbversions",
  "CXGN::DB::Metadata::Schema::MdDbversion",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "md_files",
  "CXGN::DB::Metadata::Schema::MdFiles",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "md_groupmembers",
  "CXGN::DB::Metadata::Schema::MdGroupmembers",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "md_groups",
  "CXGN::DB::Metadata::Schema::MdGroups",
  { "foreign.metadata_id" => "self.metadata_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-01 09:34:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XOga0ug1CHeypx17EazhRg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
