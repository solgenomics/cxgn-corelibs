use utf8;
package CXGN::People::Schema::Result::List;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::List

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<list>

=cut

__PACKAGE__->table("list");

=head1 ACCESSORS

=head2 list_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.list_list_id_seq'

=head2 is_hotlist

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 sent_by

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 owner

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 type_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "list_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.list_list_id_seq",
  },
  "is_hotlist",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "sent_by",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "owner",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "type_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</list_id>

=back

=cut

__PACKAGE__->set_primary_key("list_id");

=head1 RELATIONS

=head2 list_items

Type: has_many

Related object: L<CXGN::People::Schema::Result::ListItem>

=cut

__PACKAGE__->has_many(
  "list_items",
  "CXGN::People::Schema::Result::ListItem",
  { "foreign.list_id" => "self.list_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 owner

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpPerson>

=cut

__PACKAGE__->belongs_to(
  "owner",
  "CXGN::People::Schema::Result::SpPerson",
  { sp_person_id => "owner" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-26 16:04:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:H/dOuNCTXqTa/D1+e0kLow


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
