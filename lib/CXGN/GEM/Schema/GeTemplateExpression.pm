package CXGN::GEM::Schema::GeTemplateExpression;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_template_expression");
__PACKAGE__->add_columns(
  "template_expression_id",
  {
    data_type => "bigint",
    default_value => "nextval('gem.ge_template_expression_template_expression_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "hybridization_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "template_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "template_signal",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "template_signal_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "statistical_value",
  {
    data_type => "double precision",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "statistical_value_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "flag",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "dataset_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("template_expression_id");
__PACKAGE__->add_unique_constraint("ge_template_expression_pkey", ["template_expression_id"]);
__PACKAGE__->belongs_to(
  "template_id",
  "CXGN::GEM::Schema::GeTemplate",
  { template_id => "template_id" },
);
__PACKAGE__->belongs_to(
  "hybridization_id",
  "CXGN::GEM::Schema::GeHybridization",
  { hybridization_id => "hybridization_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-02-01 11:35:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YKzARGmy+/Fn9R3xdbgq4Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
