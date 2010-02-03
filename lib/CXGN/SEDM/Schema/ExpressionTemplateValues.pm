package CXGN::SEDM::Schema::ExpressionTemplateValues;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("expression_template_values");
__PACKAGE__->add_columns(
  "expression_template_value_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.expression_template_values_expression_template_value_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "hybridization_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
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
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("expression_template_value_id");
__PACKAGE__->add_unique_constraint(
  "expression_template_values_pkey",
  ["expression_template_value_id"],
);
__PACKAGE__->belongs_to(
  "template_id",
  "CXGN::SEDM::Schema::Templates",
  { template_id => "template_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->belongs_to(
  "hybridization_id",
  "CXGN::SEDM::Schema::Hybridizations",
  { hybridization_id => "hybridization_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JwI0CW2mk4GyU0kb43+rUA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
