package SGN::Schema::TigrtcIndex;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("tigrtc_index");
__PACKAGE__->add_columns(
  "tcindex_id",
  {
    data_type => "integer",
    default_value => "nextval('tigrtc_index_tcindex_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "index_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 40,
  },
);
__PACKAGE__->set_primary_key("tcindex_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WR09mxZ1fvmOYge6y21SmA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
