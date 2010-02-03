package SGN::Schema::PMarker;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("p_markers");
__PACKAGE__->add_columns(
  "pid",
  {
    data_type => "integer",
    default_value => "nextval('p_markers_pid_seq'::regclass)",
    is_auto_increment => 1,
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
  "est_clone_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "p_mrkr_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
);
__PACKAGE__->set_primary_key("pid");
__PACKAGE__->belongs_to("marker", "SGN::Schema::Marker", { marker_id => "marker_id" });


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:d9ZOQdC7WHhe7efaAvMTkA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
