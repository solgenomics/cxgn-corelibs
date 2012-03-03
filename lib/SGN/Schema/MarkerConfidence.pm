package SGN::Schema::MarkerConfidence;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::MarkerConfidence

=cut

__PACKAGE__->table("marker_confidence");

=head1 ACCESSORS

=head2 confidence_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'marker_confidence_confidence_id_seq'

=head2 confidence_name

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "confidence_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "marker_confidence_confidence_id_seq",
  },
  "confidence_name",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("confidence_id");
__PACKAGE__->add_unique_constraint("marker_confidence_confidence_name_key", ["confidence_name"]);

=head1 RELATIONS

=head2 marker_locations

Type: has_many

Related object: L<SGN::Schema::MarkerLocation>

=cut

__PACKAGE__->has_many(
  "marker_locations",
  "SGN::Schema::MarkerLocation",
  { "foreign.confidence_id" => "self.confidence_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:roKn9U2mzGcfcoxTGgFjuw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
