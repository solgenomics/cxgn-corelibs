package SGN::Schema::IdLinkage;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("id_linkage");
__PACKAGE__->add_columns(
  "id_linkage_id",
  {
    data_type => "integer",
    default_value => "nextval('id_linkage_id_linkage_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "link_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "link_id_type",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "internal_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "internal_id_type",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("id_linkage_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oYcL2G3WGqzmIF85gIz0uQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
