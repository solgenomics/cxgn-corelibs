package SGN::Schema::TmMarker;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("tm_markers");
__PACKAGE__->add_columns(
  "tm_id",
  {
    data_type => "integer",
    default_value => "nextval('tm_markers_tm_id_seq'::regclass)",
    is_auto_increment => 1,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "marker_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 8,
  },
  "tm_name",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 32,
  },
  "old_cos_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "seq_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "est_read_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "comment",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("tm_id");
__PACKAGE__->belongs_to("marker", "SGN::Schema::Marker", { marker_id => "marker_id" });
__PACKAGE__->belongs_to("tm", "SGN::Schema::TmMarker", { tm_id => "tm_id" });
__PACKAGE__->might_have(
  "tm_marker",
  "SGN::Schema::TmMarker",
  { "foreign.tm_id" => "self.tm_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4A0prP6Kf6aJYrw/xOQPWg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
