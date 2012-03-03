package SGN::Schema::TmMarkersSequence;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::TmMarkersSequence

=cut

__PACKAGE__->table("tm_markers_sequences");

=head1 ACCESSORS

=head2 tm_marker_seq_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=head2 tm_id

  data_type: 'bigint'
  is_nullable: 1

=head2 sequence

  accessor: undef
  data_type: 'text'
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "tm_marker_seq_id",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "tm_id",
  { data_type => "bigint", is_nullable => 1 },
  "sequence",
  { accessor => undef, data_type => "text", is_nullable => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("tm_marker_seq_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ur2YJs3YnkXRw4IjdqsE2Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
