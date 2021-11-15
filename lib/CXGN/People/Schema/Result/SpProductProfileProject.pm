use utf8;
package CXGN::People::Schema::Result::SpProductProfileProject;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpProductProfileProject

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_product_profile_project>

=cut

__PACKAGE__->table("sp_product_profile_project");

=head1 ACCESSORS

=head2 sp_product_profile_project

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_product_profile_project_sp_product_profile_project_seq'

=head2 project_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 sp_product_profile_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sp_product_profile_project",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_product_profile_project_sp_product_profile_project_seq",
  },
  "project_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "sp_product_profile_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_product_profile_project>

=back

=cut

__PACKAGE__->set_primary_key("sp_product_profile_project");

=head1 RELATIONS

=head2 sp_product_profile

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpProductProfile>

=cut

__PACKAGE__->belongs_to(
  "sp_product_profile",
  "CXGN::People::Schema::Result::SpProductProfile",
  { sp_product_profile_id => "sp_product_profile_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-11-15 19:45:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KExQ/FziW9ukr4dZ3mWVFA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
