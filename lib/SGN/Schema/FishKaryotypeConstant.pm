package SGN::Schema::FishKaryotypeConstant;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("fish_karyotype_constants");
__PACKAGE__->add_columns(
  "fish_experimenter_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "chromo_num",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 0,
    size => 2,
  },
  "chromo_arm",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "arm_length",
  {
    data_type => "numeric",
    default_value => undef,
    is_nullable => 0,
    size => "2,5",
  },
  "arm_eu_length",
  {
    data_type => "numeric",
    default_value => undef,
    is_nullable => 0,
    size => "2,5",
  },
  "arm_het_length",
  {
    data_type => "numeric",
    default_value => undef,
    is_nullable => 0,
    size => "2,5",
  },
);
__PACKAGE__->set_primary_key("fish_experimenter_id", "chromo_num", "chromo_arm");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ttvFJoD3qnIp1c2pkWH+vQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
