package SGN::Schema::DeprecatedMarkerConfidence;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::DeprecatedMarkerConfidence

=cut

__PACKAGE__->table("deprecated_marker_confidences");

=head1 ACCESSORS

=head2 confidence_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'deprecated_marker_confidences_confidence_id_seq'

=head2 confidence_name

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 legacy_conf_id

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "confidence_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "deprecated_marker_confidences_confidence_id_seq",
  },
  "confidence_name",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "legacy_conf_id",
  { data_type => "bigint", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("confidence_id");
__PACKAGE__->add_unique_constraint("legacy_conf_id_unique", ["legacy_conf_id"]);

=head1 RELATIONS

=head2 deprecated_marker_locations

Type: has_many

Related object: L<SGN::Schema::DeprecatedMarkerLocation>

=cut

__PACKAGE__->has_many(
  "deprecated_marker_locations",
  "SGN::Schema::DeprecatedMarkerLocation",
  { "foreign.confidence" => "self.legacy_conf_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 map_versions

Type: has_many

Related object: L<SGN::Schema::MapVersion>

=cut

__PACKAGE__->has_many(
  "map_versions",
  "SGN::Schema::MapVersion",
  { "foreign.default_threshold" => "self.confidence_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jVtQOSMFK+hZZ3sajdmzqA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
