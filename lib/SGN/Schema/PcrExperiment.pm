package SGN::Schema::PcrExperiment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::PcrExperiment

=cut

__PACKAGE__->table("pcr_experiment");

=head1 ACCESSORS

=head2 pcr_experiment_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'pcr_experiment_pcr_experiment_id_seq'

=head2 marker_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 mg_concentration

  data_type: 'real'
  is_nullable: 1

=head2 annealing_temp

  data_type: 'bigint'
  is_nullable: 1

=head2 primer_id_fwd

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 primer_id_rev

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 subscript

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 experiment_type_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 map_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 additional_enzymes

  data_type: 'varchar'
  is_nullable: 1
  size: 1023

=head2 primer_type

  data_type: 'varchar'
  is_nullable: 1
  size: 4

=head2 predicted

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 primer_id_pd

  data_type: 'bigint'
  is_nullable: 1

=head2 accession_id

  data_type: 'varchar'
  is_nullable: 1
  size: 7

=head2 stock_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "pcr_experiment_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "pcr_experiment_pcr_experiment_id_seq",
  },
  "marker_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "mg_concentration",
  { data_type => "real", is_nullable => 1 },
  "annealing_temp",
  { data_type => "bigint", is_nullable => 1 },
  "primer_id_fwd",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "primer_id_rev",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "subscript",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "experiment_type_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "map_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "additional_enzymes",
  { data_type => "varchar", is_nullable => 1, size => 1023 },
  "primer_type",
  { data_type => "varchar", is_nullable => 1, size => 4 },
  "predicted",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "primer_id_pd",
  { data_type => "bigint", is_nullable => 1 },
  "accession_id",
  { data_type => "varchar", is_nullable => 1, size => 7 },
  "stock_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("pcr_experiment_id");

=head1 RELATIONS

=head2 marker_experiments

Type: has_many

Related object: L<SGN::Schema::MarkerExperiment>

=cut

__PACKAGE__->has_many(
  "marker_experiments",
  "SGN::Schema::MarkerExperiment",
  { "foreign.pcr_experiment_id" => "self.pcr_experiment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pcr_exp_accessions

Type: has_many

Related object: L<SGN::Schema::PcrExpAccession>

=cut

__PACKAGE__->has_many(
  "pcr_exp_accessions",
  "SGN::Schema::PcrExpAccession",
  { "foreign.pcr_experiment_id" => "self.pcr_experiment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 map

Type: belongs_to

Related object: L<SGN::Schema::Map>

=cut

__PACKAGE__->belongs_to(
  "map",
  "SGN::Schema::Map",
  { map_id => "map_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 primer_id_fwd

Type: belongs_to

Related object: L<SGN::Schema::Sequence>

=cut

__PACKAGE__->belongs_to(
  "primer_id_fwd",
  "SGN::Schema::Sequence",
  { sequence_id => "primer_id_fwd" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 marker

Type: belongs_to

Related object: L<SGN::Schema::Marker>

=cut

__PACKAGE__->belongs_to(
  "marker",
  "SGN::Schema::Marker",
  { marker_id => "marker_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 primer_id_rev

Type: belongs_to

Related object: L<SGN::Schema::Sequence>

=cut

__PACKAGE__->belongs_to(
  "primer_id_rev",
  "SGN::Schema::Sequence",
  { sequence_id => "primer_id_rev" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 experiment_type

Type: belongs_to

Related object: L<SGN::Schema::ExperimentType>

=cut

__PACKAGE__->belongs_to(
  "experiment_type",
  "SGN::Schema::ExperimentType",
  { experiment_type_id => "experiment_type_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 pcr_experiment_sequences

Type: has_many

Related object: L<SGN::Schema::PcrExperimentSequence>

=cut

__PACKAGE__->has_many(
  "pcr_experiment_sequences",
  "SGN::Schema::PcrExperimentSequence",
  { "foreign.pcr_experiment_id" => "self.pcr_experiment_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Czl2BcSeTOW18DpeUyqtdw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
