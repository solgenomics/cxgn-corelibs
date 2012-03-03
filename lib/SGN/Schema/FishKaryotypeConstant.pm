package SGN::Schema::FishKaryotypeConstant;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::FishKaryotypeConstant

=cut

__PACKAGE__->table("fish_karyotype_constants");

=head1 ACCESSORS

=head2 fish_experimenter_id

  data_type: 'integer'
  is_nullable: 0

=head2 chromo_num

  data_type: 'smallint'
  is_nullable: 0

=head2 chromo_arm

  data_type: 'text'
  is_nullable: 0

=head2 arm_length

  data_type: 'numeric'
  is_nullable: 0
  size: [5,2]

=head2 arm_eu_length

  data_type: 'numeric'
  is_nullable: 0
  size: [5,2]

=head2 arm_het_length

  data_type: 'numeric'
  is_nullable: 0
  size: [5,2]

=cut

__PACKAGE__->add_columns(
  "fish_experimenter_id",
  { data_type => "integer", is_nullable => 0 },
  "chromo_num",
  { data_type => "smallint", is_nullable => 0 },
  "chromo_arm",
  { data_type => "text", is_nullable => 0 },
  "arm_length",
  { data_type => "numeric", is_nullable => 0, size => [5, 2] },
  "arm_eu_length",
  { data_type => "numeric", is_nullable => 0, size => [5, 2] },
  "arm_het_length",
  { data_type => "numeric", is_nullable => 0, size => [5, 2] },
);
__PACKAGE__->set_primary_key("fish_experimenter_id", "chromo_num", "chromo_arm");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YQHAN1Jx5OvUQ6YPNWTlnQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
