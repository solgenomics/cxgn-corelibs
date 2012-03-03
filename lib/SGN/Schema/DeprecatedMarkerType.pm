package SGN::Schema::DeprecatedMarkerType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::DeprecatedMarkerType

=cut

__PACKAGE__->table("deprecated_marker_types");

=head1 ACCESSORS

=head2 marker_type_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'deprecated_marker_types_marker_type_id_seq'

=head2 type_name

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 marker_table

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=cut

__PACKAGE__->add_columns(
  "marker_type_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "deprecated_marker_types_marker_type_id_seq",
  },
  "type_name",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "marker_table",
  { data_type => "varchar", is_nullable => 1, size => 128 },
);
__PACKAGE__->set_primary_key("marker_type_id");

=head1 RELATIONS

=head2 deprecated_markers

Type: has_many

Related object: L<SGN::Schema::DeprecatedMarker>

=cut

__PACKAGE__->has_many(
  "deprecated_markers",
  "SGN::Schema::DeprecatedMarker",
  { "foreign.marker_type" => "self.marker_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QklUU7Zc9A2ghjKSIvJRMw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
