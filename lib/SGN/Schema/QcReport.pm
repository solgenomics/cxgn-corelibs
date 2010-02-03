package SGN::Schema::QcReport;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("qc_report");
__PACKAGE__->add_columns(
  "qc_id",
  {
    data_type => "integer",
    default_value => "nextval('qc_report_qc_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "est_id",
  {
    data_type => "integer",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "basecaller",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 40,
  },
  "qc_status",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "vs_status",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "qstart",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "qend",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "istart",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "iend",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "hqi_start",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "hqi_length",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "entropy",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "expected_error",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "quality_trim_threshold",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "vector_tokens",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("qc_id");
__PACKAGE__->add_unique_constraint("qc_report_est_id_key", ["est_id"]);
__PACKAGE__->belongs_to("est", "SGN::Schema::Est", { est_id => "est_id" });


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U4A2xfcDZEcs8fJNhex8yg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
