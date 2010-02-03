package SGN::Schema::PcrExperiment;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("pcr_experiment");
__PACKAGE__->add_columns(
  "pcr_experiment_id",
  {
    data_type => "bigint",
    default_value => "nextval('pcr_experiment_pcr_experiment_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "marker_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "mg_concentration",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "annealing_temp",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "primer_id_fwd",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "primer_id_rev",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "subscript",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "experiment_type_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "map_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "additional_enzymes",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1023,
  },
  "primer_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 4,
  },
  "predicted",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "primer_id_pd",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "accession_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 7,
  },
);
__PACKAGE__->set_primary_key("pcr_experiment_id");
__PACKAGE__->has_many(
  "marker_experiments",
  "SGN::Schema::MarkerExperiment",
  { "foreign.pcr_experiment_id" => "self.pcr_experiment_id" },
);
__PACKAGE__->has_many(
  "pcr_exp_accessions",
  "SGN::Schema::PcrExpAccession",
  { "foreign.pcr_experiment_id" => "self.pcr_experiment_id" },
);
__PACKAGE__->belongs_to(
  "map",
  "SGN::Schema::Map",
  { map_id => "map_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "primer_id_fwd",
  "SGN::Schema::Sequence",
  { sequence_id => "primer_id_fwd" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "marker",
  "SGN::Schema::Marker",
  { marker_id => "marker_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "primer_id_rev",
  "SGN::Schema::Sequence",
  { sequence_id => "primer_id_rev" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "experiment_type",
  "SGN::Schema::ExperimentType",
  { experiment_type_id => "experiment_type_id" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5vVVTNXG2Bvq59KwYstpNw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
