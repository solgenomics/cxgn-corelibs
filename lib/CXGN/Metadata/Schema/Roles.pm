package CXGN::Metadata::Schema::Roles;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("roles");
__PACKAGE__->add_columns(
  "role_id",
  {
    data_type => "bigint",
    default_value => "nextval('metadata.roles_role_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
    is_auto_increment => 1
  },
  "role_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "role_description",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("role_id");
__PACKAGE__->add_unique_constraint("roles_pkey", ["role_id"]);
__PACKAGE__->has_many(
  "attribution_toes",
  "CXGN::DB::Metadata::Schema::AttributionTo",
  { "foreign.role_id" => "self.role_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-01 09:34:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rgj6T0YGYUHatV8h1G0Zow


# You can replace this text with custom content, and it will be preserved on regeneration
1;
