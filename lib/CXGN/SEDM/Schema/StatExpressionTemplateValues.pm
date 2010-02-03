package CXGN::SEDM::Schema::StatExpressionTemplateValues;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("stat_expression_template_values");
__PACKAGE__->add_columns(
  "stat_expression_template_value_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.stat_expression_template_valu_stat_expression_template_valu_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "stat_expression_analysis_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "template_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "analysis_group_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "stat_value",
  {
    data_type => "double precision",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "stat_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("stat_expression_template_value_id");
__PACKAGE__->add_unique_constraint(
  "stat_expression_template_values_pkey",
  ["stat_expression_template_value_id"],
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->belongs_to(
  "stat_expression_analysis_id",
  "CXGN::SEDM::Schema::StatExpressionAnalysis",
  { "stat_expression_analysis_id" => "stat_expression_analysis_id" },
);
__PACKAGE__->belongs_to(
  "analysis_group_id",
  "CXGN::SEDM::Schema::Groups",
  { group_id => "analysis_group_id" },
);
__PACKAGE__->belongs_to(
  "template_id",
  "CXGN::SEDM::Schema::Templates",
  { template_id => "template_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fLDWXfR+v1AZ1FobI3ZFag


# You can replace this text with custom content, and it will be preserved on regeneration
1;
