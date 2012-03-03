package SGN::Schema::ExperimentType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::ExperimentType

=cut

__PACKAGE__->table("experiment_type");

=head1 ACCESSORS

=head2 experiment_type_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'experiment_type_experiment_type_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "experiment_type_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "experiment_type_experiment_type_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "description",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("experiment_type_id");

=head1 RELATIONS

=head2 pcr_experiments

Type: has_many

Related object: L<SGN::Schema::PcrExperiment>

=cut

__PACKAGE__->has_many(
  "pcr_experiments",
  "SGN::Schema::PcrExperiment",
  { "foreign.experiment_type_id" => "self.experiment_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:M6VKiqWKu+9a/dtKynIa4Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
