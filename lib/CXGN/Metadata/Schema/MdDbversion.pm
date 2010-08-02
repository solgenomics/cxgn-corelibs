package CXGN::Metadata::Schema::MdDbversion;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("md_dbversion");
__PACKAGE__->add_columns(
  "dbversion_id",
  {
    data_type => "integer",
    default_value => "nextval('md_dbversion_dbversion_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "patch_name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "patch_description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("dbversion_id");
__PACKAGE__->add_unique_constraint("md_dbversion_pkey", ["dbversion_id"]);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::DB::Metadata::Schema::MdMetadata",
  { metadata_id => "metadata_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-01 09:34:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dSJ/uLuyUBSG+ftl24lMeg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
