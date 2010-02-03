package CXGN::SEDM::Schema::ExperimentalDesigns;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("experimental_designs");
__PACKAGE__->add_columns(
  "experimental_design_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.experimental_designs_experimental_design_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "experimental_design_name",
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
  "design_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "dbxref_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("experimental_design_id");
__PACKAGE__->add_unique_constraint("experimental_designs_pkey", ["experimental_design_id"]);
__PACKAGE__->has_many(
  "experiment_data_analyses",
  "CXGN::SEDM::Schema::ExperimentDataAnalysis",
  { "foreign.experiment_design_id" => "self.experimental_design_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->has_many(
  "experiments",
  "CXGN::SEDM::Schema::Experiments",
  {
    "foreign.experimental_design_id" => "self.experimental_design_id",
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Tr0VIfT7alD+zqJp4HgWnQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
