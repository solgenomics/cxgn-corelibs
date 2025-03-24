use utf8;
package CXGN::People::Schema::Result::SpJob;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpJob

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_job>

=cut

__PACKAGE__->table("sp_job");

=head1 ACCESSORS

=head2 sp_job_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_job_sp_job_id_seq'

=head2 sp_person_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 slurm_id

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 status

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 create_timestamp

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 finish_timestamp

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 type_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 args

  data_type: 'jsonb'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sp_job_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_job_sp_job_id_seq",
  },
  "sp_person_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "slurm_id",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "create_timestamp",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "finish_timestamp",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "type_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "args",
  { data_type => "jsonb", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_job_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_job_id");

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


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2025-03-24 18:14:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:I/cnzF2xmkkhsV+/U7d+EQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;