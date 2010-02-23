package CXGN::GEM::Schema::GeTarget;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_target");
__PACKAGE__->add_columns(
  "target_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_target_target_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "target_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "experiment_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("target_id");
__PACKAGE__->add_unique_constraint("ge_target_target_name_key", ["target_name", "experiment_id"]);
__PACKAGE__->add_unique_constraint("ge_target_pkey", ["target_id"]);
__PACKAGE__->has_many(
  "ge_data_analysis_processes",
  "CXGN::GEM::Schema::GeDataAnalysisProcess",
  { "foreign.target_id" => "self.target_id" },
);
__PACKAGE__->has_many(
  "ge_hybridizations",
  "CXGN::GEM::Schema::GeHybridization",
  { "foreign.target_id" => "self.target_id" },
);
__PACKAGE__->belongs_to(
  "experiment_id",
  "CXGN::GEM::Schema::GeExperiment",
  { experiment_id => "experiment_id" },
);
__PACKAGE__->has_many(
  "ge_target_dbxrefs",
  "CXGN::GEM::Schema::GeTargetDbxref",
  { "foreign.target_id" => "self.target_id" },
);
__PACKAGE__->has_many(
  "ge_target_elements",
  "CXGN::GEM::Schema::GeTargetElement",
  { "foreign.target_id" => "self.target_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-02-01 11:35:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:M422nSgXBmrlUYBDuIB+fA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
