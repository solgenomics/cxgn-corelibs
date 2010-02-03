package CXGN::Metadata::Schema::MdTagImage;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("md_tag_image");
__PACKAGE__->add_columns(
  "tag_image_id",
  {
    data_type => "integer",
    default_value => "nextval('md_tag_image_tag_image_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "image_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "tag_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "obsolete",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "sp_person_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "create_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "modified_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("tag_image_id");
__PACKAGE__->add_unique_constraint("md_tag_image_pkey", ["tag_image_id"]);
__PACKAGE__->belongs_to(
  "tag_id",
  "CXGN::Metadata::Schema::MdTag",
  { tag_id => "tag_id" },
);
__PACKAGE__->belongs_to(
  "image_id",
  "CXGN::Metadata::Schema::MdImage",
  { image_id => "image_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-18 10:50:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Y8INk3NL9XtmYUs61YBWWQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
