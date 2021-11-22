use utf8;
package CXGN::People::Schema::Result::SpProductProfile;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpProductProfile

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_product_profile>

=cut

__PACKAGE__->table("sp_product_profile");

=head1 ACCESSORS

=head2 sp_product_profile_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_product_profile_sp_product_profile_id_seq'

=head2 breeding_program_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 sp_stage_gate_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 scope

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 sp_person_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 create_date

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 modified_date

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "sp_product_profile_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_product_profile_sp_product_profile_id_seq",
  },
#  "breeding_program_id",
# { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "sp_stage_gate_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "scope",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "sp_person_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "create_date",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "modified_date",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_product_profile_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_product_profile_id");

=head1 RELATIONS

=head2 sp_person

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpPerson>

=cut

__PACKAGE__->belongs_to(
  "sp_person",
  "CXGN::People::Schema::Result::SpPerson",
  { sp_person_id => "sp_person_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 sp_product_profile_projects

Type: has_many

Related object: L<CXGN::People::Schema::Result::SpProductProfileProject>

=cut

__PACKAGE__->has_many(
  "sp_product_profile_projects",
  "CXGN::People::Schema::Result::SpProductProfileProject",
  { "foreign.sp_product_profile_id" => "self.sp_product_profile_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sp_product_profileprops

Type: has_many

Related object: L<CXGN::People::Schema::Result::SpProductProfileprop>

=cut

__PACKAGE__->has_many(
  "sp_product_profileprops",
  "CXGN::People::Schema::Result::SpProductProfileprop",
  { "foreign.sp_product_profile_id" => "self.sp_product_profile_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sp_stage_gate

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpStageGate>

=cut

__PACKAGE__->belongs_to(
  "sp_stage_gate",
  "CXGN::People::Schema::Result::SpStageGate",
  { sp_stage_gate_id => "sp_stage_gate_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-11-15 19:45:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3DhAHeWIwCBgVycNdWUC/A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
