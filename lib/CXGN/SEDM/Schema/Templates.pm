package CXGN::SEDM::Schema::Templates;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("templates");
__PACKAGE__->add_columns(
  "template_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.templates_template_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "template_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "template_type",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "platform_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "dbiref_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "dbiref_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("template_id");
__PACKAGE__->add_unique_constraint("templates_pkey", ["template_id"]);
__PACKAGE__->has_many(
  "cluster_expression_members",
  "CXGN::SEDM::Schema::ClusterExpressionMembers",
  { "foreign.template_id" => "self.template_id" },
);
__PACKAGE__->has_many(
  "correlation_analysis_members_template_a_ids",
  "CXGN::SEDM::Schema::CorrelationAnalysisMembers",
  { "foreign.template_a_id" => "self.template_id" },
);
__PACKAGE__->has_many(
  "correlation_analysis_members_template_b_ids",
  "CXGN::SEDM::Schema::CorrelationAnalysisMembers",
  { "foreign.template_b_id" => "self.template_id" },
);
__PACKAGE__->has_many(
  "expression_experiment_values",
  "CXGN::SEDM::Schema::ExpressionExperimentValues",
  { "foreign.template_id" => "self.template_id" },
);
__PACKAGE__->has_many(
  "expression_template_values",
  "CXGN::SEDM::Schema::ExpressionTemplateValues",
  { "foreign.template_id" => "self.template_id" },
);
__PACKAGE__->has_many(
  "probes",
  "CXGN::SEDM::Schema::Probes",
  { "foreign.template_id" => "self.template_id" },
);
__PACKAGE__->has_many(
  "stat_expression_template_values",
  "CXGN::SEDM::Schema::StatExpressionTemplateValues",
  { "foreign.template_id" => "self.template_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->belongs_to(
  "platform_id",
  "CXGN::SEDM::Schema::Platforms",
  { platform_id => "platform_id" },
);
__PACKAGE__->has_many(
  "templates_dbxrefs",
  "CXGN::SEDM::Schema::TemplatesDbxref",
  { "foreign.template_id" => "self.template_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aoBV4VG7vj+5sL3eufw9Yw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
