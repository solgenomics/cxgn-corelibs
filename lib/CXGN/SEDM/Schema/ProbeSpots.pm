package CXGN::SEDM::Schema::ProbeSpots;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("probe_spots");
__PACKAGE__->add_columns(
  "probe_spot_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.probe_spots_probe_spot_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "probe_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "spot_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("probe_spot_id");
__PACKAGE__->add_unique_constraint("probe_spots_pkey", ["probe_spot_id"]);
__PACKAGE__->has_many(
  "probe_spot_coordinates",
  "CXGN::SEDM::Schema::ProbeSpotCoordinates",
  { "foreign.probe_spot_id" => "self.probe_spot_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->belongs_to(
  "probe_id",
  "CXGN::SEDM::Schema::Probes",
  { probe_id => "probe_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KH7JYl99MkBrOV68iO90AQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
