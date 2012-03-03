package SGN::Schema::CosiiOrtholog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::CosiiOrtholog

=cut

__PACKAGE__->table("cosii_ortholog");

=head1 ACCESSORS

=head2 cosii_unigene_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cosii_ortholog_cosii_unigene_id_seq'

=head2 marker_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 unigene_id

  data_type: 'integer'
  is_nullable: 1

=head2 copies

  data_type: 'varchar'
  is_nullable: 1
  size: 1

=head2 database_name

  data_type: 'varchar'
  is_nullable: 1
  size: 11

=head2 sequence_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 edited_sequence_id

  data_type: 'bigint'
  is_nullable: 1

=head2 peptide_sequence_id

  data_type: 'bigint'
  is_nullable: 1

=head2 introns

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cosii_unigene_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cosii_ortholog_cosii_unigene_id_seq",
  },
  "marker_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "unigene_id",
  { data_type => "integer", is_nullable => 1 },
  "copies",
  { data_type => "varchar", is_nullable => 1, size => 1 },
  "database_name",
  { data_type => "varchar", is_nullable => 1, size => 11 },
  "sequence_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "edited_sequence_id",
  { data_type => "bigint", is_nullable => 1 },
  "peptide_sequence_id",
  { data_type => "bigint", is_nullable => 1 },
  "introns",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("cosii_unigene_id");

=head1 RELATIONS

=head2 marker

Type: belongs_to

Related object: L<SGN::Schema::Marker>

=cut

__PACKAGE__->belongs_to(
  "marker",
  "SGN::Schema::Marker",
  { marker_id => "marker_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5E/wH8hjHQqk3rLvGjTuCA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
