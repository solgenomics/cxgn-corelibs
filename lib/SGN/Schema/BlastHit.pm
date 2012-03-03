package SGN::Schema::BlastHit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::BlastHit

=cut

__PACKAGE__->table("blast_hits");

=head1 ACCESSORS

=head2 blast_hit_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'blast_hits_blast_hit_id_seq'

=head2 blast_annotation_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 target_db_id

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 evalue

  data_type: 'double precision'
  is_nullable: 1

=head2 score

  data_type: 'double precision'
  is_nullable: 1

=head2 identity_percentage

  data_type: 'double precision'
  is_nullable: 1

=head2 apply_start

  data_type: 'bigint'
  is_nullable: 1

=head2 apply_end

  data_type: 'bigint'
  is_nullable: 1

=head2 defline_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "blast_hit_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "blast_hits_blast_hit_id_seq",
  },
  "blast_annotation_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "target_db_id",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "evalue",
  { data_type => "double precision", is_nullable => 1 },
  "score",
  { data_type => "double precision", is_nullable => 1 },
  "identity_percentage",
  { data_type => "double precision", is_nullable => 1 },
  "apply_start",
  { data_type => "bigint", is_nullable => 1 },
  "apply_end",
  { data_type => "bigint", is_nullable => 1 },
  "defline_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("blast_hit_id");

=head1 RELATIONS

=head2 blast_annotation

Type: belongs_to

Related object: L<SGN::Schema::BlastAnnotation>

=cut

__PACKAGE__->belongs_to(
  "blast_annotation",
  "SGN::Schema::BlastAnnotation",
  { blast_annotation_id => "blast_annotation_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oIds6hCNHjaKMqpIqLeoAQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
