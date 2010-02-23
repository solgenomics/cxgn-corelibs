package CXGN::GEM::Schema::GeDiffExpression;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_diff_expression");
__PACKAGE__->add_columns(
  "diff_expression_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_diff_expression_diff_expression_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "experiment_analysis_group_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "method",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "stat_significance_cutoff",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "stat_significance_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("diff_expression_id");
__PACKAGE__->add_unique_constraint("ge_diff_expression_pkey", ["diff_expression_id"]);
__PACKAGE__->belongs_to(
  "experiment_analysis_group_id",
  "CXGN::GEM::Schema::GeExperimentAnalysisGroup",
  {
    "experiment_analysis_group_id" => "experiment_analysis_group_id",
  },
);
__PACKAGE__->has_many(
  "ge_template_diff_expressions",
  "CXGN::GEM::Schema::GeTemplateDiffExpression",
  { "foreign.diff_expression_id" => "self.diff_expression_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-02-01 11:35:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YcvT0dfAD0QyHIXgIKH5QQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
