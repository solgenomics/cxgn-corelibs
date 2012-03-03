package SGN::Schema::Sequence;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Sequence

=cut

__PACKAGE__->table("sequence");

=head1 ACCESSORS

=head2 sequence_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sequence_sequence_id_seq'

=head2 sequence

  accessor: undef
  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sequence_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sequence_sequence_id_seq",
  },
  "sequence",
  { accessor => undef, data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("sequence_id");
__PACKAGE__->add_unique_constraint("sequence_unique", ["sequence"]);

=head1 RELATIONS

=head2 pcr_experiment_primer_id_fwds

Type: has_many

Related object: L<SGN::Schema::PcrExperiment>

=cut

__PACKAGE__->has_many(
  "pcr_experiment_primer_id_fwds",
  "SGN::Schema::PcrExperiment",
  { "foreign.primer_id_fwd" => "self.sequence_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pcr_experiment_primer_id_revs

Type: has_many

Related object: L<SGN::Schema::PcrExperiment>

=cut

__PACKAGE__->has_many(
  "pcr_experiment_primer_id_revs",
  "SGN::Schema::PcrExperiment",
  { "foreign.primer_id_rev" => "self.sequence_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pcr_experiment_sequences

Type: has_many

Related object: L<SGN::Schema::PcrExperimentSequence>

=cut

__PACKAGE__->has_many(
  "pcr_experiment_sequences",
  "SGN::Schema::PcrExperimentSequence",
  { "foreign.sequence_id" => "self.sequence_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 snp_sequence_rights

Type: has_many

Related object: L<SGN::Schema::Snp>

=cut

__PACKAGE__->has_many(
  "snp_sequence_rights",
  "SGN::Schema::Snp",
  { "foreign.sequence_right_id" => "self.sequence_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 snp_sequences_left

Type: has_many

Related object: L<SGN::Schema::Snp>

=cut

__PACKAGE__->has_many(
  "snp_sequences_left",
  "SGN::Schema::Snp",
  { "foreign.sequence_left_id" => "self.sequence_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Hckpd8VYR2jFEKhM0XoAqQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
