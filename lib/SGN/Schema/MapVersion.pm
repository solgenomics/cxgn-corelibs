package SGN::Schema::MapVersion;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::MapVersion

=cut

__PACKAGE__->table("map_version");

=head1 ACCESSORS

=head2 map_version_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'map_version_map_version_id_seq'

=head2 map_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 date_loaded

  data_type: 'date'
  is_nullable: 1

=head2 current_version

  data_type: 'boolean'
  is_nullable: 1

=head2 default_threshold

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 has_il

  data_type: 'boolean'
  is_nullable: 1

=head2 has_physical

  data_type: 'boolean'
  is_nullable: 1

=head2 metadata_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "map_version_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "map_version_map_version_id_seq",
  },
  "map_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "date_loaded",
  { data_type => "date", is_nullable => 1 },
  "current_version",
  { data_type => "boolean", is_nullable => 1 },
  "default_threshold",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "has_il",
  { data_type => "boolean", is_nullable => 1 },
  "has_physical",
  { data_type => "boolean", is_nullable => 1 },
  "metadata_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("map_version_id");

=head1 RELATIONS

=head2 linkage_groups

Type: has_many

Related object: L<SGN::Schema::LinkageGroup>

=cut

__PACKAGE__->has_many(
  "linkage_groups",
  "SGN::Schema::LinkageGroup",
  { "foreign.map_version_id" => "self.map_version_id" },
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

=head2 default_threshold

Type: belongs_to

Related object: L<SGN::Schema::DeprecatedMarkerConfidence>

=cut

__PACKAGE__->belongs_to(
  "default_threshold",
  "SGN::Schema::DeprecatedMarkerConfidence",
  { confidence_id => "default_threshold" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 marker_locations

Type: has_many

Related object: L<SGN::Schema::MarkerLocation>

=cut

__PACKAGE__->has_many(
  "marker_locations",
  "SGN::Schema::MarkerLocation",
  { "foreign.map_version_id" => "self.map_version_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 temp_map_correspondences

Type: has_many

Related object: L<SGN::Schema::TempMapCorrespondence>

=cut

__PACKAGE__->has_many(
  "temp_map_correspondences",
  "SGN::Schema::TempMapCorrespondence",
  { "foreign.map_version_id" => "self.map_version_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8cm9eQqw3sOvPHi6hveD2A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
