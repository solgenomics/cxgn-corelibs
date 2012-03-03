package SGN::Schema::DeprecatedMarkerLocation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::DeprecatedMarkerLocation

=cut

__PACKAGE__->table("deprecated_marker_locations");

=head1 ACCESSORS

=head2 marker_location_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'deprecated_marker_locations_marker_location_id_seq'

=head2 marker_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 loc_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 confidence

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 order_in_loc

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=head2 location_subscript

  data_type: 'char'
  is_nullable: 1
  size: 2

=head2 mapmaker_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "marker_location_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "deprecated_marker_locations_marker_location_id_seq",
  },
  "marker_id",
  {
    data_type      => "bigint",
    default_value  => "0)::bigint",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "loc_id",
  {
    data_type      => "bigint",
    default_value  => "0)::bigint",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "confidence",
  {
    data_type      => "bigint",
    default_value  => "0)::bigint",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "order_in_loc",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "location_subscript",
  { data_type => "char", is_nullable => 1, size => 2 },
  "mapmaker_id",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("marker_location_id");

=head1 RELATIONS

=head2 loc

Type: belongs_to

Related object: L<SGN::Schema::DeprecatedMapdata>

=cut

__PACKAGE__->belongs_to(
  "loc",
  "SGN::Schema::DeprecatedMapdata",
  { loc_id => "loc_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 marker

Type: belongs_to

Related object: L<SGN::Schema::DeprecatedMarker>

=cut

__PACKAGE__->belongs_to(
  "marker",
  "SGN::Schema::DeprecatedMarker",
  { marker_id => "marker_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 confidence

Type: belongs_to

Related object: L<SGN::Schema::DeprecatedMarkerConfidence>

=cut

__PACKAGE__->belongs_to(
  "confidence",
  "SGN::Schema::DeprecatedMarkerConfidence",
  { legacy_conf_id => "confidence" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9egEjMuXtTqa46MzDYvChg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
