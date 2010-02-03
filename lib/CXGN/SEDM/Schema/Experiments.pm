package CXGN::SEDM::Schema::Experiments;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("experiments");
__PACKAGE__->add_columns(
  "experiment_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.experiments_experiment_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "experiment_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "experimental_design_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "replicates_nr",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "colour_nr",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "contact_person_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "dbxref_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("experiment_id");
__PACKAGE__->add_unique_constraint("experiments_pkey", ["experiment_id"]);
__PACKAGE__->has_many(
  "experiment_data_analyses",
  "CXGN::SEDM::Schema::ExperimentDataAnalysis",
  { "foreign.experiment_id" => "self.experiment_id" },
);
__PACKAGE__->belongs_to(
  "experimental_design_id",
  "CXGN::SEDM::Schema::ExperimentalDesigns",
  { "experimental_design_id" => "experimental_design_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->has_many(
  "expression_experiment_values",
  "CXGN::SEDM::Schema::ExpressionExperimentValues",
  { "foreign.experiment_id" => "self.experiment_id" },
);
__PACKAGE__->has_many(
  "profile_elements",
  "CXGN::SEDM::Schema::ProfileElements",
  { "foreign.experiment_id" => "self.experiment_id" },
);
__PACKAGE__->has_many(
  "targets",
  "CXGN::SEDM::Schema::Targets",
  { "foreign.experiment_id" => "self.experiment_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JtGMfL4ItbcMMhNTGuEulw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
