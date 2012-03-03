package SGN::Schema::MarkerToMap;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::MarkerToMap

=cut

__PACKAGE__->table("marker_to_map");

=head1 ACCESSORS

=head2 marker_id

  data_type: 'integer'
  is_nullable: 1

=head2 protocol

  data_type: 'text'
  is_nullable: 1

=head2 location_id

  data_type: 'integer'
  is_nullable: 1

=head2 lg_name

  data_type: 'text'
  is_nullable: 1

=head2 lg_order

  data_type: 'integer'
  is_nullable: 1

=head2 position

  data_type: 'numeric'
  is_nullable: 1
  size: [9,6]

=head2 confidence_id

  data_type: 'integer'
  is_nullable: 1

=head2 subscript

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 map_version_id

  data_type: 'integer'
  is_nullable: 1

=head2 map_id

  data_type: 'integer'
  is_nullable: 1

=head2 parent_1

  data_type: 'integer'
  is_nullable: 1

=head2 parent_2

  data_type: 'integer'
  is_nullable: 1

=head2 current_version

  data_type: 'boolean'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "marker_id",
  { data_type => "integer", is_nullable => 1 },
  "protocol",
  { data_type => "text", is_nullable => 1 },
  "location_id",
  { data_type => "integer", is_nullable => 1 },
  "lg_name",
  { data_type => "text", is_nullable => 1 },
  "lg_order",
  { data_type => "integer", is_nullable => 1 },
  "position",
  { data_type => "numeric", is_nullable => 1, size => [9, 6] },
  "confidence_id",
  { data_type => "integer", is_nullable => 1 },
  "subscript",
  { data_type => "char", is_nullable => 1, size => 1 },
  "map_version_id",
  { data_type => "integer", is_nullable => 1 },
  "map_id",
  { data_type => "integer", is_nullable => 1 },
  "parent_1",
  { data_type => "integer", is_nullable => 1 },
  "parent_2",
  { data_type => "integer", is_nullable => 1 },
  "current_version",
  { data_type => "boolean", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DRojZP1ZUqn3TBUzFAH+/w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
