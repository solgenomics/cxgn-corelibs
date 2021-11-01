use utf8;
package CXGN::People::Schema::Result::SpTeam;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpTeam

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_teams>

=cut

__PACKAGE__->table("sp_teams");

=head1 ACCESSORS

=head2 sp_team_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_teams_sp_team_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 sp_stage_gate_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sp_team_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_teams_sp_team_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "sp_stage_gate_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_team_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_team_id");

=head1 RELATIONS

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


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-10-31 21:58:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JOCesWDnO8t2GFwWPuzbSg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
