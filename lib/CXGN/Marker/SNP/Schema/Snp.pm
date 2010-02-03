package CXGN::Marker::SNP::Schema::Snp;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("snp");
__PACKAGE__->add_columns(
  "snp_id",
  {
    data_type => "integer",
    default_value => "nextval('marker.snp_snp_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "unigene_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "unigene_position",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "region",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 5,
  },
  "reference_nucleotide",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
  "snp_nucleotide",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
  "mqs",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "mns",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
  "confirmed",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 4,
  },
  "primer_left_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "primer_right_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "accession_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "snp_accession_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "sp_person_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "modified_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "create_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "obsolete",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("snp_id");
__PACKAGE__->add_unique_constraint("snp_pkey", ["snp_id"]);
__PACKAGE__->has_many(
  "snp_dbxrefs",
  "CXGN::Marker::SNP::Schema::SnpDbxref",
  { "foreign.snp_id" => "self.snp_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-07-20 16:37:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lf0Tcx5kZQA3RNZXc/KGwQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
