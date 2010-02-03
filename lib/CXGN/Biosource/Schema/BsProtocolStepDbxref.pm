package CXGN::Biosource::Schema::BsProtocolStepDbxref;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("bs_protocol_step_dbxref");
__PACKAGE__->add_columns(
  "protocol_step_dbxref_id",
  {
    data_type => "integer",
    default_value => "nextval('biosource.bs_protocol_step_dbxref_protocol_step_dbxref_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "protocol_step_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "dbxref_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("protocol_step_dbxref_id");
__PACKAGE__->add_unique_constraint("bs_protocol_step_dbxref_pkey", ["protocol_step_dbxref_id"]);
__PACKAGE__->belongs_to(
  "protocol_step_id",
  "CXGN::Biosource::Schema::BsProtocolStep",
  { protocol_step_id => "protocol_step_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-18 11:49:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oQiyrWlPI2YTF41VQjWJuw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
