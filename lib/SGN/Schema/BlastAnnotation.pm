package SGN::Schema::BlastAnnotation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::BlastAnnotation

=cut

__PACKAGE__->table("blast_annotations");

=head1 ACCESSORS

=head2 blast_annotation_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'blast_annotations_blast_annotation_id_seq'

=head2 apply_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 apply_type

  data_type: 'integer'
  is_nullable: 1

=head2 blast_target_id

  data_type: 'integer'
  is_nullable: 1

=head2 n_hits

  data_type: 'integer'
  is_nullable: 1

=head2 hits_stored

  data_type: 'integer'
  is_nullable: 1

=head2 last_updated

  data_type: 'integer'
  is_nullable: 1

=head2 host

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 pid

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "blast_annotation_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "blast_annotations_blast_annotation_id_seq",
  },
  "apply_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "apply_type",
  { data_type => "integer", is_nullable => 1 },
  "blast_target_id",
  { data_type => "integer", is_nullable => 1 },
  "n_hits",
  { data_type => "integer", is_nullable => 1 },
  "hits_stored",
  { data_type => "integer", is_nullable => 1 },
  "last_updated",
  { data_type => "integer", is_nullable => 1 },
  "host",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "pid",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("blast_annotation_id");
__PACKAGE__->add_unique_constraint(
  "blast_annotations_apply_id_blast_target_id_uq",
  ["apply_id", "blast_target_id"],
);

=head1 RELATIONS

=head2 apply

Type: belongs_to

Related object: L<SGN::Schema::Unigene>

=cut

__PACKAGE__->belongs_to(
  "apply",
  "SGN::Schema::Unigene",
  { unigene_id => "apply_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 blast_hits

Type: has_many

Related object: L<SGN::Schema::BlastHit>

=cut

__PACKAGE__->has_many(
  "blast_hits",
  "SGN::Schema::BlastHit",
  { "foreign.blast_annotation_id" => "self.blast_annotation_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:43aWHj56ncTWYbyZmIAs4Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
