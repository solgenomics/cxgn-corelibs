use utf8;
package CXGN::People::Schema::Result::SpOrder;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpOrder

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_order>

=cut

__PACKAGE__->table("sp_order");

=head1 ACCESSORS

=head2 sp_order_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_order_sp_order_id_seq'

=head2 order_from_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 order_to_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 order_status

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 comments

  data_type: 'text'
  is_nullable: 1

=head2 create_date

  data_type: 'timestamp'
  is_nullable: 1

=head2 completion_date

  data_type: 'timestamp'
  is_nullable: 1



=cut

__PACKAGE__->add_columns(
  "sp_order_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_order_sp_order_id_seq",
  },
  "order_from_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "order_to_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "order_status",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "comments",
  { data_type => "text", is_nullable => 1 },
  "create_date",
  { data_type => "timestamp", is_nullable => 1 },
  "completion_date",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_order_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_order_id");

=head1 RELATIONS

=head2 order_from

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpPerson>

=cut

__PACKAGE__->belongs_to(
  "order_from",
  "CXGN::People::Schema::Result::SpPerson",
  { sp_person_id => "order_from_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 order_to

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpPerson>

=cut

__PACKAGE__->belongs_to(
  "order_to",
  "CXGN::People::Schema::Result::SpPerson",
  { sp_person_id => "order_to_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-03-07 19:18:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6b/RwQN9B6ZHSEx/lHMDaQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
