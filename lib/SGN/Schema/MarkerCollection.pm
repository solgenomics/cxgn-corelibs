package SGN::Schema::MarkerCollection;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("marker_collection");
__PACKAGE__->add_columns(
  "mc_id",
  {
    data_type => "integer",
    default_value => "nextval('marker_collection_mc_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "mc_name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "mc_description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("mc_id");
__PACKAGE__->add_unique_constraint("marker_collection_mc_name_key", ["mc_name"]);
__PACKAGE__->has_many(
  "marker_collectibles",
  "SGN::Schema::MarkerCollectible",
  { "foreign.mc_id" => "self.mc_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YALcddlZMO4e8TJX9om2ow


# You can replace this text with custom content, and it will be preserved on regeneration
1;
