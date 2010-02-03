package CXGN::SEDM::Schema::ExperimentDataAnalysis;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("experiment_data_analysis");
__PACKAGE__->add_columns(
  "experiment_data_analysis_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.experiment_data_analysis_experiment_data_analysis_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "experiment_design_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "experiment_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "hybridization_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "data_filename",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "data_source_url",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "protocol_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "protocol_step",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("experiment_data_analysis_id");
__PACKAGE__->add_unique_constraint(
  "experiment_data_analysis_pkey",
  ["experiment_data_analysis_id"],
);
__PACKAGE__->belongs_to(
  "experiment_design_id",
  "CXGN::SEDM::Schema::ExperimentalDesigns",
  { "experimental_design_id" => "experiment_design_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->belongs_to(
  "protocol_id",
  "CXGN::SEDM::Schema::Protocols",
  { protocol_id => "protocol_id" },
);
__PACKAGE__->belongs_to(
  "experiment_id",
  "CXGN::SEDM::Schema::Experiments",
  { experiment_id => "experiment_id" },
);
__PACKAGE__->belongs_to(
  "hybridization_id",
  "CXGN::SEDM::Schema::Hybridizations",
  { hybridization_id => "hybridization_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:laUnAxbauCsnaVymQ6hB7A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
