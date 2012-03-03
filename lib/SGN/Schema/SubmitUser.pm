package SGN::Schema::SubmitUser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::SubmitUser

=cut

__PACKAGE__->table("submit_user");

=head1 ACCESSORS

=head2 submit_user_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'submit_user_submit_user_id_seq'

=head2 submit_code

  data_type: 'varchar'
  is_nullable: 1
  size: 6

=head2 username

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 password

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 80

=head2 email_address

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 phone_number

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 organization

  data_type: 'varchar'
  is_nullable: 1
  size: 80

=head2 contact_information

  data_type: 'text'
  is_nullable: 1

=head2 disabled

  data_type: 'bigint'
  is_nullable: 1

=head2 confirm_code

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 sp_person_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "submit_user_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "submit_user_submit_user_id_seq",
  },
  "submit_code",
  { data_type => "varchar", is_nullable => 1, size => 6 },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 80 },
  "email_address",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "phone_number",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "organization",
  { data_type => "varchar", is_nullable => 1, size => 80 },
  "contact_information",
  { data_type => "text", is_nullable => 1 },
  "disabled",
  { data_type => "bigint", is_nullable => 1 },
  "confirm_code",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "sp_person_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("submit_user_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:H8ElPRe7I8jN7AiPGWYTlw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
