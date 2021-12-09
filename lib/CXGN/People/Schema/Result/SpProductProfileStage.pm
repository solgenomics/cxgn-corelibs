use utf8;
package CXGN::People::Schema::Result::SpProductProfileStage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpProductProfileStage

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_product_profile_stage>

=cut

__PACKAGE__->table("sp_product_profile_stage");

=head1 ACCESSORS

=head2 sp_product_profile_stage_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_product_profile_stage_sp_product_profile_stage_id_seq'

=head2 sp_product_profile_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 sp_stage_gate_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 sp_person_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 create_date

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "sp_product_profile_stage_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_product_profile_stage_sp_product_profile_stage_id_seq",
  },
  "sp_product_profile_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "sp_stage_gate_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "sp_person_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "create_date",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_product_profile_stage_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_product_profile_stage_id");

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


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-12-09 21:29:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JC4IT61yC6km7IO3YMmpLw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
