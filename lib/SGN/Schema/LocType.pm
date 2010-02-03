package SGN::Schema::LocType;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("loc_types");
__PACKAGE__->add_columns(
  "loc_type_id",
  {
    data_type => "integer",
    default_value => "nextval('loc_types_loc_type_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "type_code",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 10,
  },
  "type_name",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 12,
  },
);
__PACKAGE__->set_primary_key("loc_type_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RCbTZwAvN7ne+jOqxcgqvQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
