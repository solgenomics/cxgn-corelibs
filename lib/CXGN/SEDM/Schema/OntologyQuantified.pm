package CXGN::SEDM::Schema::OntologyQuantified;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ontology_quantified");
__PACKAGE__->add_columns(
  "ontology_quantified_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.ontology_quantified_ontology_quantified_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "sample_dbxref_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "ontology_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "value",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "units",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "step_in_description",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("ontology_quantified_id");
__PACKAGE__->add_unique_constraint("ontology_quantified_pkey", ["ontology_quantified_id"]);
__PACKAGE__->belongs_to(
  "sample_dbxref_id",
  "CXGN::SEDM::Schema::SampleDbxref",
  { sample_dbxref_id => "sample_dbxref_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Gc4hXoEHALYr8SmTESO4HQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
