package SGN::Schema::FishResultComposite;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::FishResultComposite

=cut

__PACKAGE__->table("fish_result_composite");

=head1 ACCESSORS

=head2 fish_result_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=head2 map_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=head2 fish_experimenter_id

  data_type: 'integer'
  is_nullable: 1

=head2 experiment_name

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 clone_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=head2 chromo_num

  data_type: 'smallint'
  default_value: '0)::smallint'
  is_nullable: 0

=head2 chromo_arm

  data_type: 'varchar'
  default_value: 'P'
  is_nullable: 0
  size: 1

=head2 percent_from_centromere

  data_type: 'real'
  default_value: '0)::real'
  is_nullable: 0

=head2 het_or_eu

  data_type: 'varchar'
  is_nullable: 1
  size: 1

=head2 um_from_centromere

  data_type: 'real'
  is_nullable: 1

=head2 um_from_arm_end

  data_type: 'real'
  is_nullable: 1

=head2 um_from_arm_border

  data_type: 'real'
  is_nullable: 1

=head2 mbp_from_arm_end

  data_type: 'real'
  is_nullable: 1

=head2 mbp_from_centromere

  data_type: 'real'
  is_nullable: 1

=head2 mbp_from_arm_border

  data_type: 'real'
  is_nullable: 1

=head2 experiment_group

  data_type: 'varchar'
  is_nullable: 1
  size: 12

=cut

__PACKAGE__->add_columns(
  "fish_result_id",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "map_id",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "fish_experimenter_id",
  { data_type => "integer", is_nullable => 1 },
  "experiment_name",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "clone_id",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "chromo_num",
  {
    data_type     => "smallint",
    default_value => "0)::smallint",
    is_nullable   => 0,
  },
  "chromo_arm",
  { data_type => "varchar", default_value => "P", is_nullable => 0, size => 1 },
  "percent_from_centromere",
  { data_type => "real", default_value => "0)::real", is_nullable => 0 },
  "het_or_eu",
  { data_type => "varchar", is_nullable => 1, size => 1 },
  "um_from_centromere",
  { data_type => "real", is_nullable => 1 },
  "um_from_arm_end",
  { data_type => "real", is_nullable => 1 },
  "um_from_arm_border",
  { data_type => "real", is_nullable => 1 },
  "mbp_from_arm_end",
  { data_type => "real", is_nullable => 1 },
  "mbp_from_centromere",
  { data_type => "real", is_nullable => 1 },
  "mbp_from_arm_border",
  { data_type => "real", is_nullable => 1 },
  "experiment_group",
  { data_type => "varchar", is_nullable => 1, size => 12 },
);
__PACKAGE__->set_primary_key("fish_result_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nJPjSahTyJeD1dzWQt2KLg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
