package SGN::Schema::FamilyMember;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::FamilyMember

=cut

__PACKAGE__->table("family_member");

=head1 ACCESSORS

=head2 family_member_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'family_member_family_member_id_seq'

=head2 cds_id

  data_type: 'bigint'
  is_nullable: 1

=head2 organism_group_id

  data_type: 'bigint'
  is_nullable: 1

=head2 family_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 database_name

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 sequence_name

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 alignment_seq

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "family_member_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "family_member_family_member_id_seq",
  },
  "cds_id",
  { data_type => "bigint", is_nullable => 1 },
  "organism_group_id",
  { data_type => "bigint", is_nullable => 1 },
  "family_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "database_name",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "sequence_name",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "alignment_seq",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("family_member_id");

=head1 RELATIONS

=head2 family

Type: belongs_to

Related object: L<SGN::Schema::Family>

=cut

__PACKAGE__->belongs_to(
  "family",
  "SGN::Schema::Family",
  { family_id => "family_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EwK2XAL/yXMUV8rOpDh0VA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
