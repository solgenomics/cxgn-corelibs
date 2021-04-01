use utf8;
package CXGN::People::Schema::Result::SpOrderprop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpOrderprop

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_orderprop>

=cut

__PACKAGE__->table("sp_orderprop");

=head1 ACCESSORS

=head2 sp_orderprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_orderprop_sp_orderprop_id_seq'

=head2 sp_order_id

  data_type: 'integer'
  is_foreign_key:1
  is_nullable:0

=head2 type_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 value

  data_type: 'jsonb'
  is_nullable: 1

=head2 rank

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "sp_orderprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_orderprop_sp_orderprop_id_seq",
  },
  "sp_order_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "value",
  { data_type => "jsonb", is_nullable => 1 },
  "rank",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_orderprop_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_orderprop_id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-03-07 19:18:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WBsvctfYpjQx0u2e77Aebw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
