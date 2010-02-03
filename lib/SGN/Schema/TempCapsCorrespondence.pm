package SGN::Schema::TempCapsCorrespondence;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("temp_caps_correspondence");
__PACKAGE__->add_columns(
  "tcc_id",
  {
    data_type => "integer",
    default_value => "nextval('temp_caps_correspondence_tcc_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "old_marker_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "new_marker_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("tcc_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:075hFpD8CmiOz0QSbguBIw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
