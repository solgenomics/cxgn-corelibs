package SGN::Schema::DeprecatedMap;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::DeprecatedMap

=cut

__PACKAGE__->table("deprecated_maps");

=head1 ACCESSORS

=head2 map_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'deprecated_maps_map_id_seq'

=head2 legacy_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=head2 short_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 50

=head2 long_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 250

=head2 number_chromosomes

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=head2 default_threshold

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=head2 header

  data_type: 'text'
  is_nullable: 0

=head2 abstract

  data_type: 'text'
  is_nullable: 0

=head2 genetic_cross

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=head2 population_type

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=head2 population_size

  data_type: 'bigint'
  is_nullable: 1

=head2 seed_available

  data_type: 'bigint'
  is_nullable: 1

=head2 seed_url

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=head2 deprecated_by

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 1

=head2 map_type

  data_type: 'varchar'
  is_nullable: 1
  size: 7

=cut

__PACKAGE__->add_columns(
  "map_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "deprecated_maps_map_id_seq",
  },
  "legacy_id",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "short_name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 50 },
  "long_name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 250 },
  "number_chromosomes",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "default_threshold",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "header",
  { data_type => "text", is_nullable => 0 },
  "abstract",
  { data_type => "text", is_nullable => 0 },
  "genetic_cross",
  { data_type => "varchar", is_nullable => 1, size => 250 },
  "population_type",
  { data_type => "varchar", is_nullable => 1, size => 250 },
  "population_size",
  { data_type => "bigint", is_nullable => 1 },
  "seed_available",
  { data_type => "bigint", is_nullable => 1 },
  "seed_url",
  { data_type => "varchar", is_nullable => 1, size => 250 },
  "deprecated_by",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 1 },
  "map_type",
  { data_type => "varchar", is_nullable => 1, size => 7 },
);
__PACKAGE__->set_primary_key("map_id");

=head1 RELATIONS

=head2 deprecated_linkage_groups

Type: has_many

Related object: L<SGN::Schema::DeprecatedLinkageGroup>

=cut

__PACKAGE__->has_many(
  "deprecated_linkage_groups",
  "SGN::Schema::DeprecatedLinkageGroup",
  { "foreign.map_id" => "self.map_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 deprecated_map_crosses

Type: has_many

Related object: L<SGN::Schema::DeprecatedMapCross>

=cut

__PACKAGE__->has_many(
  "deprecated_map_crosses",
  "SGN::Schema::DeprecatedMapCross",
  { "foreign.map_id" => "self.map_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 deprecated_mapdatas

Type: has_many

Related object: L<SGN::Schema::DeprecatedMapdata>

=cut

__PACKAGE__->has_many(
  "deprecated_mapdatas",
  "SGN::Schema::DeprecatedMapdata",
  { "foreign.map_id" => "self.map_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 fish_results

Type: has_many

Related object: L<SGN::Schema::FishResult>

=cut

__PACKAGE__->has_many(
  "fish_results",
  "SGN::Schema::FishResult",
  { "foreign.map_id" => "self.map_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 temp_map_correspondences

Type: has_many

Related object: L<SGN::Schema::TempMapCorrespondence>

=cut

__PACKAGE__->has_many(
  "temp_map_correspondences",
  "SGN::Schema::TempMapCorrespondence",
  { "foreign.old_map_id" => "self.map_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Z0L3rLo7AASYJCb2N7JKKQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
