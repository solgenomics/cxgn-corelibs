package SGN::Schema::Ssr;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ssr");
__PACKAGE__->add_columns(
  "ssr_id",
  {
    data_type => "integer",
    default_value => "nextval('ssr_ssr_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "marker_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 8,
  },
  "ssr_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "est_read_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "start_primer",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "end_primer",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "pcr_product_ln",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "tm_start_primer",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "tm_end_primer",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "ann_high",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "ann_low",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
);
__PACKAGE__->set_primary_key("ssr_id");
__PACKAGE__->belongs_to("marker", "SGN::Schema::Marker", { marker_id => "marker_id" });
__PACKAGE__->has_many(
  "ssr_primer_unigene_matches",
  "SGN::Schema::SsrPrimerUnigeneMatch",
  { "foreign.ssr_id" => "self.ssr_id" },
);
__PACKAGE__->has_many(
  "ssr_repeats",
  "SGN::Schema::SsrRepeat",
  { "foreign.ssr_id" => "self.ssr_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KsqiG9Iipum6TyPnH5ZRgQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
