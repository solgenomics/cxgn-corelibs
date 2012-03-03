package SGN::Schema::TempCapsCorrespondence;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::TempCapsCorrespondence

=cut

__PACKAGE__->table("temp_caps_correspondence");

=head1 ACCESSORS

=head2 tcc_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'temp_caps_correspondence_tcc_id_seq'

=head2 old_marker_id

  data_type: 'integer'
  is_nullable: 1

=head2 new_marker_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "tcc_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "temp_caps_correspondence_tcc_id_seq",
  },
  "old_marker_id",
  { data_type => "integer", is_nullable => 1 },
  "new_marker_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("tcc_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aXrYHcEdAAKPM42jD48IDQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
