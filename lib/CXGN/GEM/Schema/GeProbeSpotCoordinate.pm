package CXGN::GEM::Schema::GeProbeSpotCoordinate;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_probe_spot_coordinate");
__PACKAGE__->add_columns(
  "probe_spot_coordinate_id",
  {
    data_type => "bigint",
    default_value => "nextval('gem.ge_probe_spot_coordinate_probe_spot_coordinate_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "probe_spot_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "coordinate_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "coordinate_value",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("probe_spot_coordinate_id");
__PACKAGE__->add_unique_constraint("ge_probe_spot_coordinate_pkey", ["probe_spot_coordinate_id"]);
__PACKAGE__->belongs_to(
  "probe_spot_id",
  "CXGN::GEM::Schema::GeProbeSpot",
  { probe_spot_id => "probe_spot_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-02-01 11:35:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IlqXXIc2i7HOxB3ejFm1xA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
