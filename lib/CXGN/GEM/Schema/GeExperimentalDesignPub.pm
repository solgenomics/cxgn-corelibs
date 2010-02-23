package CXGN::GEM::Schema::GeExperimentalDesignPub;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_experimental_design_pub");
__PACKAGE__->add_columns(
  "experimental_design_pub_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_experimental_design_pub_experimental_design_pub_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "experimental_design_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "pub_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("experimental_design_pub_id");
__PACKAGE__->add_unique_constraint(
  "ge_experimental_design_pub_pkey",
  ["experimental_design_pub_id"],
);
__PACKAGE__->belongs_to(
  "experimental_design_id",
  "CXGN::GEM::Schema::GeExperimentalDesign",
  { "experimental_design_id" => "experimental_design_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-02-01 11:35:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vrmZLI9YPkAm9BFhFSqtDg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
