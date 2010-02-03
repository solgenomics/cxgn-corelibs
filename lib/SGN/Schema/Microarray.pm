package SGN::Schema::Microarray;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("microarray");
__PACKAGE__->add_columns(
  "microarray_id",
  {
    data_type => "integer",
    default_value => "nextval('microarray_microarray_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "chip_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "release",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "version",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "spot_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "content_specific_tag",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 40,
  },
  "clone_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("microarray_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:a52LI50lO2DcJ5YYwI/Xqg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
