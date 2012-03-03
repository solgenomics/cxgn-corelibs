package SGN::Schema::FishResultImage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::FishResultImage

=cut

__PACKAGE__->table("fish_result_image");

=head1 ACCESSORS

=head2 fish_result_image_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'fish_result_image_fish_result_image_id_seq'

=head2 image_id

  data_type: 'bigint'
  is_nullable: 1

=head2 fish_result_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "fish_result_image_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "fish_result_image_fish_result_image_id_seq",
  },
  "image_id",
  { data_type => "bigint", is_nullable => 1 },
  "fish_result_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("fish_result_image_id");

=head1 RELATIONS

=head2 fish_result

Type: belongs_to

Related object: L<SGN::Schema::FishResult>

=cut

__PACKAGE__->belongs_to(
  "fish_result",
  "SGN::Schema::FishResult",
  { fish_result_id => "fish_result_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:L5lujszy4fNROQMVyCqPqw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
