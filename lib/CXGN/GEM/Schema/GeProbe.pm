package CXGN::GEM::Schema::GeProbe;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_probe");
__PACKAGE__->add_columns(
  "probe_id",
  {
    data_type => "bigint",
    default_value => "nextval('gem.ge_probe_probe_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "platform_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "probe_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "probe_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "sequence_file_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "template_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "template_start",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "template_end",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("probe_id");
__PACKAGE__->add_unique_constraint("ge_probe_pkey", ["probe_id"]);
__PACKAGE__->add_unique_constraint("ge_probe_probe_name_key", ["probe_name", "platform_id"]);
__PACKAGE__->belongs_to(
  "platform_id",
  "CXGN::GEM::Schema::GePlatform",
  { platform_id => "platform_id" },
);
__PACKAGE__->belongs_to(
  "template_id",
  "CXGN::GEM::Schema::GeTemplate",
  { template_id => "template_id" },
);
__PACKAGE__->has_many(
  "ge_probe_expressions",
  "CXGN::GEM::Schema::GeProbeExpression",
  { "foreign.probe_id" => "self.probe_id" },
);
__PACKAGE__->has_many(
  "ge_probe_spots",
  "CXGN::GEM::Schema::GeProbeSpot",
  { "foreign.probe_id" => "self.probe_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-24 17:00:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Pq8tLezvWkjNkdiS9Mozqw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
