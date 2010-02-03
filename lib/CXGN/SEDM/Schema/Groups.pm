package CXGN::SEDM::Schema::Groups;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("groups");
__PACKAGE__->add_columns(
  "group_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.groups_group_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "name",
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
__PACKAGE__->set_primary_key("group_id");
__PACKAGE__->add_unique_constraint("groups_pkey", ["group_id"]);
__PACKAGE__->has_many(
  "cluster_expression_analyses",
  "CXGN::SEDM::Schema::ClusterExpressionAnalysis",
  { "foreign.experiment_group_id" => "self.group_id" },
);
__PACKAGE__->has_many(
  "correlation_analyses",
  "CXGN::SEDM::Schema::CorrelationAnalysis",
  { "foreign.experiment_group_id" => "self.group_id" },
);
__PACKAGE__->has_many(
  "group_linkages",
  "CXGN::SEDM::Schema::GroupLinkage",
  { "foreign.group_id" => "self.group_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->has_many(
  "hybridizations",
  "CXGN::SEDM::Schema::Hybridizations",
  { "foreign.target_group_id" => "self.group_id" },
);
__PACKAGE__->has_many(
  "platforms_designs",
  "CXGN::SEDM::Schema::PlatformsDesigns",
  { "foreign.organism_group_id" => "self.group_id" },
);
__PACKAGE__->has_many(
  "samples_organism_group_ids",
  "CXGN::SEDM::Schema::Samples",
  { "foreign.organism_group_id" => "self.group_id" },
);
__PACKAGE__->has_many(
  "samples_cultivar_group_ids",
  "CXGN::SEDM::Schema::Samples",
  { "foreign.cultivar_group_id" => "self.group_id" },
);
__PACKAGE__->has_many(
  "stat_expression_analyses",
  "CXGN::SEDM::Schema::StatExpressionAnalysis",
  { "foreign.experiment_group_id" => "self.group_id" },
);
__PACKAGE__->has_many(
  "stat_expression_template_values",
  "CXGN::SEDM::Schema::StatExpressionTemplateValues",
  { "foreign.analysis_group_id" => "self.group_id" },
);
__PACKAGE__->has_many(
  "targets",
  "CXGN::SEDM::Schema::Targets",
  { "foreign.sample_group_id" => "self.group_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dourrqwUrSkoYf2sATFGfQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
