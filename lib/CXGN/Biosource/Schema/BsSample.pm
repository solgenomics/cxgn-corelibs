package CXGN::Biosource::Schema::BsSample;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("bs_sample");
__PACKAGE__->add_columns(
  "sample_id",
  {
    data_type => "integer",
    default_value => "nextval('biosource.bs_sample_sample_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "sample_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "sample_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "contact_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("sample_id");
__PACKAGE__->add_unique_constraint("bs_sample_pkey", ["sample_id"]);
__PACKAGE__->has_many(
  "bs_sample_elements",
  "CXGN::Biosource::Schema::BsSampleElement",
  { "foreign.sample_id" => "self.sample_id" },
);
__PACKAGE__->has_many(
  "bs_sample_pubs",
  "CXGN::Biosource::Schema::BsSamplePub",
  { "foreign.sample_id" => "self.sample_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-18 11:49:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/PdDCd77Ht3UfohkpidsqA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
