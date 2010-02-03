package CXGN::GEM::Schema::GeTargetElement;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_target_element");
__PACKAGE__->add_columns(
  "target_element_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_target_element_target_element_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "target_element_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "target_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "sample_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "protocol_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "dye",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("target_element_id");
__PACKAGE__->add_unique_constraint("ge_target_element_target_id_key", ["target_id", "dye"]);
__PACKAGE__->add_unique_constraint("ge_target_element_pkey", ["target_element_id"]);
__PACKAGE__->belongs_to(
  "target_id",
  "CXGN::GEM::Schema::GeTarget",
  { target_id => "target_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-24 17:00:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:F2u0Ew0qKa2vHn44IE451Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
