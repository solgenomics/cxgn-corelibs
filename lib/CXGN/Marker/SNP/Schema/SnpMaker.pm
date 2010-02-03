package CXGN::Marker::SNP::Schema::SnpMaker;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("snp_maker");
__PACKAGE__->add_columns(
  "snp_maker_id",
  {
    data_type => "integer",
    default_value => "nextval('marker.snp_maker_snp_maker_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "snp_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "marker_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("snp_maker_id");
__PACKAGE__->add_unique_constraint("snp_maker_pkey", ["snp_maker_id"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2009-07-20 16:37:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KquEwTp/+V3AJpSbpRsRPQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
