package SGN::Schema::FishResult;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::FishResult

=cut

__PACKAGE__->table("fish_result");

=head1 ACCESSORS

=head2 fish_result_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'fish_result_fish_result_id_seq'

=head2 map_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 fish_experimenter_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 experiment_name

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=head2 clone_id

  data_type: 'bigint'
  is_nullable: 0

=head2 chromo_num

  data_type: 'smallint'
  is_nullable: 0

=head2 chromo_arm

  data_type: 'varchar'
  is_nullable: 0
  size: 1

=head2 percent_from_centromere

  data_type: 'real'
  is_nullable: 0

=head2 experiment_group

  data_type: 'varchar'
  is_nullable: 1
  size: 12

=head2 attribution_id

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "fish_result_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "fish_result_fish_result_id_seq",
  },
  "map_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "fish_experimenter_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "experiment_name",
  { data_type => "varchar", is_nullable => 0, size => 10 },
  "clone_id",
  { data_type => "bigint", is_nullable => 0 },
  "chromo_num",
  { data_type => "smallint", is_nullable => 0 },
  "chromo_arm",
  { data_type => "varchar", is_nullable => 0, size => 1 },
  "percent_from_centromere",
  { data_type => "real", is_nullable => 0 },
  "experiment_group",
  { data_type => "varchar", is_nullable => 1, size => 12 },
  "attribution_id",
  { data_type => "bigint", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("fish_result_id");
__PACKAGE__->add_unique_constraint(
  "fish_result_fish_experimenter_clone_id_experiment_name",
  ["fish_experimenter_id", "clone_id", "experiment_name"],
);

=head1 RELATIONS

=head2 fish_experimenter

Type: belongs_to

Related object: L<SGN::Schema::FishExperimenter>

=cut

__PACKAGE__->belongs_to(
  "fish_experimenter",
  "SGN::Schema::FishExperimenter",
  { fish_experimenter_id => "fish_experimenter_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

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

=head2 fish_result_images

Type: has_many

Related object: L<SGN::Schema::FishResultImage>

=cut

__PACKAGE__->has_many(
  "fish_result_images",
  "SGN::Schema::FishResultImage",
  { "foreign.fish_result_id" => "self.fish_result_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3Qs/Qm/jdBZo2BRoSH9EGg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
