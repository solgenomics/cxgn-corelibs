package SGN::Schema::MarkerCollectible;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::MarkerCollectible

=cut

__PACKAGE__->table("marker_collectible");

=head1 ACCESSORS

=head2 marker_collectible_dummy_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'marker_collectible_marker_collectible_dummy_id_seq'

=head2 marker_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 mc_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "marker_collectible_dummy_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "marker_collectible_marker_collectible_dummy_id_seq",
  },
  "marker_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "mc_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("marker_collectible_dummy_id");
__PACKAGE__->add_unique_constraint("marker_collectible_marker_id_key", ["marker_id", "mc_id"]);

=head1 RELATIONS

=head2 mc

Type: belongs_to

Related object: L<SGN::Schema::MarkerCollection>

=cut

__PACKAGE__->belongs_to(
  "mc",
  "SGN::Schema::MarkerCollection",
  { mc_id => "mc_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 marker

Type: belongs_to

Related object: L<SGN::Schema::Marker>

=cut

__PACKAGE__->belongs_to(
  "marker",
  "SGN::Schema::Marker",
  { marker_id => "marker_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Jx+9+xVR4fa6jp7x3Q6hZg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
