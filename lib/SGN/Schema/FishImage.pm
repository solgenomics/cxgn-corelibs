package SGN::Schema::FishImage;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("fish_image");
__PACKAGE__->add_columns(
  "fish_image_id",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
  "filename",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "fish_result_id",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
);
__PACKAGE__->set_primary_key("fish_image_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ouk79KO/gIA1Lu8jVnGk9Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
