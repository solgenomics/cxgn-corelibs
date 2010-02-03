package SGN::Schema::CommonName;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("common_name");
__PACKAGE__->add_columns(
  "common_name_id",
  {
    data_type => "bigint",
    default_value => "nextval('common_name_common_name_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "common_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("common_name_id");
__PACKAGE__->add_unique_constraint("common_name_unique", ["common_name"]);
__PACKAGE__->has_many(
  "organisms",
  "SGN::Schema::Organism",
  { "foreign.common_name_id" => "self.common_name_id" },
);
__PACKAGE__->has_many(
  "organismprops",
  "SGN::Schema::Organismprop",
  { "foreign.common_name_id" => "self.common_name_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tbYoxZDGDjT/Ofi+4PbgIA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
