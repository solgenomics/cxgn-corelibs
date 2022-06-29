package CXGN::Metadata::Schema::Attribution;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("attribution");
__PACKAGE__->add_columns(
  "attribution_id",
  {
    data_type => "bigint",
    default_value => "nextval('metadata.attribution_attribution_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "database_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "table_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "primary_key_column_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "row_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("attribution_id");
__PACKAGE__->add_unique_constraint("attribution_pkey", ["attribution_id"]);
__PACKAGE__->add_unique_constraint(
  "referred_to_db_row_unique",
  ["database_name", "table_name", "row_id"],
);
__PACKAGE__->has_many(
  "attribution_toes",
  "CXGN::DB::Metadata::Schema::AttributionTo",
  { "foreign.attribution_id" => "self.attribution_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-01 09:34:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5N1MKSfuE5tb8N4Qc/dlrw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
