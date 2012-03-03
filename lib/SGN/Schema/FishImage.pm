package SGN::Schema::FishImage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::FishImage

=cut

__PACKAGE__->table("fish_image");

=head1 ACCESSORS

=head2 fish_image_id

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 filename

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 fish_result_id

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "fish_image_id",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "filename",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "fish_result_id",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("fish_image_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xu/8TWncnO9lYh3PlaG8Iw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
