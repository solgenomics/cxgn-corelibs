package SGN::Schema::DeprecatedMarker;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::DeprecatedMarker

=cut

__PACKAGE__->table("deprecated_markers");

=head1 ACCESSORS

=head2 marker_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'deprecated_markers_marker_id_seq'

=head2 marker_type

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 marker_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "marker_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "deprecated_markers_marker_id_seq",
  },
  "marker_type",
  {
    data_type      => "bigint",
    default_value  => "0)::bigint",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "marker_name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("marker_id");

=head1 RELATIONS

=head2 deprecated_marker_locations

Type: has_many

Related object: L<SGN::Schema::DeprecatedMarkerLocation>

=cut

__PACKAGE__->has_many(
  "deprecated_marker_locations",
  "SGN::Schema::DeprecatedMarkerLocation",
  { "foreign.marker_id" => "self.marker_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 marker_type

Type: belongs_to

Related object: L<SGN::Schema::DeprecatedMarkerType>

=cut

__PACKAGE__->belongs_to(
  "marker_type",
  "SGN::Schema::DeprecatedMarkerType",
  { marker_type_id => "marker_type" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 markers_derived_from

Type: has_many

Related object: L<SGN::Schema::MarkerDerivedFrom>

=cut

__PACKAGE__->has_many(
  "markers_derived_from",
  "SGN::Schema::MarkerDerivedFrom",
  { "foreign.marker_id" => "self.marker_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 temp_marker_correspondences

Type: has_many

Related object: L<SGN::Schema::TempMarkerCorrespondence>

=cut

__PACKAGE__->has_many(
  "temp_marker_correspondences",
  "SGN::Schema::TempMarkerCorrespondence",
  { "foreign.old_marker_id" => "self.marker_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ajQ/yk/MajjbX4Bw+pLvrw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
