use utf8;
package CXGN::People::Schema::Result::SpStageGate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpStageGate

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_stage_gate>

=cut

__PACKAGE__->table("sp_stage_gate");

=head1 ACCESSORS

=head2 sp_stage_gate_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_stage_gate_sp_stage_gate_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 breeding_program_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sp_stage_gate_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_stage_gate_sp_stage_gate_id_seq",
  },
    "sp_stage_gate_definition_id",
    { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
      
    "name",
    { data_type => "varchar", is_nullable => 1, size => 100 },
  "description",
    { data_type => "text", is_nullable => 1 },

    "season",
    { data_type => "varchar", is_nullable => 1, size => 100 },

    "year",
    { data_type => "varchar", is_nullable => 1, size => 4 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_stage_gate_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_stage_gate_id");

=head1 RELATIONS

=head2 sp_teams

Type: has_many

Related object: L<CXGN::People::Schema::Result::SpTeam>

=cut

__PACKAGE__->has_many(
  "sp_teams",
  "CXGN::People::Schema::Result::SpTeam",
  { "foreign.sp_stage_gate_id" => "self.sp_stage_gate_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-10-31 21:58:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fBD3sjvsGnnCXGfw51wwnA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
