package CXGN::SEDM::Schema::CorrelationAnalysisMembers;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("correlation_analysis_members");
__PACKAGE__->add_columns(
  "correlation_analysis_member_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.correlation_analysis_members_correlation_analysis_member_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
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
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "correlation_analysis_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("correlation_analysis_member_id");
__PACKAGE__->add_unique_constraint(
  "correlation_analysis_members_pkey",
  ["correlation_analysis_member_id"],
);
__PACKAGE__->belongs_to(
  "template_a_id",
  "CXGN::SEDM::Schema::Templates",
  { template_id => "template_a_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->belongs_to(
  "correlation_analysis_id",
  "CXGN::SEDM::Schema::CorrelationAnalysis",
  { "correlation_analysis_id" => "correlation_analysis_id" },
);
__PACKAGE__->belongs_to(
  "template_b_id",
  "CXGN::SEDM::Schema::Templates",
  { template_id => "template_b_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oYfVF/jT9nn3zvxwlXa3HA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
