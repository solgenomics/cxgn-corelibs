package CXGN::Biosource::Schema::BsSampleElementRelation;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("bs_sample_element_relation");
__PACKAGE__->add_columns(
  "sample_element_relation_id",
  {
    data_type => "integer",
    default_value => "nextval('biosource.bs_sample_element_relation_sample_element_relation_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "sample_element_id_a",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "sample_element_id_b",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "relation_type",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("sample_element_relation_id");
__PACKAGE__->add_unique_constraint(
  "bs_sample_element_relation_pkey",
  ["sample_element_relation_id"],
);
__PACKAGE__->belongs_to(
  "sample_element_id_a",
  "CXGN::Biosource::Schema::BsSampleElement",
  { sample_element_id => "sample_element_id_a" },
);
__PACKAGE__->belongs_to(
  "sample_element_id_b",
  "CXGN::Biosource::Schema::BsSampleElement",
  { sample_element_id => "sample_element_id_b" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-18 11:49:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yfsjYQ3L+bcnDEqktwzi4g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
