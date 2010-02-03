package CXGN::Biosource::Schema::BsProtocol;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("bs_protocol");
__PACKAGE__->add_columns(
  "protocol_id",
  {
    data_type => "integer",
    default_value => "nextval('biosource.bs_protocol_protocol_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "protocol_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "protocol_type",
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
__PACKAGE__->set_primary_key("protocol_id");
__PACKAGE__->add_unique_constraint("bs_protocol_pkey", ["protocol_id"]);
__PACKAGE__->has_many(
  "bs_protocol_pubs",
  "CXGN::Biosource::Schema::BsProtocolPub",
  { "foreign.protocol_id" => "self.protocol_id" },
);
__PACKAGE__->has_many(
  "bs_protocol_steps",
  "CXGN::Biosource::Schema::BsProtocolStep",
  { "foreign.protocol_id" => "self.protocol_id" },
);
__PACKAGE__->has_many(
  "bs_sample_elements",
  "CXGN::Biosource::Schema::BsSampleElement",
  { "foreign.protocol_id" => "self.protocol_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-18 11:49:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zXz9IHYs8b1ULn5N4uwRRQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
