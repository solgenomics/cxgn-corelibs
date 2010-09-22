package CXGN::Metadata::Schema::AttributionTo;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("attribution_to");
__PACKAGE__->add_columns(
  "attribution_to_id",
  {
    data_type => "bigint",
    default_value => "nextval('metadata.attribution_to_attribution_to_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "attribution_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "person_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "organization_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "project_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "role_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("attribution_to_id");
__PACKAGE__->add_unique_constraint("attribution_to_pkey", ["attribution_to_id"]);
__PACKAGE__->belongs_to(
  "attribution_id",
  "CXGN::DB::Metadata::Schema::Attribution",
  { attribution_id => "attribution_id" },
);
__PACKAGE__->belongs_to(
  "role_id",
  "CXGN::DB::Metadata::Schema::Roles",
  { role_id => "role_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-01 09:34:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YuBQt9xJ6UalRQtuMptnUg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
