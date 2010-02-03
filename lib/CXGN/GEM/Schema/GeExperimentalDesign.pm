package CXGN::GEM::Schema::GeExperimentalDesign;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_experimental_design");
__PACKAGE__->add_columns(
  "experimental_design_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_experimental_design_experimental_design_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
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
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("experimental_design_id");
__PACKAGE__->add_unique_constraint("ge_experimental_design_pkey", ["experimental_design_id"]);
__PACKAGE__->has_many(
  "ge_experiments",
  "CXGN::GEM::Schema::GeExperiment",
  {
    "foreign.experimental_design_id" => "self.experimental_design_id",
  },
);
__PACKAGE__->has_many(
  "ge_experimental_design_dbxrefs",
  "CXGN::GEM::Schema::GeExperimentalDesignDbxref",
  {
    "foreign.experimental_design_id" => "self.experimental_design_id",
  },
);
__PACKAGE__->has_many(
  "ge_experimental_design_pubs",
  "CXGN::GEM::Schema::GeExperimentalDesignPub",
  {
    "foreign.experimental_design_id" => "self.experimental_design_id",
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-24 17:00:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yzzsRzF/NWa2cEX5SENS1g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
