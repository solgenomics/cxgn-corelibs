package SGN::Schema::Organismprop;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("organismprop");
__PACKAGE__->add_columns(
  "organismprop_id",
  {
    data_type => "integer",
    default_value => "nextval('organismprop_organismprop_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "common_name_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "type_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "value",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 32,
  },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
);
__PACKAGE__->set_primary_key("organismprop_id");
__PACKAGE__->belongs_to(
  "common_name",
  "SGN::Schema::CommonName",
  { common_name_id => "common_name_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:t4Tyz3FkNnRzTzRyGCSMuA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
