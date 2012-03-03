package SGN::Schema::MarkerCollection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::MarkerCollection

=cut

__PACKAGE__->table("marker_collection");

=head1 ACCESSORS

=head2 mc_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'marker_collection_mc_id_seq'

=head2 mc_name

  data_type: 'text'
  is_nullable: 0

=head2 mc_description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "mc_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "marker_collection_mc_id_seq",
  },
  "mc_name",
  { data_type => "text", is_nullable => 0 },
  "mc_description",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("mc_id");
__PACKAGE__->add_unique_constraint("marker_collection_mc_name_key", ["mc_name"]);

=head1 RELATIONS

=head2 marker_collectibles

Type: has_many

Related object: L<SGN::Schema::MarkerCollectible>

=cut

__PACKAGE__->has_many(
  "marker_collectibles",
  "SGN::Schema::MarkerCollectible",
  { "foreign.mc_id" => "self.mc_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZLN5hiKV+Bxhzzzdbeq75Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
