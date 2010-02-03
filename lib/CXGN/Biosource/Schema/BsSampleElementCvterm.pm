package CXGN::Biosource::Schema::BsSampleElementCvterm;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("bs_sample_element_cvterm");
__PACKAGE__->add_columns(
  "sample_element_cvterm_id",
  {
    data_type => "integer",
    default_value => "nextval('biosource.bs_sample_element_cvterm_sample_element_cvterm_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "sample_element_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "cvterm_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("sample_element_cvterm_id");
__PACKAGE__->add_unique_constraint("bs_sample_element_cvterm_pkey", ["sample_element_cvterm_id"]);
__PACKAGE__->belongs_to(
  "sample_element_id",
  "CXGN::Biosource::Schema::BsSampleElement",
  { sample_element_id => "sample_element_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-18 11:49:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aaNfnIXk/0MJhoswzLITXw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
