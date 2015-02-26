use utf8;
package CXGN::People::Schema::Result::SpProjectOrganization;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpProjectOrganization

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_project_organization>

=cut

__PACKAGE__->table("sp_project_organization");

=head1 ACCESSORS

=head2 sp_project_organization_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_project_organization_sp_project_organization_id_seq'

=head2 sp_project_id

  data_type: 'bigint'
  is_nullable: 1

=head2 sp_organization_id

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sp_project_organization_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_project_organization_sp_project_organization_id_seq",
  },
  "sp_project_id",
  { data_type => "bigint", is_nullable => 1 },
  "sp_organization_id",
  { data_type => "bigint", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_project_organization_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_project_organization_id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-26 16:04:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:j5DAEA4uYx6sR5MUU8M9jw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
