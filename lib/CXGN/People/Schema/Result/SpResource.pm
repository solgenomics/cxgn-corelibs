use utf8;
package CXGN::People::Schema::Result::SpResource;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpResource

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_resource>

=cut

__PACKAGE__->table("sp_resource");

=head1 ACCESSORS

=head2 sp_resource_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_resources_sp_resource_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 url

  data_type: 'text'
  is_nullable: 1

=head2 require_ownership

  data_type: 'boolean'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sp_resource_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_resources_sp_resource_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "url",
  { data_type => "text", is_nullable => 1 },
  "require_ownership",
  { data_type => "boolean", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_resource_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_resource_id");

=head1 RELATIONS

=head2 sp_privileges

Type: has_many

Related object: L<CXGN::People::Schema::Result::SpPrivilege>

=cut

__PACKAGE__->has_many(
  "sp_privileges",
  "CXGN::People::Schema::Result::SpPrivilege",
  { "foreign.sp_resource_id" => "self.sp_resource_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2023-12-31 10:26:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:X0Z2UGFUAhY2nMaG9NtrIw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
