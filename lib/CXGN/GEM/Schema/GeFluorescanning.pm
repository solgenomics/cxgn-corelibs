package CXGN::GEM::Schema::GeFluorescanning;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_fluorescanning");
__PACKAGE__->add_columns(
  "fluorescanning_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_fluorescanning_fluorescanning_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "hybridization_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "protocol_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "file_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "dbxref_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("fluorescanning_id");
__PACKAGE__->add_unique_constraint("ge_fluorescanning_pkey", ["fluorescanning_id"]);
__PACKAGE__->belongs_to(
  "hybridization_id",
  "CXGN::GEM::Schema::GeHybridization",
  { hybridization_id => "hybridization_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-24 17:00:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5/HQvtEuv7Ypb1n26aHBjQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
