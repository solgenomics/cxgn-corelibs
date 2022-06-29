package CXGN::Metadata::Schema::MdGroupmembers;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("md_groupmembers");
__PACKAGE__->add_columns(
  "groupmember_id",
  {
    data_type => "bigint",
    default_value => "nextval('metadata.md_groupmembers_groupmember_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
    is_auto_increment => 1
  },
  "group_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "dbiref_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("groupmember_id");
__PACKAGE__->add_unique_constraint("md_groupmembers_pkey", ["groupmember_id"]);
__PACKAGE__->belongs_to(
  "group_id",
  "CXGN::DB::Metadata::Schema::MdGroups",
  { group_id => "group_id" },
);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::DB::Metadata::Schema::MdMetadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->belongs_to(
  "dbiref_id",
  "CXGN::DB::Metadata::Schema::MdDbiref",
  { dbiref_id => "dbiref_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-10-01 09:34:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:i4Sx/QBPGoF2rQ3DY44Vdw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
