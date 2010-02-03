package SGN::Schema::EstsMappedByClone;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ests_mapped_by_clone");
__PACKAGE__->add_columns(
  "embc_id",
  {
    data_type => "integer",
    default_value => "nextval('ests_mapped_by_clone_embc_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "marker_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "clone_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("embc_id");
__PACKAGE__->belongs_to(
  "marker",
  "SGN::Schema::Marker",
  { marker_id => "marker_id" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LGRHiplz8v+Ud7YW66y1OA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
