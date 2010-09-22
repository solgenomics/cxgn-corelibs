package CXGN::Metadata::Schema::MdDbipath;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("md_dbipath");
__PACKAGE__->add_columns(
  "dbipath_id",
  {
    data_type => "integer",
    default_value => "nextval('metadata.md_dbipath_dbipath_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "column_name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "table_name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "schema_name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("dbipath_id");
__PACKAGE__->add_unique_constraint(
  "md_dbipath_column_name_key",
  ["column_name", "table_name", "schema_name"],
);
__PACKAGE__->add_unique_constraint("md_dbipath_pkey", ["dbipath_id"]);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::DB::Metadata::Schema::MdMetadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->has_many(
  "md_dbirefs",
  "CXGN::DB::Metadata::Schema::MdDbiref",
  { "foreign.dbipath_id" => "self.dbipath_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-01 09:34:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U7Dcm9oAtau0LTh/nZyaIA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
