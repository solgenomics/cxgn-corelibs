package SGN::Schema::RflpUnigeneAssociation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::RflpUnigeneAssociation

=cut

__PACKAGE__->table("rflp_unigene_associations");

=head1 ACCESSORS

=head2 rflp_unigene_assoc_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'rflp_unigene_associations_rflp_unigene_assoc_id_seq'

=head2 rflp_seq_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 unigene_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 e_val

  data_type: 'double precision'
  is_nullable: 1

=head2 align_length

  data_type: 'bigint'
  is_nullable: 1

=head2 query_start

  data_type: 'bigint'
  is_nullable: 1

=head2 query_end

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "rflp_unigene_assoc_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "rflp_unigene_associations_rflp_unigene_assoc_id_seq",
  },
  "rflp_seq_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "unigene_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "e_val",
  { data_type => "double precision", is_nullable => 1 },
  "align_length",
  { data_type => "bigint", is_nullable => 1 },
  "query_start",
  { data_type => "bigint", is_nullable => 1 },
  "query_end",
  { data_type => "bigint", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("rflp_unigene_assoc_id");

=head1 RELATIONS

=head2 unigene

Type: belongs_to

Related object: L<SGN::Schema::Unigene>

=cut

__PACKAGE__->belongs_to(
  "unigene",
  "SGN::Schema::Unigene",
  { unigene_id => "unigene_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 rflp_seq

Type: belongs_to

Related object: L<SGN::Schema::RflpSequence>

=cut

__PACKAGE__->belongs_to(
  "rflp_seq",
  "SGN::Schema::RflpSequence",
  { seq_id => "rflp_seq_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8HiLrErnVTkuUbndvyRZ9g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
