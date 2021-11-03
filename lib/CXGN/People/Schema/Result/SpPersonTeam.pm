use utf8;
package CXGN::People::Schema::Result::SpPersonTeam;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpPersonTeam

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_person_team>

=cut

__PACKAGE__->table("sp_person_team");

=head1 ACCESSORS

=head2 sp_person_team_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_person_team_sp_person_team_id_seq'

=head2 sp_person_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 functional_role

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 sp_team_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sp_person_team_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_person_team_sp_person_team_id_seq",
  },
  "sp_person_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "functional_role",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "sp_team_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_person_team_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_person_team_id");

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

=head2 sp_team

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpTeam>

=cut

__PACKAGE__->belongs_to(
  "sp_team",
  "CXGN::People::Schema::Result::SpTeam",
  { sp_team_id => "sp_team_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-11-02 01:14:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:t4C91+p5oiFpB+xKU8YAbA
# These lines were loaded from '/home/production/cxgn/cxgn-corelibs/lib/CXGN/People/Schema/Result/SpPersonTeam.pm' found in @INC.
# They are now part of the custom portion of this file
# for you to hand-edit.  If you do not either delete
# this section or remove that file from @INC, this section
# will be repeated redundantly when you re-create this
# file again via Loader!  See skip_load_external to disable
# this feature.

use utf8;
package CXGN::People::Schema::Result::SpPersonTeam;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpPersonTeam

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_person_team>

=cut

__PACKAGE__->table("sp_person_team");

=head1 ACCESSORS

=head2 sp_person_team_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_person_team_sp_person_team_id_seq'

=head2 sp_person_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 functional_role

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "sp_person_team_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_person_team_sp_person_team_id_seq",
  },
  "sp_person_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "functional_role",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_person_team_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_person_team_id");

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


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-10-31 21:58:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HZMirAhIHOR0s7mIMXC9xg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
# End of lines loaded from '/home/production/cxgn/cxgn-corelibs/lib/CXGN/People/Schema/Result/SpPersonTeam.pm'


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
