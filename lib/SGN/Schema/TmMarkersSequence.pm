package SGN::Schema::TmMarkersSequence;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("tm_markers_sequences");
__PACKAGE__->add_columns(
  "tm_marker_seq_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "tm_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "sequence",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "comment",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("tm_marker_seq_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:J7ci1jsVdv+jjqL27VoojA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
