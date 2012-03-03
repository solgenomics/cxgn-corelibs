package SGN::Schema::TigrtcMembership;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::TigrtcMembership

=cut

__PACKAGE__->table("tigrtc_membership");

=head1 ACCESSORS

=head2 tigrtc_membership_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'tigrtc_membership_tigrtc_membership_id_seq'

=head2 tc_id

  data_type: 'integer'
  is_nullable: 1

=head2 tcindex_id

  data_type: 'integer'
  is_nullable: 1

=head2 read_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "tigrtc_membership_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tigrtc_membership_tigrtc_membership_id_seq",
  },
  "tc_id",
  { data_type => "integer", is_nullable => 1 },
  "tcindex_id",
  { data_type => "integer", is_nullable => 1 },
  "read_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("tigrtc_membership_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BD8nFBZhcQiaB2S9Ddp3fA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
