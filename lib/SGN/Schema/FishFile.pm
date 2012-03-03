package SGN::Schema::FishFile;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::FishFile

=cut

__PACKAGE__->table("fish_file");

=head1 ACCESSORS

=head2 fish_file_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'fish_file_fish_file_id_seq'

=head2 filename

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 fish_result_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "fish_file_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "fish_file_fish_file_id_seq",
  },
  "filename",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "fish_result_id",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("fish_file_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wFX+WY6+MP6TSA2Sh9nboA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
