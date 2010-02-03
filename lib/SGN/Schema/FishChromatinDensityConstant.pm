package SGN::Schema::FishChromatinDensityConstant;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("fish_chromatin_density_constants");
__PACKAGE__->add_columns(
  "arm",
  {
    data_type => "character varying",
    default_value => "'E'::character varying",
    is_nullable => 0,
    size => 1,
  },
  "density",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("arm");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dVbgqT3zCORAdxZMrBfn9g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
