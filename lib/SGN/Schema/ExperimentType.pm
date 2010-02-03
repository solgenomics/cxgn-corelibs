package SGN::Schema::ExperimentType;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("experiment_type");
__PACKAGE__->add_columns(
  "experiment_type_id",
  {
    data_type => "bigint",
    default_value => "nextval('experiment_type_experiment_type_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("experiment_type_id");
__PACKAGE__->has_many(
  "pcr_experiments",
  "SGN::Schema::PcrExperiment",
  { "foreign.experiment_type_id" => "self.experiment_type_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dTcoOxFqZW86L0MPWpZ3uA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
