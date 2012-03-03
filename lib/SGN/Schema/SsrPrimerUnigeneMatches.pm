package SGN::Schema::SsrPrimerUnigeneMatches;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::SsrPrimerUnigeneMatches

=cut

__PACKAGE__->table("ssr_primer_unigene_matches");

=head1 ACCESSORS

=head2 ssr_primer_unigene_match_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'ssr_primer_unigene_matches_ssr_primer_unigene_match_id_seq'

=head2 ssr_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 unigene_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 primer_direction

  data_type: 'smallint'
  default_value: '0)::smallint'
  is_nullable: 0

=head2 match_length

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=head2 primer_match_start

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=head2 primer_match_end

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=head2 unigene_match_start

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=head2 unigene_match_end

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=head2 e_value

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "ssr_primer_unigene_match_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "ssr_primer_unigene_matches_ssr_primer_unigene_match_id_seq",
  },
  "ssr_id",
  {
    data_type      => "bigint",
    default_value  => "0)::bigint",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "unigene_id",
  {
    data_type      => "bigint",
    default_value  => "0)::bigint",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "primer_direction",
  {
    data_type     => "smallint",
    default_value => "0)::smallint",
    is_nullable   => 0,
  },
  "match_length",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "primer_match_start",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "primer_match_end",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "unigene_match_start",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "unigene_match_end",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "e_value",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("ssr_primer_unigene_match_id");

=head1 RELATIONS

=head2 ssr

Type: belongs_to

Related object: L<SGN::Schema::Ssr>

=cut

__PACKAGE__->belongs_to(
  "ssr",
  "SGN::Schema::Ssr",
  { ssr_id => "ssr_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 unigene

Type: belongs_to

Related object: L<SGN::Schema::Unigene>

=cut

__PACKAGE__->belongs_to(
  "unigene",
  "SGN::Schema::Unigene",
  { unigene_id => "unigene_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eoWeR7fnqTULb9byE5+LHQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
