package CXGN::Metadata::Schema::Comments;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("comments");
__PACKAGE__->add_columns(
  "comment_id",
  {
    data_type => "bigint",
    default_value => "nextval('metadata.comments_comment_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
    is_auto_increment => 1
  },
  "attribution_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "comment_text",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("comment_id");
__PACKAGE__->add_unique_constraint("comments_pkey", ["comment_id"]);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-01 09:34:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U0wXkh2Qna/R9qbQaIdCgg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
