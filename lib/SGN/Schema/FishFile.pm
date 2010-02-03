package SGN::Schema::FishFile;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("fish_file");
__PACKAGE__->add_columns(
  "fish_file_id",
  {
    data_type => "bigint",
    default_value => "nextval('fish_file_fish_file_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "filename",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "fish_result_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("fish_file_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:r8PqTUqIYaUIWKv0E6nrVQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
