package SGN::Schema::SubmitUser;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("submit_user");
__PACKAGE__->add_columns(
  "submit_user_id",
  {
    data_type => "integer",
    default_value => "nextval('submit_user_submit_user_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "submit_code",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 6,
  },
  "username",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "password",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "email_address",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "phone_number",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "organization",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "contact_information",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "disabled",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "confirm_code",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 16,
  },
  "sp_person_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("submit_user_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kNQSsWJyZQpBdc/8gM9arw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
