package SGN::Schema::TrimFeature;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("trim_feature");
__PACKAGE__->add_columns(
  "feature_id",
  {
    data_type => "integer",
    default_value => "nextval('trim_feature_feature_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "est_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "start",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "end",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "type",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "value",
  {
    data_type => "bytea",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("feature_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PNFx1WjR7/0Uob/+OqII3g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
