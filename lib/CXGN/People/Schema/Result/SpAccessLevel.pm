use utf8;
package CXGN::People::Schema::Result::SpAccessLevel;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpAccessLevel

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_access_level>

=cut

__PACKAGE__->table("sp_access_level");

=head1 ACCESSORS

=head2 sp_access_level_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_access_level_sp_access_level_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=cut

__PACKAGE__->add_columns(
  "sp_access_level_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_access_level_sp_access_level_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 20 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_access_level_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_access_level_id");

=head1 RELATIONS

=head2 sp_privileges

Type: has_many

Related object: L<CXGN::People::Schema::Result::SpPrivilege>

=cut

__PACKAGE__->has_many(
  "sp_privileges",
  "CXGN::People::Schema::Result::SpPrivilege",
  { "foreign.sp_access_level_id" => "self.sp_access_level_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2023-12-31 10:26:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VHI2zkgunOZUy2fh3G8Keg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
