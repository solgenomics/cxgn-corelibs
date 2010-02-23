package CXGN::GEM::Schema::GeProbeSpot;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_probe_spot");
__PACKAGE__->add_columns(
  "probe_spot_id",
  {
    data_type => "bigint",
    default_value => "nextval('gem.ge_probe_spot_probe_spot_id_seq'::regclass)",
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
__PACKAGE__->add_unique_constraint("ge_probe_spot_pkey", ["probe_spot_id"]);
__PACKAGE__->belongs_to(
  "probe_id",
  "CXGN::GEM::Schema::GeProbe",
  { probe_id => "probe_id" },
);
__PACKAGE__->has_many(
  "ge_probe_spot_coordinates",
  "CXGN::GEM::Schema::GeProbeSpotCoordinate",
  { "foreign.probe_spot_id" => "self.probe_spot_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-02-01 11:35:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Yjg3QmHGBBKD3Af0uNPx2w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
