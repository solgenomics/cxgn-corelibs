package SGN::Schema::BlastHit;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("blast_hits");
__PACKAGE__->add_columns(
  "blast_hit_id",
  {
    data_type => "integer",
    default_value => "nextval('blast_hits_blast_hit_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "blast_annotation_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "target_db_id",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "evalue",
  {
    data_type => "double precision",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "score",
  {
    data_type => "double precision",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "identity_percentage",
  {
    data_type => "double precision",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "apply_start",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "apply_end",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "defline_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("blast_hit_id");
__PACKAGE__->belongs_to(
  "blast_annotation",
  "SGN::Schema::BlastAnnotation",
  { blast_annotation_id => "blast_annotation_id" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QKBiP2cK+zwhJ7uLGcmmiQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
