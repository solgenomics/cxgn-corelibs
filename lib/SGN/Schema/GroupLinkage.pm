package SGN::Schema::GroupLinkage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::GroupLinkage

=cut

__PACKAGE__->table("group_linkage");

=head1 ACCESSORS

=head2 group_linkage_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'group_linkage_group_linkage_id_seq'

=head2 group_id

  data_type: 'integer'
  is_nullable: 1

=head2 member_id

  data_type: 'integer'
  is_nullable: 1

=head2 member_type

  data_type: 'bigint'
  is_nullable: 1

=head2 member_value

  data_type: 'bytea'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "group_linkage_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "group_linkage_group_linkage_id_seq",
  },
  "group_id",
  { data_type => "integer", is_nullable => 1 },
  "member_id",
  { data_type => "integer", is_nullable => 1 },
  "member_type",
  { data_type => "bigint", is_nullable => 1 },
  "member_value",
  { data_type => "bytea", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("group_linkage_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wRthsfk+3dZbyhxvnSULVw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
