package SGN::Schema::PcrExperimentSequence;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::PcrExperimentSequence

=cut

__PACKAGE__->table("pcr_experiment_sequence");

=head1 ACCESSORS

=head2 pcr_experiment_sequence_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn.pcr_experiment_sequence_pcr_experiment_sequence_id_seq'

=head2 pcr_experiment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 sequence_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "pcr_experiment_sequence_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn.pcr_experiment_sequence_pcr_experiment_sequence_id_seq",
  },
  "pcr_experiment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "sequence_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("pcr_experiment_sequence_id");

=head1 RELATIONS

=head2 pcr_experiment

Type: belongs_to

Related object: L<SGN::Schema::PcrExperiment>

=cut

__PACKAGE__->belongs_to(
  "pcr_experiment",
  "SGN::Schema::PcrExperiment",
  { pcr_experiment_id => "pcr_experiment_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 sequence

Type: belongs_to

Related object: L<SGN::Schema::Sequence>

=cut

__PACKAGE__->belongs_to(
  "sequence",
  "SGN::Schema::Sequence",
  { sequence_id => "sequence_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:95CRo7IhbTOypksTtsBcCw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
