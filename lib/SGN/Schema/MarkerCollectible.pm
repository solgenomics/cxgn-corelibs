package SGN::Schema::MarkerCollectible;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("marker_collectible");
__PACKAGE__->add_columns(
  "marker_collectible_dummy_id",
  {
    data_type => "integer",
    default_value => "nextval('marker_collectible_marker_collectible_dummy_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "marker_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "mc_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
);
__PACKAGE__->set_primary_key("marker_collectible_dummy_id");
__PACKAGE__->add_unique_constraint("marker_collectible_marker_id_key", ["marker_id", "mc_id"]);
__PACKAGE__->belongs_to("mc", "SGN::Schema::MarkerCollection", { mc_id => "mc_id" });
__PACKAGE__->belongs_to("marker", "SGN::Schema::Marker", { marker_id => "marker_id" });


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EtUEbTiZ2cwlutSGJD/rrw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
