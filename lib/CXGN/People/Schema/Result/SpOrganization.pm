use utf8;
package CXGN::People::Schema::Result::SpOrganization;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpOrganization

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_organization>

=cut

__PACKAGE__->table("sp_organization");

=head1 ACCESSORS

=head2 sp_organization_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_organization_sp_organization_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 department

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 unit

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 address

  data_type: 'text'
  is_nullable: 1

=head2 country

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 phone_number

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 fax

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 contact_email

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 webpage

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 upload_account_name

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 shortname

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=cut

__PACKAGE__->add_columns(
  "sp_organization_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_organization_sp_organization_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "department",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "unit",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "address",
  { data_type => "text", is_nullable => 1 },
  "country",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "phone_number",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "fax",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "contact_email",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "webpage",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "upload_account_name",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "shortname",
  { data_type => "varchar", is_nullable => 0, size => 20 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_organization_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_organization_id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-26 16:04:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vzxfYU6jvc9+rZ+baZPhAg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
