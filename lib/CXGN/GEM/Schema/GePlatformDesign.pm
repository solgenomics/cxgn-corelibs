package CXGN::GEM::Schema::GePlatformDesign;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_platform_design");
__PACKAGE__->add_columns(
  "platform_design_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_platform_design_platform_design_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "platform_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "sample_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("platform_design_id");
__PACKAGE__->add_unique_constraint("ge_platform_design_pkey", ["platform_design_id"]);
__PACKAGE__->belongs_to(
  "platform_id",
  "CXGN::GEM::Schema::GePlatform",
  { platform_id => "platform_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-02-01 11:35:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EeZadQpWe2Z3dngUiydYEw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
