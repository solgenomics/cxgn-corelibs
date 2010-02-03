package SGN::Schema::Cd;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("cds");
__PACKAGE__->add_columns(
  "cds_id",
  {
    data_type => "bigint",
    default_value => "nextval('cds_cds_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "unigene_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "seq_text",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "seq_edits",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "protein_seq",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "begin",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "end",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "forward_reverse",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
  "run_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "score",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "method",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "frame",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "preferred",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
  "cds_seq",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "protein_feature_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("cds_id");
__PACKAGE__->belongs_to(
  "unigene",
  "SGN::Schema::Unigene",
  { unigene_id => "unigene_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->has_many(
  "domain_matches",
  "SGN::Schema::DomainMatch",
  { "foreign.cds_id" => "self.cds_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wh6CiS4uWY0VfH0yTtoUyQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
