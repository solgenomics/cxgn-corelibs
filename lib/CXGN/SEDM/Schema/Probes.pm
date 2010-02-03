package CXGN::SEDM::Schema::Probes;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("probes");
__PACKAGE__->add_columns(
  "probe_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.probes_probe_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "platform_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "probe_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "probe_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "sequence_file_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "template_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "template_start",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "template_end",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "primer_forward_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "primer_reverse_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("probe_id");
__PACKAGE__->add_unique_constraint("probes_probe_name_key", ["probe_name", "platform_id"]);
__PACKAGE__->add_unique_constraint("probes_pkey", ["probe_id"]);
__PACKAGE__->has_many(
  "expression_probe_values",
  "CXGN::SEDM::Schema::ExpressionProbeValues",
  { "foreign.probe_id" => "self.probe_id" },
);
__PACKAGE__->has_many(
  "probe_spots",
  "CXGN::SEDM::Schema::ProbeSpots",
  { "foreign.probe_id" => "self.probe_id" },
);
__PACKAGE__->belongs_to(
  "template_id",
  "CXGN::SEDM::Schema::Templates",
  { template_id => "template_id" },
);
__PACKAGE__->belongs_to(
  "primer_reverse_id",
  "CXGN::SEDM::Schema::Primers",
  { primer_id => "primer_reverse_id" },
);
__PACKAGE__->belongs_to(
  "platform_id",
  "CXGN::SEDM::Schema::Platforms",
  { platform_id => "platform_id" },
);
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
__PACKAGE__->belongs_to(
  "primer_forward_id",
  "CXGN::SEDM::Schema::Primers",
  { primer_id => "primer_forward_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:v38uXtFBrPqSTRbEj8HSog


# You can replace this text with custom content, and it will be preserved on regeneration
1;
