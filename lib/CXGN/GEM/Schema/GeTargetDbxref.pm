package CXGN::GEM::Schema::GeTargetDbxref;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_target_dbxref");
__PACKAGE__->add_columns(
  "target_dbxref_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_target_dbxref_target_dbxref_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "target_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "dbxref_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("target_dbxref_id");
__PACKAGE__->add_unique_constraint("ge_target_dbxref_pkey", ["target_dbxref_id"]);
__PACKAGE__->belongs_to(
  "target_id",
  "CXGN::GEM::Schema::GeTarget",
  { target_id => "target_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-02-01 11:35:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eMPZPRSMNLNi1cdwOGL5uQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
