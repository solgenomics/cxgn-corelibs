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

=head2 sp_person_teams

Type: has_many

Related object: L<CXGN::People::Schema::Result::SpPersonTeam>

=cut

__PACKAGE__->has_many(
  "sp_person_teams",
  "CXGN::People::Schema::Result::SpPersonTeam",
  { "foreign.sp_team_id" => "self.sp_team_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-11-02 01:14:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uM6kFqivAFlZ3a9WXhpVog
# These lines were loaded from '/home/production/cxgn/cxgn-corelibs/lib/CXGN/People/Schema/Result/SpTeam.pm' found in @INC.
# They are now part of the custom portion of this file
# for you to hand-edit.  If you do not either delete
# this section or remove that file from @INC, this section
# will be repeated redundantly when you re-create this
# file again via Loader!  See skip_load_external to disable
# this feature.

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

=head2 sp_person_teams

Type: has_many

Related object: L<CXGN::People::Schema::Result::ListItem>

=cut

__PACKAGE__->has_many(
  "sp_person_team",
  "CXGN::People::Schema::Result::SpPersonTeam",
  { "foreign.sp_team_id" => "self.sp_team_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);




# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
# End of lines loaded from '/home/production/cxgn/cxgn-corelibs/lib/CXGN/People/Schema/Result/SpTeam.pm'


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
