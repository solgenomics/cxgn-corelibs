package SGN::Schema::BlastDefline;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("blast_defline");
__PACKAGE__->add_columns(
  "defline_id",
  {
    data_type => "integer",
    default_value => "nextval('blast_defline_defline_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "blast_target_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "target_db_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "defline",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "defline_fulltext",
  {
    data_type => "tsvector",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "identifier_defline_fulltext",
  {
    data_type => "tsvector",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("defline_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8yU0F15zAHGCgzzTxjqR3A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
