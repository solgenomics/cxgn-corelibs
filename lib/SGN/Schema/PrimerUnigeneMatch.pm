package SGN::Schema::PrimerUnigeneMatch;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("primer_unigene_match");
__PACKAGE__->add_columns(
  "primer_unigene_match_id",
  {
    data_type => "integer",
    default_value => "nextval('primer_unigene_match_primer_unigene_match_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "marker_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "unigene_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "primer_direction",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "match_length",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "primer_match_start",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "primer_match_end",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "unigene_match_start",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "unigene_match_end",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "e_value",
  {
    data_type => "double precision",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("primer_unigene_match_id");
__PACKAGE__->belongs_to(
  "unigene",
  "SGN::Schema::Unigene",
  { unigene_id => "unigene_id" },
);
__PACKAGE__->belongs_to("marker", "SGN::Schema::Marker", { marker_id => "marker_id" });


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Mhaa3OkVosYAiGnjcBjOpg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
