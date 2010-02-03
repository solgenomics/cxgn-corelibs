package CXGN::GEM::Schema::GeExperimentDbxref;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_experiment_dbxref");
__PACKAGE__->add_columns(
  "experiment_dbxref_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_experiment_dbxref_experiment_dbxref_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "experiment_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "dbxref_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("experiment_dbxref_id");
__PACKAGE__->add_unique_constraint("ge_experiment_dbxref_pkey", ["experiment_dbxref_id"]);
__PACKAGE__->belongs_to(
  "experiment_id",
  "CXGN::GEM::Schema::GeExperiment",
  { experiment_id => "experiment_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-24 17:00:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JGzP0LAW/voeCmnx//agSA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
