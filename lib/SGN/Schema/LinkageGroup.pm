package SGN::Schema::LinkageGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::LinkageGroup

=cut

__PACKAGE__->table("linkage_group");

=head1 ACCESSORS

=head2 lg_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'linkage_group_lg_id_seq'

=head2 map_version_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 lg_order

  data_type: 'integer'
  is_nullable: 0

=head2 lg_name

  data_type: 'text'
  is_nullable: 1

=head2 north_location_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 south_location_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "lg_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "linkage_group_lg_id_seq",
  },
  "map_version_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "lg_order",
  { data_type => "integer", is_nullable => 0 },
  "lg_name",
  { data_type => "text", is_nullable => 1 },
  "north_location_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "south_location_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("lg_id");
__PACKAGE__->add_unique_constraint(
  "linkage_group_map_version_id_key",
  ["map_version_id", "lg_order"],
);
__PACKAGE__->add_unique_constraint(
  "linkage_group_map_version_id_key1",
  ["map_version_id", "lg_name"],
);

=head1 RELATIONS

=head2 north_location

Type: belongs_to

Related object: L<SGN::Schema::MarkerLocation>

=cut

__PACKAGE__->belongs_to(
  "north_location",
  "SGN::Schema::MarkerLocation",
  { location_id => "north_location_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 map_version

Type: belongs_to

Related object: L<SGN::Schema::MapVersion>

=cut

__PACKAGE__->belongs_to(
  "map_version",
  "SGN::Schema::MapVersion",
  { map_version_id => "map_version_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 south_location

Type: belongs_to

Related object: L<SGN::Schema::MarkerLocation>

=cut

__PACKAGE__->belongs_to(
  "south_location",
  "SGN::Schema::MarkerLocation",
  { location_id => "south_location_id" },
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
  { "foreign.lg_id" => "self.lg_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AeXr/gcdemGIXiaObXaycw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
