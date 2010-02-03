package CXGN::Metadata::Schema::MdDbiref;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("md_dbiref");
__PACKAGE__->add_columns(
  "dbiref_id",
  {
    data_type => "bigint",
    default_value => "nextval('metadata.md_dbiref_dbiref_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "iref_accession",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "dbipath_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("dbiref_id");
__PACKAGE__->add_unique_constraint("md_dbiref_pkey", ["dbiref_id"]);
__PACKAGE__->add_unique_constraint(
  "md_dbiref_iref_accession_key",
  ["iref_accession", "dbiref_id"],
);
__PACKAGE__->belongs_to(
  "dbipath_id",
  "CXGN::DB::Metadata::Schema::MdDbipath",
  { dbipath_id => "dbipath_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::DB::Metadata::Schema::MdMetadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->has_many(
  "md_groupmembers",
  "CXGN::DB::Metadata::Schema::MdGroupmembers",
  { "foreign.dbiref_id" => "self.dbiref_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-01 09:34:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QcBw5YdYHgtIaEW6e5+drw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
