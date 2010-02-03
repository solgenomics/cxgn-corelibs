package SGN::Schema::FishResult;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("fish_result");
__PACKAGE__->add_columns(
  "fish_result_id",
  {
    data_type => "bigint",
    default_value => "nextval('fish_result_fish_result_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "map_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 8,
  },
  "fish_experimenter_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "experiment_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 10,
  },
  "clone_id",
  { data_type => "bigint", default_value => undef, is_nullable => 0, size => 8 },
  "chromo_num",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 0,
    size => 2,
  },
  "chromo_arm",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 1,
  },
  "percent_from_centromere",
  { data_type => "real", default_value => undef, is_nullable => 0, size => 4 },
  "experiment_group",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 12,
  },
  "attribution_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("fish_result_id");
__PACKAGE__->add_unique_constraint(
  "fish_result_fish_experimenter_clone_id_experiment_name",
  ["fish_experimenter_id", "clone_id", "experiment_name"],
);
__PACKAGE__->belongs_to(
  "fish_experimenter",
  "SGN::Schema::FishExperimenter",
  { fish_experimenter_id => "fish_experimenter_id" },
);
__PACKAGE__->belongs_to("map", "SGN::Schema::DeprecatedMap", { map_id => "map_id" });


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:u6gmDcAvOElivbc5PM6u9A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
