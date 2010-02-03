package SGN::Schema::FishResultComposite;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("fish_result_composite");
__PACKAGE__->add_columns(
  "fish_result_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "map_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "fish_experimenter_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "experiment_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "clone_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "chromo_num",
  {
    data_type => "smallint",
    default_value => "(0)::smallint",
    is_nullable => 0,
    size => 2,
  },
  "chromo_arm",
  {
    data_type => "character varying",
    default_value => "'P'::character varying",
    is_nullable => 0,
    size => 1,
  },
  "percent_from_centromere",
  {
    data_type => "real",
    default_value => "(0)::real",
    is_nullable => 0,
    size => 4,
  },
  "het_or_eu",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
  "um_from_centromere",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "um_from_arm_end",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "um_from_arm_border",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "mbp_from_arm_end",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "mbp_from_centromere",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "mbp_from_arm_border",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "experiment_group",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 12,
  },
);
__PACKAGE__->set_primary_key("fish_result_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Dqjpbir9VTv1xIIPs8nYkw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
