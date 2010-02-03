package SGN::Schema::TigrtcTracking;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("tigrtc_tracking");
__PACKAGE__->add_columns(
  "tigrtc_tracking_id",
  {
    data_type => "integer",
    default_value => "nextval('tigrtc_tracking_tigrtc_tracking_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "tc_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "current_tc_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "tcindex_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("tigrtc_tracking_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4dLwJ0ZdTTQHmdD/NFQfvw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
