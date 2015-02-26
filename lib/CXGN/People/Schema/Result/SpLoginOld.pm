use utf8;
package CXGN::People::Schema::Result::SpLoginOld;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpLoginOld

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_login_old>

=cut

__PACKAGE__->table("sp_login_old");

=head1 ACCESSORS

=head2 sp_login_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_login_old_sp_login_id_seq'

=head2 username

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 private_email

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 pending_email

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 password

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 confirm_code

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 disabled

  data_type: 'bigint'
  is_nullable: 1

=head2 user_type

  data_type: 'varchar'
  default_value: 'user'
  is_nullable: 1
  size: 9

=cut

__PACKAGE__->add_columns(
  "sp_login_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_login_old_sp_login_id_seq",
  },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "private_email",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pending_email",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "confirm_code",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "disabled",
  { data_type => "bigint", is_nullable => 1 },
  "user_type",
  {
    data_type => "varchar",
    default_value => "user",
    is_nullable => 1,
    size => 9,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_login_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_login_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<username_unique>

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->add_unique_constraint("username_unique", ["username"]);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-26 16:04:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qnbZ6qbwGEtDeDxAwdEqcA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
