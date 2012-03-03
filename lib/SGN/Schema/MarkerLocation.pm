package SGN::Schema::MarkerLocation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::MarkerLocation

=cut

__PACKAGE__->table("marker_location");

=head1 ACCESSORS

=head2 location_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'marker_location_location_id_seq'

=head2 lg_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 map_version_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 position

  data_type: 'numeric'
  is_nullable: 0
  size: [9,6]

=head2 confidence_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 subscript

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 position_north

  data_type: 'numeric'
  is_nullable: 1
  size: [8,5]

=head2 position_south

  data_type: 'numeric'
  is_nullable: 1
  size: [8,5]

=cut

__PACKAGE__->add_columns(
  "location_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "marker_location_location_id_seq",
  },
  "lg_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "map_version_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "position",
  { data_type => "numeric", is_nullable => 0, size => [9, 6] },
  "confidence_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "subscript",
  { data_type => "char", is_nullable => 1, size => 1 },
  "position_north",
  { data_type => "numeric", is_nullable => 1, size => [8, 5] },
  "position_south",
  { data_type => "numeric", is_nullable => 1, size => [8, 5] },
);
__PACKAGE__->set_primary_key("location_id");

=head1 RELATIONS

=head2 linkage_group_north_locations

Type: has_many

Related object: L<SGN::Schema::LinkageGroup>

=cut

__PACKAGE__->has_many(
  "linkage_group_north_locations",
  "SGN::Schema::LinkageGroup",
  { "foreign.north_location_id" => "self.location_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 linkage_group_south_locations

Type: has_many

Related object: L<SGN::Schema::LinkageGroup>

=cut

__PACKAGE__->has_many(
  "linkage_group_south_locations",
  "SGN::Schema::LinkageGroup",
  { "foreign.south_location_id" => "self.location_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 marker_experiments

Type: has_many

Related object: L<SGN::Schema::MarkerExperiment>

=cut

__PACKAGE__->has_many(
  "marker_experiments",
  "SGN::Schema::MarkerExperiment",
  { "foreign.location_id" => "self.location_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 lg

Type: belongs_to

Related object: L<SGN::Schema::LinkageGroup>

=cut

__PACKAGE__->belongs_to(
  "lg",
  "SGN::Schema::LinkageGroup",
  { lg_id => "lg_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 confidence

Type: belongs_to

Related object: L<SGN::Schema::MarkerConfidence>

=cut

__PACKAGE__->belongs_to(
  "confidence",
  "SGN::Schema::MarkerConfidence",
  { confidence_id => "confidence_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 map_version

Type: belongs_to

Related object: L<SGN::Schema::MapVersion>

=cut

__PACKAGE__->belongs_to(
  "map_version",
  "SGN::Schema::MapVersion",
  { map_version_id => "map_version_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2P4PX4+ciHl38fLPp715fQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
