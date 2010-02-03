package SGN::Schema::BlastAnnotation;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("blast_annotations");
__PACKAGE__->add_columns(
  "blast_annotation_id",
  {
    data_type => "integer",
    default_value => "nextval('blast_annotations_blast_annotation_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "apply_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "apply_type",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "blast_target_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "n_hits",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "hits_stored",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "last_updated",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "host",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "pid",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("blast_annotation_id");
__PACKAGE__->add_unique_constraint(
  "blast_annotations_apply_id_blast_target_id_uq",
  ["apply_id", "blast_target_id"],
);
__PACKAGE__->belongs_to(
  "apply",
  "SGN::Schema::Unigene",
  { unigene_id => "apply_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->has_many(
  "blast_hits",
  "SGN::Schema::BlastHit",
  { "foreign.blast_annotation_id" => "self.blast_annotation_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:c25ns20ozFJhtQvjZZXq3Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
