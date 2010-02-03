package SGN::Schema::Seqread;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("seqread");
__PACKAGE__->add_columns(
  "read_id",
  {
    data_type => "integer",
    default_value => "nextval('seqread_read_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "clone_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "facility_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "submitter_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "batch_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "primer",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "direction",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
  "trace_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 50,
  },
  "trace_location",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "attribution_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "date",
  {
    data_type => "timestamp without time zone",
    default_value => "('now'::text)::timestamp(6) with time zone",
    is_nullable => 0,
    size => 8,
  },
  "censor_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("read_id");
__PACKAGE__->has_many(
  "ests",
  "SGN::Schema::Est",
  { "foreign.read_id" => "self.read_id" },
);
__PACKAGE__->belongs_to(
  "clone",
  "SGN::Schema::Clone",
  { clone_id => "clone_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "facility",
  "SGN::Schema::Facility",
  { facility_id => "facility_id" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OK5Wvi7LzpT5n8sSpMkcww


# You can replace this text with custom content, and it will be preserved on regeneration
1;
