package SGN::Schema::DeprecatedMapdata;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::DeprecatedMapdata

=cut

__PACKAGE__->table("deprecated_mapdata");

=head1 ACCESSORS

=head2 loc_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'deprecated_mapdata_loc_id_seq'

=head2 map_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 lg_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 offset

  data_type: 'numeric'
  is_nullable: 1
  size: [8,5]

=head2 loc_type

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=head2 loc_order

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "loc_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "deprecated_mapdata_loc_id_seq",
  },
  "map_id",
  {
    data_type      => "bigint",
    default_value  => "0)::bigint",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "lg_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "offset",
  { data_type => "numeric", is_nullable => 1, size => [8, 5] },
  "loc_type",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "loc_order",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("loc_id");

=head1 RELATIONS

=head2 map

Type: belongs_to

Related object: L<SGN::Schema::DeprecatedMap>

=cut

__PACKAGE__->belongs_to(
  "map",
  "SGN::Schema::DeprecatedMap",
  { map_id => "map_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 lg

Type: belongs_to

Related object: L<SGN::Schema::DeprecatedLinkageGroup>

=cut

__PACKAGE__->belongs_to(
  "lg",
  "SGN::Schema::DeprecatedLinkageGroup",
  { lg_id => "lg_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 deprecated_marker_locations

Type: has_many

Related object: L<SGN::Schema::DeprecatedMarkerLocation>

=cut

__PACKAGE__->has_many(
  "deprecated_marker_locations",
  "SGN::Schema::DeprecatedMarkerLocation",
  { "foreign.loc_id" => "self.loc_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:orOD30Vq4ddEG6GH3KNMSw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
