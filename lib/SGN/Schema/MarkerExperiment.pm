package SGN::Schema::MarkerExperiment;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("marker_experiment");
__PACKAGE__->add_columns(
  "marker_experiment_id",
  {
    data_type => "integer",
    default_value => "nextval('marker_experiment_marker_experiment_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "marker_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "pcr_experiment_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "rflp_experiment_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "location_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "protocol",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("marker_experiment_id");
__PACKAGE__->add_unique_constraint(
  "marker_experiment_pcr_experiment_id_key",
  ["pcr_experiment_id", "rflp_experiment_id", "location_id"],
);
__PACKAGE__->belongs_to(
  "pcr_experiment",
  "SGN::Schema::PcrExperiment",
  { pcr_experiment_id => "pcr_experiment_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "location",
  "SGN::Schema::MarkerLocation",
  { location_id => "location_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "rflp_experiment",
  "SGN::Schema::RflpMarker",
  { rflp_id => "rflp_experiment_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "marker",
  "SGN::Schema::Marker",
  { marker_id => "marker_id" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Kyh1yEJMn3Hy5Y5Ezh9rsA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
