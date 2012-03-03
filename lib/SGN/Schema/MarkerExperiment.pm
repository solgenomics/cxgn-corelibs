package SGN::Schema::MarkerExperiment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::MarkerExperiment

=cut

__PACKAGE__->table("marker_experiment");

=head1 ACCESSORS

=head2 marker_experiment_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'marker_experiment_marker_experiment_id_seq'

=head2 marker_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 pcr_experiment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 rflp_experiment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 location_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 protocol

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "marker_experiment_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "marker_experiment_marker_experiment_id_seq",
  },
  "marker_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "pcr_experiment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "rflp_experiment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "location_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "protocol",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("marker_experiment_id");
__PACKAGE__->add_unique_constraint(
  "marker_experiment_pcr_experiment_id_key",
  ["pcr_experiment_id", "rflp_experiment_id", "location_id"],
);

=head1 RELATIONS

=head2 pcr_experiment

Type: belongs_to

Related object: L<SGN::Schema::PcrExperiment>

=cut

__PACKAGE__->belongs_to(
  "pcr_experiment",
  "SGN::Schema::PcrExperiment",
  { pcr_experiment_id => "pcr_experiment_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 location

Type: belongs_to

Related object: L<SGN::Schema::MarkerLocation>

=cut

__PACKAGE__->belongs_to(
  "location",
  "SGN::Schema::MarkerLocation",
  { location_id => "location_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 rflp_experiment

Type: belongs_to

Related object: L<SGN::Schema::RflpMarker>

=cut

__PACKAGE__->belongs_to(
  "rflp_experiment",
  "SGN::Schema::RflpMarker",
  { rflp_id => "rflp_experiment_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LACXBxVUAZwsF+fcMy8Y3g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
