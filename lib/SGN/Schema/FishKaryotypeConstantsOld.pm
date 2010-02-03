package SGN::Schema::FishKaryotypeConstantsOld;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("fish_karyotype_constants_old");
__PACKAGE__->add_columns(
  "chromo_num",
  {
    data_type => "smallint",
    default_value => "(0)::smallint",
    is_nullable => 0,
    size => 2,
  },
  "chromo_length",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "chromo_arm_ratio",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "short_arm_length",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "short_arm_eu_length",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "short_arm_het_length",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "long_arm_length",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "long_arm_eu_length",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "long_arm_het_length",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("chromo_num");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WfE8usSbJsTs11/oxc5Ajg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
