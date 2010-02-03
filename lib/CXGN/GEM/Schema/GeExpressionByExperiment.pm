package CXGN::GEM::Schema::GeExpressionByExperiment;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_expression_by_experiment");
__PACKAGE__->add_columns(
  "expression_by_experiment_id",
  {
    data_type => "bigint",
    default_value => "nextval('gem.ge_expression_by_experiment_expression_by_experiment_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "experiment_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
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
  "dataset_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("expression_by_experiment_id");
__PACKAGE__->add_unique_constraint(
  "ge_expression_by_experiment_pkey",
  ["expression_by_experiment_id"],
);
__PACKAGE__->belongs_to(
  "template_id",
  "CXGN::GEM::Schema::GeTemplate",
  { template_id => "template_id" },
);
__PACKAGE__->belongs_to(
  "experiment_id",
  "CXGN::GEM::Schema::GeExperiment",
  { experiment_id => "experiment_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-24 17:00:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Of66O7Ca5fE/ANsQD7cXyw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
