package SGN::Schema::FamilyMember;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("family_member");
__PACKAGE__->add_columns(
  "family_member_id",
  {
    data_type => "bigint",
    default_value => "nextval('family_member_family_member_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "cds_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "organism_group_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "family_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "database_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "sequence_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "alignment_seq",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("family_member_id");
__PACKAGE__->belongs_to(
  "family",
  "SGN::Schema::Family",
  { family_id => "family_id" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/Pw0xdFCdtj0+afRDX811Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
