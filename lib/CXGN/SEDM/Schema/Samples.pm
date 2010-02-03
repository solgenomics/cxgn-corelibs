package CXGN::SEDM::Schema::Samples;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("samples");
__PACKAGE__->add_columns(
  "sample_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.samples_sample_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "sample_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "organism_group_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "cultivar_group_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("sample_id");
__PACKAGE__->add_unique_constraint("samples_pkey", ["sample_id"]);
__PACKAGE__->has_many(
  "sample_dbxrefs",
  "CXGN::SEDM::Schema::SampleDbxref",
  { "foreign.sample_id" => "self.sample_id" },
);
__PACKAGE__->belongs_to(
  "organism_group_id",
  "CXGN::SEDM::Schema::Groups",
  { group_id => "organism_group_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->belongs_to(
  "cultivar_group_id",
  "CXGN::SEDM::Schema::Groups",
  { group_id => "cultivar_group_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gQyMkT6cFYSKe/KZYlrVEQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
