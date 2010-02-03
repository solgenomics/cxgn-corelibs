package CXGN::SEDM::Schema::Hybridizations;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hybridizations");
__PACKAGE__->add_columns(
  "hybridization_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.hybridizations_hybridization_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "target_group_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "platform_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "protocol_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("hybridization_id");
__PACKAGE__->add_unique_constraint("hybridizations_pkey", ["hybridization_id"]);
__PACKAGE__->has_many(
  "experiment_data_analyses",
  "CXGN::SEDM::Schema::ExperimentDataAnalysis",
  { "foreign.hybridization_id" => "self.hybridization_id" },
);
__PACKAGE__->has_many(
  "expression_template_values",
  "CXGN::SEDM::Schema::ExpressionTemplateValues",
  { "foreign.hybridization_id" => "self.hybridization_id" },
);
__PACKAGE__->belongs_to(
  "platform_id",
  "CXGN::SEDM::Schema::Platforms",
  { platform_id => "platform_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->belongs_to(
  "target_group_id",
  "CXGN::SEDM::Schema::Groups",
  { group_id => "target_group_id" },
);
__PACKAGE__->belongs_to(
  "protocol_id",
  "CXGN::SEDM::Schema::Protocols",
  { protocol_id => "protocol_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nVxW5H0UraJC8RkC9FJnRg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
