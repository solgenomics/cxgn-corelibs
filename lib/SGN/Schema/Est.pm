package SGN::Schema::Est;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Est

=cut

__PACKAGE__->table("est");

=head1 ACCESSORS

=head2 est_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'est_est_id_seq'

=head2 read_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 version

  data_type: 'integer'
  is_nullable: 1

=head2 basecaller

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 seq

  data_type: 'text'
  is_nullable: 1

=head2 qscore

  data_type: 'text'
  is_nullable: 1

=head2 call_positions

  data_type: 'text'
  is_nullable: 1

=head2 status

  data_type: 'integer'
  is_nullable: 1

=head2 flags

  data_type: 'bigint'
  is_nullable: 1

=head2 date

  data_type: 'date'
  is_nullable: 1

=head2 genbank_submission_date

  data_type: 'date'
  is_nullable: 1

=head2 genbank_confirmed

  data_type: 'boolean'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "est_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "est_est_id_seq",
  },
  "read_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "version",
  { data_type => "integer", is_nullable => 1 },
  "basecaller",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "seq",
  { data_type => "text", is_nullable => 1 },
  "qscore",
  { data_type => "text", is_nullable => 1 },
  "call_positions",
  { data_type => "text", is_nullable => 1 },
  "status",
  { data_type => "integer", is_nullable => 1 },
  "flags",
  { data_type => "bigint", is_nullable => 1 },
  "date",
  { data_type => "date", is_nullable => 1 },
  "genbank_submission_date",
  { data_type => "date", is_nullable => 1 },
  "genbank_confirmed",
  { data_type => "boolean", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("est_id");

=head1 RELATIONS

=head2 read

Type: belongs_to

Related object: L<SGN::Schema::Seqread>

=cut

__PACKAGE__->belongs_to(
  "read",
  "SGN::Schema::Seqread",
  { read_id => "read_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 est_dbxrefs

Type: has_many

Related object: L<SGN::Schema::EstDbxref>

=cut

__PACKAGE__->has_many(
  "est_dbxrefs",
  "SGN::Schema::EstDbxref",
  { "foreign.est_id" => "self.est_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_report

Type: might_have

Related object: L<SGN::Schema::QcReport>

=cut

__PACKAGE__->might_have(
  "qc_report",
  "SGN::Schema::QcReport",
  { "foreign.est_id" => "self.est_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 unigene_members

Type: has_many

Related object: L<SGN::Schema::UnigeneMember>

=cut

__PACKAGE__->has_many(
  "unigene_members",
  "SGN::Schema::UnigeneMember",
  { "foreign.est_id" => "self.est_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DeimiLHdVqQ+IoBlB+xxog

sub hqi_seq {
    my ( $self ) = @_;

    if( my $qc = $self->qc_report ) {
        return substr( $self->seq, $qc->hqi_start, $qc->hqi_length );
    } else {
        return $self->seq;
    }
}


# You can replace this text with custom content, and it will be preserved on regeneration
1;
