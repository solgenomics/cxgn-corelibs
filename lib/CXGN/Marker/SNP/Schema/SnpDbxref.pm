package CXGN::Marker::SNP::Schema::SnpDbxref;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("snp_dbxref");
__PACKAGE__->add_columns(
  "snp_dbxref_id",
  {
    data_type => "integer",
    default_value => "nextval('marker.snp_dbxref_snp_dbxref_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "snp_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "dbxref_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "obsolete",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
  "sp_person_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "create_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "modified_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("snp_dbxref_id");
__PACKAGE__->add_unique_constraint("snp_dbxref_pkey", ["snp_dbxref_id"]);
__PACKAGE__->belongs_to(
  "snp_id",
  "CXGN::Marker::SNP::Schema::Snp",
  { snp_id => "snp_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-07-20 16:37:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:a5KaLXAL/WjvSdhgzZGSnQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
