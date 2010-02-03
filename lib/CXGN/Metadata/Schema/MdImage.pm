package CXGN::Metadata::Schema::MdImage;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("md_image");
__PACKAGE__->add_columns(
  "image_id",
  {
    data_type => "integer",
    default_value => "nextval('md_image_image_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "original_filename",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "file_ext",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "sp_person_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "modified_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "create_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "obsolete",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("image_id");
__PACKAGE__->add_unique_constraint("md_image_pkey", ["image_id"]);
__PACKAGE__->has_many(
  "md_tag_images",
  "CXGN::Metadata::Schema::MdTagImage",
  { "foreign.image_id" => "self.image_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-18 10:50:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HAtiB41vS4RKyMRU9p6DDw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
