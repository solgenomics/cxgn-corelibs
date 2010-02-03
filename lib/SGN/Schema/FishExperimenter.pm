package SGN::Schema::FishExperimenter;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("fish_experimenter");
__PACKAGE__->add_columns(
  "fish_experimenter_id",
  {
    data_type => "integer",
    default_value => "nextval('fish_experimenter_fish_experimenter_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "fish_experimenter_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
);
__PACKAGE__->set_primary_key("fish_experimenter_id");
__PACKAGE__->add_unique_constraint("fish_expermenter_name_uniq", ["fish_experimenter_name"]);
__PACKAGE__->has_many(
  "fish_results",
  "SGN::Schema::FishResult",
  { "foreign.fish_experimenter_id" => "self.fish_experimenter_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ocoSQMPPyQCzpoTisbvC0g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
