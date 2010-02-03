package CXGN::SEDM::Schema::SampleDbxref;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("sample_dbxref");
__PACKAGE__->add_columns(
  "sample_dbxref_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.sample_dbxref_sample_dbxref_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "sample_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "dbxref_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("sample_dbxref_id");
__PACKAGE__->add_unique_constraint("sample_dbxref_pkey", ["sample_dbxref_id"]);
__PACKAGE__->has_many(
  "ontology_quantifieds",
  "CXGN::SEDM::Schema::OntologyQuantified",
  { "foreign.sample_dbxref_id" => "self.sample_dbxref_id" },
);
__PACKAGE__->belongs_to(
  "metadata",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->belongs_to(
  "samples",
  "CXGN::SEDM::Schema::Samples",
  { sample_id => "sample_id" },
);

# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:P8hpdnAGX30cSWGF0tCf6A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
