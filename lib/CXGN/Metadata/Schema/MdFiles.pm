package CXGN::Metadata::Schema::MdFiles;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("md_files");
__PACKAGE__->add_columns(
  "file_id",
  {
    data_type => "integer",
    default_value => "nextval('metadata.md_files_file_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "basename",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "dirname",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "filetype",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "alt_filename",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "comment",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "md5checksum",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "urlsource",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "urlsource_md5checksum",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("file_id");
__PACKAGE__->add_unique_constraint("md_files_pkey", ["file_id"]);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::Metadata::Schema::MdMetadata",
  { metadata_id => "metadata_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-18 10:50:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QkbvrAAM/DIr1nKevY4D+g
# These lines were loaded from '/data/local/cxgn/core/perllib/CXGN/Metadata/Schema/MdFiles.pm' found in @INC.# They are now part of the custom portion of this file# for you to hand-edit.  If you do not either delete# this section or remove that file from @INC, this section# will be repeated redundantly when you re-create this# file again via Loader!

# End of lines loaded from '/data/local/cxgn/core/perllib/CXGN/Metadata/Schema/MdFiles.pm' 


# You can replace this text with custom content, and it will be preserved on regeneration
1;
