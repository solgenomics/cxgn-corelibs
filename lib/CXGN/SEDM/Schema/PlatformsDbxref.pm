package CXGN::SEDM::Schema::PlatformsDbxref;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("platforms_dbxref");
__PACKAGE__->add_columns(
  "platform_dbxref_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.platforms_dbxref_platform_dbxref_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "platform_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "dbxref_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("platform_dbxref_id");
__PACKAGE__->add_unique_constraint("platforms_dbxref_pkey", ["platform_dbxref_id"]);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->belongs_to(
  "platform_id",
  "CXGN::SEDM::Schema::Platforms",
  { platform_id => "platform_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Kl3sxdbG6I4WzJ+yfKysBg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
