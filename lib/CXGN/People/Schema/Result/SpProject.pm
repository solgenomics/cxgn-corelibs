use utf8;
package CXGN::People::Schema::Result::SpProject;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpProject

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_project>

=cut

__PACKAGE__->table("sp_project");

=head1 ACCESSORS

=head2 sp_project_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_project_sp_project_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 80

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sp_project_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_project_sp_project_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 80 },
  "description",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_project_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_project_id");

=head1 RELATIONS

=head2 sp_project_il_mapping_clone_logs

Type: has_many

Related object: L<CXGN::People::Schema::Result::SpProjectIlMappingCloneLog>

=cut

__PACKAGE__->has_many(
  "sp_project_il_mapping_clone_logs",
  "CXGN::People::Schema::Result::SpProjectIlMappingCloneLog",
  { "foreign.sp_project_id" => "self.sp_project_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sp_project_people

Type: has_many

Related object: L<CXGN::People::Schema::Result::SpProjectPerson>

=cut

__PACKAGE__->has_many(
  "sp_project_people",
  "CXGN::People::Schema::Result::SpProjectPerson",
  { "foreign.sp_project_id" => "self.sp_project_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-26 16:04:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CNyf0k/RGaHf3TPdVVRQ7w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
