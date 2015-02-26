use utf8;
package CXGN::People::Schema::Result::UserMap;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::UserMap

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<user_map>

=cut

__PACKAGE__->table("user_map");

=head1 ACCESSORS

=head2 user_map_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.user_map_user_map_id_seq'

=head2 short_name

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 long_name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 abstract

  data_type: 'text'
  is_nullable: 1

=head2 is_public

  data_type: 'boolean'
  is_nullable: 1

=head2 parent1_accession_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 parent1

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 parent2_accession_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 parent2

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 sp_person_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 obsolete

  data_type: 'boolean'
  is_nullable: 1

=head2 modified_date

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 create_date

  data_type: 'timestamp with time zone'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user_map_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.user_map_user_map_id_seq",
  },
  "short_name",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "long_name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "abstract",
  { data_type => "text", is_nullable => 1 },
  "is_public",
  { data_type => "boolean", is_nullable => 1 },
  "parent1_accession_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "parent1",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "parent2_accession_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "parent2",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "sp_person_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "obsolete",
  { data_type => "boolean", is_nullable => 1 },
  "modified_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "create_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_map_id>

=back

=cut

__PACKAGE__->set_primary_key("user_map_id");

=head1 RELATIONS

=head2 sp_person

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpPerson>

=cut

__PACKAGE__->belongs_to(
  "sp_person",
  "CXGN::People::Schema::Result::SpPerson",
  { sp_person_id => "sp_person_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 user_map_datas

Type: has_many

Related object: L<CXGN::People::Schema::Result::UserMapData>

=cut

__PACKAGE__->has_many(
  "user_map_datas",
  "CXGN::People::Schema::Result::UserMapData",
  { "foreign.user_map_id" => "self.user_map_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-26 16:04:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PM+/sBFOf2CWhp3x2CHnpQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
