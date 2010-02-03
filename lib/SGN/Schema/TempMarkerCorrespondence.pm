package SGN::Schema::TempMarkerCorrespondence;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("temp_marker_correspondence");
__PACKAGE__->add_columns(
  "tmc_id",
  {
    data_type => "integer",
    default_value => "nextval('temp_marker_correspondence_tmc_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "old_marker_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "new_marker_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("tmc_id");
__PACKAGE__->belongs_to(
  "old_marker",
  "SGN::Schema::DeprecatedMarker",
  { marker_id => "old_marker_id" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QHMHgueh9OFeL5+j4AA1mA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
