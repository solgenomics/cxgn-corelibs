package SGN::Schema::RflpSequence;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("rflp_sequences");
__PACKAGE__->add_columns(
  "seq_id",
  {
    data_type => "integer",
    default_value => "nextval('rflp_sequences_seq_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "fasta_sequence",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("seq_id");
__PACKAGE__->has_many(
  "rflp_markers_reverse_seq_ids",
  "SGN::Schema::RflpMarker",
  { "foreign.reverse_seq_id" => "self.seq_id" },
);
__PACKAGE__->has_many(
  "rflp_markers_forward_seq_ids",
  "SGN::Schema::RflpMarker",
  { "foreign.forward_seq_id" => "self.seq_id" },
);
__PACKAGE__->has_many(
  "rflp_unigene_associations",
  "SGN::Schema::RflpUnigeneAssociation",
  { "foreign.rflp_seq_id" => "self.seq_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:F/p7mn3ehGtnjlo2jBYtGA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
