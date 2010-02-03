package SGN::Schema::CosiiOrtholog;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("cosii_ortholog");
__PACKAGE__->add_columns(
  "cosii_unigene_id",
  {
    data_type => "bigint",
    default_value => "nextval('cosii_ortholog_cosii_unigene_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "marker_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "unigene_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "copies",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
  "database_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 11,
  },
  "sequence_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "edited_sequence_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "peptide_sequence_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "introns",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("cosii_unigene_id");
__PACKAGE__->belongs_to(
  "marker",
  "SGN::Schema::Marker",
  { marker_id => "marker_id" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3+cYN1Wvi8E9pql7xqxyQQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
