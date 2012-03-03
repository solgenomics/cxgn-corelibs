package SGN::Schema::TigrtcIndex;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::TigrtcIndex

=cut

__PACKAGE__->table("tigrtc_index");

=head1 ACCESSORS

=head2 tcindex_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'tigrtc_index_tcindex_id_seq'

=head2 index_name

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=cut

__PACKAGE__->add_columns(
  "tcindex_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tigrtc_index_tcindex_id_seq",
  },
  "index_name",
  { data_type => "varchar", is_nullable => 1, size => 40 },
);
__PACKAGE__->set_primary_key("tcindex_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BH9l17I5337w6Ntxj8w3pA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
