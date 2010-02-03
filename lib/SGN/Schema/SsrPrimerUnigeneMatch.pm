package SGN::Schema::SsrPrimerUnigeneMatch;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ssr_primer_unigene_matches");
__PACKAGE__->add_columns(
  "ssr_primer_unigene_match_id",
  {
    data_type => "integer",
    default_value => "nextval('ssr_primer_unigene_matches_ssr_primer_unigene_match_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "ssr_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 8,
  },
  "unigene_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 8,
  },
  "primer_direction",
  {
    data_type => "smallint",
    default_value => "(0)::smallint",
    is_nullable => 0,
    size => 2,
  },
  "match_length",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "primer_match_start",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "primer_match_end",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "unigene_match_start",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "unigene_match_end",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "e_value",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 32,
  },
);
__PACKAGE__->set_primary_key("ssr_primer_unigene_match_id");
__PACKAGE__->belongs_to("ssr", "SGN::Schema::Ssr", { ssr_id => "ssr_id" });
__PACKAGE__->belongs_to(
  "unigene",
  "SGN::Schema::Unigene",
  { unigene_id => "unigene_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GZ6q121kHisxdchL9pmQgg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
