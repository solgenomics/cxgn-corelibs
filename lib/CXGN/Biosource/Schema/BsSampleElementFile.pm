package CXGN::Biosource::Schema::BsSampleElementFile;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("bs_sample_element_file");
__PACKAGE__->add_columns(
  "sample_element_file_id",
  {
    data_type => "integer",
    default_value => "nextval('biosource.bs_sample_element_file_sample_element_file_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "sample_element_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "file_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("sample_element_file_id");
__PACKAGE__->add_unique_constraint("bs_sample_element_file_pkey", ["sample_element_file_id"]);
__PACKAGE__->belongs_to(
  "sample_element_id",
  "CXGN::Biosource::Schema::BsSampleElement",
  { sample_element_id => "sample_element_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-18 11:49:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nOhTL3NRPoUfxy5o1Aj76Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
