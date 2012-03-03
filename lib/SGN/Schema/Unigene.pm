package SGN::Schema::Unigene;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Unigene

=cut

__PACKAGE__->table("unigene");

=head1 ACCESSORS

=head2 unigene_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'unigene_unigene_id_seq'

=head2 unigene_build_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 consensi_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 cluster_no

  data_type: 'bigint'
  is_nullable: 1

=head2 contig_no

  data_type: 'bigint'
  is_nullable: 1

=head2 nr_members

  data_type: 'bigint'
  is_nullable: 1

=head2 database_name

  data_type: 'text'
  default_value: 'SGN'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 sequence_name

  data_type: 'bigint'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "unigene_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "unigene_unigene_id_seq",
  },
  "unigene_build_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "consensi_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "cluster_no",
  { data_type => "bigint", is_nullable => 1 },
  "contig_no",
  { data_type => "bigint", is_nullable => 1 },
  "nr_members",
  { data_type => "bigint", is_nullable => 1 },
  "database_name",
  {
    data_type     => "text",
    default_value => "SGN",
    is_nullable   => 0,
    original      => { data_type => "varchar" },
  },
  "sequence_name",
  { data_type => "bigint", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("unigene_id");

=head1 RELATIONS

=head2 blast_annotations

Type: has_many

Related object: L<SGN::Schema::BlastAnnotation>

=cut

__PACKAGE__->has_many(
  "blast_annotations",
  "SGN::Schema::BlastAnnotation",
  { "foreign.apply_id" => "self.unigene_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cds

Type: has_many

Related object: L<SGN::Schema::Cd>

=cut

__PACKAGE__->has_many(
  "cds",
  "SGN::Schema::Cd",
  { "foreign.unigene_id" => "self.unigene_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 primer_unigene_matches

Type: has_many

Related object: L<SGN::Schema::PrimerUnigeneMatch>

=cut

__PACKAGE__->has_many(
  "primer_unigene_matches",
  "SGN::Schema::PrimerUnigeneMatch",
  { "foreign.unigene_id" => "self.unigene_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rflp_unigene_associations

Type: has_many

Related object: L<SGN::Schema::RflpUnigeneAssociation>

=cut

__PACKAGE__->has_many(
  "rflp_unigene_associations",
  "SGN::Schema::RflpUnigeneAssociation",
  { "foreign.unigene_id" => "self.unigene_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ssr_primer_unigenes_matches

Type: has_many

Related object: L<SGN::Schema::SsrPrimerUnigeneMatches>

=cut

__PACKAGE__->has_many(
  "ssr_primer_unigenes_matches",
  "SGN::Schema::SsrPrimerUnigeneMatches",
  { "foreign.unigene_id" => "self.unigene_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 consensi

Type: belongs_to

Related object: L<SGN::Schema::UnigeneConsensi>

=cut

__PACKAGE__->belongs_to(
  "consensi",
  "SGN::Schema::UnigeneConsensi",
  { consensi_id => "consensi_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 unigene_build

Type: belongs_to

Related object: L<SGN::Schema::UnigeneBuild>

=cut

__PACKAGE__->belongs_to(
  "unigene_build",
  "SGN::Schema::UnigeneBuild",
  { unigene_build_id => "unigene_build_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 unigene_members

Type: has_many

Related object: L<SGN::Schema::UnigeneMember>

=cut

__PACKAGE__->has_many(
  "unigene_members",
  "SGN::Schema::UnigeneMember",
  { "foreign.unigene_id" => "self.unigene_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HYSA+SrdRkUswvQeCSfweQ

use Carp ();

sub seq {
    my ($self) = @_;

    if( $self->nr_members > 1 ) {
        return $self->consensi->seq;
    } elsif( $self->nr_members == 1 ) {
        return $self->unigene_members->single->est->hqi_seq;
    } else {
        Carp::confess( 'unigene SGN-U'.$self->unigene_id.' has invalid nr_members ('.$self->nr_members.')' );
    }
}


# You can replace this text with custom content, and it will be preserved on regeneration
1;
