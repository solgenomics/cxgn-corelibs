package CXGN::Biosource::Schema::BsSampleElement;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("bs_sample_element");
__PACKAGE__->add_columns(
  "sample_element_id",
  {
    data_type => "integer",
    default_value => "nextval('biosource.bs_sample_element_sample_element_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "sample_element_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "alternative_name",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "sample_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "organism_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "stock_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "protocol_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("sample_element_id");
__PACKAGE__->add_unique_constraint("bs_sample_element_pkey", ["sample_element_id"]);
__PACKAGE__->belongs_to(
  "protocol_id",
  "CXGN::Biosource::Schema::BsProtocol",
  { protocol_id => "protocol_id" },
);
__PACKAGE__->belongs_to(
  "sample_id",
  "CXGN::Biosource::Schema::BsSample",
  { sample_id => "sample_id" },
);
__PACKAGE__->has_many(
  "bs_sample_element_cvterms",
  "CXGN::Biosource::Schema::BsSampleElementCvterm",
  { "foreign.sample_element_id" => "self.sample_element_id" },
);
__PACKAGE__->has_many(
  "bs_sample_element_dbxrefs",
  "CXGN::Biosource::Schema::BsSampleElementDbxref",
  { "foreign.sample_element_id" => "self.sample_element_id" },
);
__PACKAGE__->has_many(
  "bs_sample_element_files",
  "CXGN::Biosource::Schema::BsSampleElementFile",
  { "foreign.sample_element_id" => "self.sample_element_id" },
);
__PACKAGE__->has_many(
  "bs_sample_element_relation_sample_element_id_as",
  "CXGN::Biosource::Schema::BsSampleElementRelation",
  { "foreign.sample_element_id_a" => "self.sample_element_id" },
);
__PACKAGE__->has_many(
  "bs_sample_element_relation_sample_element_id_bs",
  "CXGN::Biosource::Schema::BsSampleElementRelation",
  { "foreign.sample_element_id_b" => "self.sample_element_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-18 11:49:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mYvKQ2IeTAh6YW3Szrz77w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
