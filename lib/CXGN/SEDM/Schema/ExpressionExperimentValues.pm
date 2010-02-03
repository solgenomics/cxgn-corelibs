package CXGN::SEDM::Schema::ExpressionExperimentValues;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("expression_experiment_values");
__PACKAGE__->add_columns(
  "expression_experiment_value_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.expression_experiment_values_expression_experiment_value_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "experiment_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "template_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "replicates_used",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "mean",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "median",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "standard_desviation",
  {
    data_type => "double precision",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "coefficient_of_variance",
  {
    data_type => "double precision",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("expression_experiment_value_id");
__PACKAGE__->add_unique_constraint(
  "expression_experiment_values_pkey",
  ["expression_experiment_value_id"],
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->belongs_to(
  "template_id",
  "CXGN::SEDM::Schema::Templates",
  { template_id => "template_id" },
);
__PACKAGE__->belongs_to(
  "experiment_id",
  "CXGN::SEDM::Schema::Experiments",
  { experiment_id => "experiment_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1Ea6n/GDwKRQ7JnREEnmFw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
