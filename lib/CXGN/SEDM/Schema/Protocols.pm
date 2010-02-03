package CXGN::SEDM::Schema::Protocols;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("protocols");
__PACKAGE__->add_columns(
  "protocol_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.protocols_protocol_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "protocol_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "input_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "input_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "output_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "output_type",
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
  "dbxref_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("protocol_id");
__PACKAGE__->add_unique_constraint("protocols_pkey", ["protocol_id"]);
__PACKAGE__->has_many(
  "cluster_expression_analyses",
  "CXGN::SEDM::Schema::ClusterExpressionAnalysis",
  { "foreign.protocol_id" => "self.protocol_id" },
);
__PACKAGE__->has_many(
  "correlation_analyses",
  "CXGN::SEDM::Schema::CorrelationAnalysis",
  { "foreign.protocol_id" => "self.protocol_id" },
);
__PACKAGE__->has_many(
  "experiment_data_analyses",
  "CXGN::SEDM::Schema::ExperimentDataAnalysis",
  { "foreign.protocol_id" => "self.protocol_id" },
);
__PACKAGE__->has_many(
  "hybridizations",
  "CXGN::SEDM::Schema::Hybridizations",
  { "foreign.protocol_id" => "self.protocol_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->has_many(
  "stat_expression_analyses",
  "CXGN::SEDM::Schema::StatExpressionAnalysis",
  { "foreign.protocol_id" => "self.protocol_id" },
);
__PACKAGE__->has_many(
  "step_protocols",
  "CXGN::SEDM::Schema::StepProtocols",
  { "foreign.protocol_id" => "self.protocol_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1lKWx4nOvcJyYyb4q6WLXw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
