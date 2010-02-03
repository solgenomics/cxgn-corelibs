package CXGN::SEDM::Schema::ProbeSpotCoordinates;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("probe_spot_coordinates");
__PACKAGE__->add_columns(
  "probe_spot_coordinate_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.probe_spot_coordinates_probe_spot_coordinate_id_seq'::regclass)",
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
__PACKAGE__->add_unique_constraint("probe_spot_coordinates_pkey", ["probe_spot_coordinate_id"]);
__PACKAGE__->belongs_to(
  "probe_spot_id",
  "CXGN::SEDM::Schema::ProbeSpots",
  { probe_spot_id => "probe_spot_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vdyBiR88EcBGA832wXn4uQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
