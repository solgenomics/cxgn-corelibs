package SGN::Schema::MarkerConfidence;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("marker_confidence");
__PACKAGE__->add_columns(
  "confidence_id",
  {
    data_type => "integer",
    default_value => "nextval('marker_confidence_confidence_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "confidence_name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("confidence_id");
__PACKAGE__->add_unique_constraint("marker_confidence_confidence_name_key", ["confidence_name"]);
__PACKAGE__->has_many(
  "marker_locations",
  "SGN::Schema::MarkerLocation",
  { "foreign.confidence_id" => "self.confidence_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PLEAad4zj+tcQotey4ZxWQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
