package CXGN::GEM::Schema::GeExperiment;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_experiment");
__PACKAGE__->add_columns(
  "experiment_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_experiment_experiment_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "experiment_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "experimental_design_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
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
  "contact_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("experiment_id");
__PACKAGE__->add_unique_constraint("ge_experiment_pkey", ["experiment_id"]);
__PACKAGE__->add_unique_constraint(
  "ge_experiment_experiment_name_key",
  ["experiment_name", "experimental_design_id"],
);
__PACKAGE__->belongs_to(
  "experimental_design_id",
  "CXGN::GEM::Schema::GeExperimentalDesign",
  { "experimental_design_id" => "experimental_design_id" },
);
__PACKAGE__->has_many(
  "ge_experiment_analysis_members",
  "CXGN::GEM::Schema::GeExperimentAnalysisMember",
  { "foreign.experiment_id" => "self.experiment_id" },
);
__PACKAGE__->has_many(
  "ge_experiment_dbxrefs",
  "CXGN::GEM::Schema::GeExperimentDbxref",
  { "foreign.experiment_id" => "self.experiment_id" },
);
__PACKAGE__->has_many(
  "ge_expression_by_experiments",
  "CXGN::GEM::Schema::GeExpressionByExperiment",
  { "foreign.experiment_id" => "self.experiment_id" },
);
__PACKAGE__->has_many(
  "ge_profile_elements",
  "CXGN::GEM::Schema::GeProfileElement",
  { "foreign.experiment_id" => "self.experiment_id" },
);
__PACKAGE__->has_many(
  "ge_targets",
  "CXGN::GEM::Schema::GeTarget",
  { "foreign.experiment_id" => "self.experiment_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-24 17:00:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3aPuZD3SHnYqjqH5lGIENA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
