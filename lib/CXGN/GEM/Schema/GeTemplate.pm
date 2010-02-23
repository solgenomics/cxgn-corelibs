package CXGN::GEM::Schema::GeTemplate;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_template");
__PACKAGE__->add_columns(
  "template_id",
  {
    data_type => "bigint",
    default_value => "nextval('gem.ge_template_template_id_seq'::regclass)",
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
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("template_id");
__PACKAGE__->add_unique_constraint("ge_template_pkey", ["template_id"]);
__PACKAGE__->has_many(
  "ge_cluster_members",
  "CXGN::GEM::Schema::GeClusterMember",
  { "foreign.template_id" => "self.template_id" },
);
__PACKAGE__->has_many(
  "ge_correlation_member_template_a_ids",
  "CXGN::GEM::Schema::GeCorrelationMember",
  { "foreign.template_a_id" => "self.template_id" },
);
__PACKAGE__->has_many(
  "ge_correlation_member_template_b_ids",
  "CXGN::GEM::Schema::GeCorrelationMember",
  { "foreign.template_b_id" => "self.template_id" },
);
__PACKAGE__->has_many(
  "ge_expression_by_experiments",
  "CXGN::GEM::Schema::GeExpressionByExperiment",
  { "foreign.template_id" => "self.template_id" },
);
__PACKAGE__->has_many(
  "ge_probes",
  "CXGN::GEM::Schema::GeProbe",
  { "foreign.template_id" => "self.template_id" },
);
__PACKAGE__->belongs_to(
  "platform_id",
  "CXGN::GEM::Schema::GePlatform",
  { platform_id => "platform_id" },
);
__PACKAGE__->has_many(
  "ge_template_dbirefs",
  "CXGN::GEM::Schema::GeTemplateDbiref",
  { "foreign.template_id" => "self.template_id" },
);
__PACKAGE__->has_many(
  "ge_template_dbxrefs",
  "CXGN::GEM::Schema::GeTemplateDbxref",
  { "foreign.template_id" => "self.template_id" },
);
__PACKAGE__->has_many(
  "ge_template_diff_expressions",
  "CXGN::GEM::Schema::GeTemplateDiffExpression",
  { "foreign.template_id" => "self.template_id" },
);
__PACKAGE__->has_many(
  "ge_template_expressions",
  "CXGN::GEM::Schema::GeTemplateExpression",
  { "foreign.template_id" => "self.template_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-02-01 11:35:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JR2Zb5ABMn5ut3ibrRyhzA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
