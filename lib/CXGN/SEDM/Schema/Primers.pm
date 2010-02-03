package CXGN::SEDM::Schema::Primers;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("primers");
__PACKAGE__->add_columns(
  "primer_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.primers_primer_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "primer_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "sequence_file_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("primer_id");
__PACKAGE__->add_unique_constraint("primers_pkey", ["primer_id"]);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->belongs_to(
  "sequence_file_id",
  "CXGN::SEDM::Schema::SequencesFiles",
  { sequence_file_id => "sequence_file_id" },
);
__PACKAGE__->has_many(
  "probes_primer_reverse_ids",
  "CXGN::SEDM::Schema::Probes",
  { "foreign.primer_reverse_id" => "self.primer_id" },
);
__PACKAGE__->has_many(
  "probes_primer_forward_ids",
  "CXGN::SEDM::Schema::Probes",
  { "foreign.primer_forward_id" => "self.primer_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XZRTyFQ+LMHX02GlbxICEw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
