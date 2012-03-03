package SGN::Schema::TempMapCorrespondence;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::TempMapCorrespondence

=cut

__PACKAGE__->table("temp_map_correspondence");

=head1 ACCESSORS

=head2 tmc_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'temp_map_correspondence_tmc_id_seq'

=head2 old_map_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 map_version_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "tmc_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "temp_map_correspondence_tmc_id_seq",
  },
  "old_map_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "map_version_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("tmc_id");

=head1 RELATIONS

=head2 old_map

Type: belongs_to

Related object: L<SGN::Schema::DeprecatedMap>

=cut

__PACKAGE__->belongs_to(
  "old_map",
  "SGN::Schema::DeprecatedMap",
  { map_id => "old_map_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 map_version

Type: belongs_to

Related object: L<SGN::Schema::MapVersion>

=cut

__PACKAGE__->belongs_to(
  "map_version",
  "SGN::Schema::MapVersion",
  { map_version_id => "map_version_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mGOVLygbNyVF5q7Z0F/yfw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
