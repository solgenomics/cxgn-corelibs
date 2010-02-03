package SGN::Schema::ManualCensorReason;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("manual_censor_reasons");
__PACKAGE__->add_columns(
  "censor_id",
  {
    data_type => "integer",
    default_value => "nextval('manual_censor_reasons_censor_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "reason",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("censor_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SX8GxhPLUj0Es62m0H+1Mg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
