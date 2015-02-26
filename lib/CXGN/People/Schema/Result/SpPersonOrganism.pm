use utf8;
package CXGN::People::Schema::Result::SpPersonOrganism;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpPersonOrganism

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_person_organisms>

=cut

__PACKAGE__->table("sp_person_organisms");

=head1 ACCESSORS

=head2 sp_person_organisms_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_person_organisms_sp_person_organisms_id_seq'

=head2 sp_person_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 organism_id

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "sp_person_organisms_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_person_organisms_sp_person_organisms_id_seq",
  },
  "sp_person_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "organism_id",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_person_organisms_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_person_organisms_id");

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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-26 16:04:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MICJbwizzBtCiil1hDrR2w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
