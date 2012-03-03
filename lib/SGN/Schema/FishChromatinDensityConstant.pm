package SGN::Schema::FishChromatinDensityConstant;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::FishChromatinDensityConstant

=cut

__PACKAGE__->table("fish_chromatin_density_constants");

=head1 ACCESSORS

=head2 arm

  data_type: 'varchar'
  default_value: 'E'
  is_nullable: 0
  size: 1

=head2 density

  data_type: 'real'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "arm",
  { data_type => "varchar", default_value => "E", is_nullable => 0, size => 1 },
  "density",
  { data_type => "real", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("arm");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ACCZqFUM8p3nR/j4MmmhqA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
