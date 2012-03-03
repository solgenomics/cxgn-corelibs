package SGN::Schema::FishKaryotypeConstantsOld;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::FishKaryotypeConstantsOld

=cut

__PACKAGE__->table("fish_karyotype_constants_old");

=head1 ACCESSORS

=head2 chromo_num

  data_type: 'smallint'
  default_value: '0)::smallint'
  is_nullable: 0

=head2 chromo_length

  data_type: 'real'
  is_nullable: 1

=head2 chromo_arm_ratio

  data_type: 'real'
  is_nullable: 1

=head2 short_arm_length

  data_type: 'real'
  is_nullable: 1

=head2 short_arm_eu_length

  data_type: 'real'
  is_nullable: 1

=head2 short_arm_het_length

  data_type: 'real'
  is_nullable: 1

=head2 long_arm_length

  data_type: 'real'
  is_nullable: 1

=head2 long_arm_eu_length

  data_type: 'real'
  is_nullable: 1

=head2 long_arm_het_length

  data_type: 'real'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "chromo_num",
  {
    data_type     => "smallint",
    default_value => "0)::smallint",
    is_nullable   => 0,
  },
  "chromo_length",
  { data_type => "real", is_nullable => 1 },
  "chromo_arm_ratio",
  { data_type => "real", is_nullable => 1 },
  "short_arm_length",
  { data_type => "real", is_nullable => 1 },
  "short_arm_eu_length",
  { data_type => "real", is_nullable => 1 },
  "short_arm_het_length",
  { data_type => "real", is_nullable => 1 },
  "long_arm_length",
  { data_type => "real", is_nullable => 1 },
  "long_arm_eu_length",
  { data_type => "real", is_nullable => 1 },
  "long_arm_het_length",
  { data_type => "real", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("chromo_num");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MWu9so2oKdhOIqWNeg9h0g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
