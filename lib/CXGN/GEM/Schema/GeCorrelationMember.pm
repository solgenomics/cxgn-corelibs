package CXGN::GEM::Schema::GeCorrelationMember;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_correlation_member");
__PACKAGE__->add_columns(
  "correlation_member_id",
  {
    data_type => "bigint",
    default_value => "nextval('gem.ge_correlation_member_correlation_member_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "correlation_analysis_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "template_a_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "template_b_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "correlation_value",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "correlation_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "dataset_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("correlation_member_id");
__PACKAGE__->add_unique_constraint("ge_correlation_member_pkey", ["correlation_member_id"]);
__PACKAGE__->belongs_to(
  "template_a_id",
  "CXGN::GEM::Schema::GeTemplate",
  { template_id => "template_a_id" },
);
__PACKAGE__->belongs_to(
  "template_b_id",
  "CXGN::GEM::Schema::GeTemplate",
  { template_id => "template_b_id" },
);
__PACKAGE__->belongs_to(
  "correlation_analysis_id",
  "CXGN::GEM::Schema::GeCorrelationAnalysis",
  { "correlation_analysis_id" => "correlation_analysis_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-24 17:00:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:a2Ee6k6Gh6b1OjuAzmiPuw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
