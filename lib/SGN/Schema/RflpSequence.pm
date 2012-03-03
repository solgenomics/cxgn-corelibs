package SGN::Schema::RflpSequence;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::RflpSequence

=cut

__PACKAGE__->table("rflp_sequences");

=head1 ACCESSORS

=head2 seq_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'rflp_sequences_seq_id_seq'

=head2 fasta_sequence

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "seq_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "rflp_sequences_seq_id_seq",
  },
  "fasta_sequence",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("seq_id");

=head1 RELATIONS

=head2 rflp_markers_reverse_seqs

Type: has_many

Related object: L<SGN::Schema::RflpMarker>

=cut

__PACKAGE__->has_many(
  "rflp_markers_reverse_seqs",
  "SGN::Schema::RflpMarker",
  { "foreign.reverse_seq_id" => "self.seq_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rflp_markers_forward_seqs

Type: has_many

Related object: L<SGN::Schema::RflpMarker>

=cut

__PACKAGE__->has_many(
  "rflp_markers_forward_seqs",
  "SGN::Schema::RflpMarker",
  { "foreign.forward_seq_id" => "self.seq_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rflp_unigene_associations

Type: has_many

Related object: L<SGN::Schema::RflpUnigeneAssociation>

=cut

__PACKAGE__->has_many(
  "rflp_unigene_associations",
  "SGN::Schema::RflpUnigeneAssociation",
  { "foreign.rflp_seq_id" => "self.seq_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:87+xNwu87RpRdUP2/z7cEg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
