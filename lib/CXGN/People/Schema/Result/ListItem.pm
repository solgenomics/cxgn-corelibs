use utf8;
package CXGN::People::Schema::Result::ListItem;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::ListItem

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<list_item>

=cut

__PACKAGE__->table("list_item");

=head1 ACCESSORS

=head2 list_item_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.list_item_list_item_id_seq'

=head2 content

  data_type: 'text'
  is_nullable: 1

=head2 list_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "list_item_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.list_item_list_item_id_seq",
  },
  "content",
  { data_type => "text", is_nullable => 1 },
  "list_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</list_item_id>

=back

=cut

__PACKAGE__->set_primary_key("list_item_id");

=head1 RELATIONS

=head2 list

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::List>

=cut

__PACKAGE__->belongs_to(
  "list",
  "CXGN::People::Schema::Result::List",
  { list_id => "list_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-26 16:04:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Cag+X4oCF9CBiPImlwF8Mw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
