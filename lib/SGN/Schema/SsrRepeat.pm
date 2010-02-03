package SGN::Schema::SsrRepeat;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ssr_repeats");
__PACKAGE__->add_columns(
  "repeat_id",
  {
    data_type => "integer",
    default_value => "nextval('ssr_repeats_repeat_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "ssr_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 8,
  },
  "repeat_motif",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 32,
  },
  "reapeat_nr",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "marker_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
);
__PACKAGE__->set_primary_key("repeat_id");
__PACKAGE__->belongs_to("ssr", "SGN::Schema::Ssr", { ssr_id => "ssr_id" });
__PACKAGE__->belongs_to("marker", "SGN::Schema::Marker", { marker_id => "marker_id" });


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4MvWSZHgM6TpvARIiHW7hA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
