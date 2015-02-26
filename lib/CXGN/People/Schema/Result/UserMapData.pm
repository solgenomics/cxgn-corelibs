use utf8;
package CXGN::People::Schema::Result::UserMapData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::UserMapData

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<user_map_data>

=cut

__PACKAGE__->table("user_map_data");

=head1 ACCESSORS

=head2 user_map_data_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.user_map_data_user_map_data_id_seq'

=head2 user_map_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 marker_name

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 protocol

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 marker_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 linkage_group

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 position

  data_type: 'numeric'
  is_nullable: 1
  size: [20,4]

=head2 confidence

  data_type: 'varchar'
  is_nullable: 1
  size: 20

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
  "user_map_data_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.user_map_data_user_map_data_id_seq",
  },
  "user_map_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "marker_name",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "protocol",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "marker_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "linkage_group",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "position",
  { data_type => "numeric", is_nullable => 1, size => [20, 4] },
  "confidence",
  { data_type => "varchar", is_nullable => 1, size => 20 },
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

=item * L</user_map_data_id>

=back

=cut

__PACKAGE__->set_primary_key("user_map_data_id");

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

=head2 user_map

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::UserMap>

=cut

__PACKAGE__->belongs_to(
  "user_map",
  "CXGN::People::Schema::Result::UserMap",
  { user_map_id => "user_map_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-26 16:04:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:em+LwXR7f7JpNXesQ1EpYw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
