package CXGN::SEDM::Schema::Metadata;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("metadata");
__PACKAGE__->add_columns(
  "metadata_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.metadata_metadata_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "create_date",
  {
    data_type => "timestamp with time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "create_person_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "modified_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "modified_person_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "modification_note",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "previous_metadata_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "obsolete",
  { data_type => "integer", default_value => 0, is_nullable => 1, size => 4 },
  "obsolete_note",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("metadata_id");
__PACKAGE__->add_unique_constraint("metadata_pkey", ["metadata_id"]);
__PACKAGE__->has_many(
  "cluster_expression_analyses",
  "CXGN::SEDM::Schema::ClusterExpressionAnalysis",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "cluster_expression_members",
  "CXGN::SEDM::Schema::ClusterExpressionMembers",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "cluster_expression_profiles",
  "CXGN::SEDM::Schema::ClusterExpressionProfiles",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "correlation_analyses",
  "CXGN::SEDM::Schema::CorrelationAnalysis",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "correlation_analysis_members",
  "CXGN::SEDM::Schema::CorrelationAnalysisMembers",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "experiment_data_analyses",
  "CXGN::SEDM::Schema::ExperimentDataAnalysis",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "experimental_designs",
  "CXGN::SEDM::Schema::ExperimentalDesigns",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "experiments",
  "CXGN::SEDM::Schema::Experiments",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "expression_experiment_values",
  "CXGN::SEDM::Schema::ExpressionExperimentValues",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "expression_probe_values",
  "CXGN::SEDM::Schema::ExpressionProbeValues",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "expression_template_values",
  "CXGN::SEDM::Schema::ExpressionTemplateValues",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "group_linkages",
  "CXGN::SEDM::Schema::GroupLinkage",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "groups",
  "CXGN::SEDM::Schema::Groups",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "hybridizations",
  "CXGN::SEDM::Schema::Hybridizations",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "ontology_quantifieds",
  "CXGN::SEDM::Schema::OntologyQuantified",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "platforms",
  "CXGN::SEDM::Schema::Platforms",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "platforms_dbxrefs",
  "CXGN::SEDM::Schema::PlatformsDbxref",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "platforms_designs",
  "CXGN::SEDM::Schema::PlatformsDesigns",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "primers",
  "CXGN::SEDM::Schema::Primers",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "probe_spot_coordinates",
  "CXGN::SEDM::Schema::ProbeSpotCoordinates",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "probe_spots",
  "CXGN::SEDM::Schema::ProbeSpots",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "probes",
  "CXGN::SEDM::Schema::Probes",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "profile_elements",
  "CXGN::SEDM::Schema::ProfileElements",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "protocols",
  "CXGN::SEDM::Schema::Protocols",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "sample_dbxrefs",
  "CXGN::SEDM::Schema::SampleDbxref",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "samples",
  "CXGN::SEDM::Schema::Samples",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "sequences_files",
  "CXGN::SEDM::Schema::SequencesFiles",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "stat_expression_analyses",
  "CXGN::SEDM::Schema::StatExpressionAnalysis",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "stat_expression_template_values",
  "CXGN::SEDM::Schema::StatExpressionTemplateValues",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "step_protocol_parameters",
  "CXGN::SEDM::Schema::StepProtocolParameters",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "step_protocols",
  "CXGN::SEDM::Schema::StepProtocols",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "targets",
  "CXGN::SEDM::Schema::Targets",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "technology_types",
  "CXGN::SEDM::Schema::TechnologyTypes",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "templates",
  "CXGN::SEDM::Schema::Templates",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "templates_dbxrefs",
  "CXGN::SEDM::Schema::TemplatesDbxref",
  { "foreign.metadata_id" => "self.metadata_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aL2qKwbXMCHEKhJ7xX9ovQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
