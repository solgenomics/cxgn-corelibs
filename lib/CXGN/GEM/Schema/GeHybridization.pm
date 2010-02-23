package CXGN::GEM::Schema::GeHybridization;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_hybridization");
__PACKAGE__->add_columns(
  "hybridization_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_hybridization_hybridization_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "target_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "platform_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "platform_batch",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "protocol_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("hybridization_id");
__PACKAGE__->add_unique_constraint("ge_hybridization_pkey", ["hybridization_id"]);
__PACKAGE__->has_many(
  "ge_fluorescannings",
  "CXGN::GEM::Schema::GeFluorescanning",
  { "foreign.hybridization_id" => "self.hybridization_id" },
);
__PACKAGE__->belongs_to(
  "platform_id",
  "CXGN::GEM::Schema::GePlatform",
  { platform_id => "platform_id" },
);
__PACKAGE__->belongs_to(
  "target_id",
  "CXGN::GEM::Schema::GeTarget",
  { target_id => "target_id" },
);
__PACKAGE__->has_many(
  "ge_template_expressions",
  "CXGN::GEM::Schema::GeTemplateExpression",
  { "foreign.hybridization_id" => "self.hybridization_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-02-01 11:35:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:h9AUnQ1eBJWoVOUWk0rgcg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
