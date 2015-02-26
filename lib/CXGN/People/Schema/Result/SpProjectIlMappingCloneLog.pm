use utf8;
package CXGN::People::Schema::Result::SpProjectIlMappingCloneLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpProjectIlMappingCloneLog

=head1 DESCRIPTION

linking table showing which sp_project is currently assigned to map a given clone to the zamir IL lines.  also provides a modification history with is_current and created columns

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_project_il_mapping_clone_log>

=cut

__PACKAGE__->table("sp_project_il_mapping_clone_log");

=head1 ACCESSORS

=head2 sp_project_il_mapping_clone_log_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_project_il_mapping_clone_l_sp_project_il_mapping_clone_l_seq'

=head2 sp_project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 sp_person_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 clone_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 is_current

  data_type: 'boolean'
  default_value: true
  is_nullable: 1

=head2 created

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "sp_project_il_mapping_clone_log_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_project_il_mapping_clone_l_sp_project_il_mapping_clone_l_seq",
  },
  "sp_project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "sp_person_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "clone_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "is_current",
  { data_type => "boolean", default_value => \"true", is_nullable => 1 },
  "created",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
);

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

=head2 sp_project

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpProject>

=cut

__PACKAGE__->belongs_to(
  "sp_project",
  "CXGN::People::Schema::Result::SpProject",
  { sp_project_id => "sp_project_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-26 16:04:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:o5+XaSuPZ3KDnR2QVnVe5Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
