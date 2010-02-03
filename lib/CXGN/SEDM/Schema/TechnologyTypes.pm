package CXGN::SEDM::Schema::TechnologyTypes;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("technology_types");
__PACKAGE__->add_columns(
  "technology_type_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.technology_types_technology_type_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "technology_name",
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
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("technology_type_id");
__PACKAGE__->add_unique_constraint("technology_types_pkey", ["technology_type_id"]);
__PACKAGE__->has_many(
  "platforms",
  "CXGN::SEDM::Schema::Platforms",
  { "foreign.technology_type_id" => "self.technology_type_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QivnR84OxVhCEx9IqshICw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
