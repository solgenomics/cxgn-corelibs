package CXGN::SEDM::Schema::SequencesFiles;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("sequences_files");
__PACKAGE__->add_columns(
  "sequence_file_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.sequences_files_sequence_file_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
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
  "md5_checksum",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("sequence_file_id");
__PACKAGE__->add_unique_constraint("sequences_files_pkey", ["sequence_file_id"]);
__PACKAGE__->has_many(
  "primers",
  "CXGN::SEDM::Schema::Primers",
  { "foreign.sequence_file_id" => "self.sequence_file_id" },
);
__PACKAGE__->has_many(
  "probes",
  "CXGN::SEDM::Schema::Probes",
  { "foreign.sequence_file_id" => "self.sequence_file_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DyK/PoFGLUCfWFSI4frt2A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
