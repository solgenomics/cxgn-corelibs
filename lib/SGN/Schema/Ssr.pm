package SGN::Schema::Ssr;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Ssr

=cut

__PACKAGE__->table("ssr");

=head1 ACCESSORS

=head2 ssr_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'ssr_ssr_id_seq'

=head2 marker_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 ssr_name

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 est_read_id

  data_type: 'bigint'
  is_nullable: 1

=head2 start_primer

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 end_primer

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 pcr_product_ln

  data_type: 'bigint'
  is_nullable: 1

=head2 tm_start_primer

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 tm_end_primer

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 ann_high

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 ann_low

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=cut

__PACKAGE__->add_columns(
  "ssr_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "ssr_ssr_id_seq",
  },
  "marker_id",
  {
    data_type      => "bigint",
    default_value  => "0)::bigint",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "ssr_name",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "est_read_id",
  { data_type => "bigint", is_nullable => 1 },
  "start_primer",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "end_primer",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "pcr_product_ln",
  { data_type => "bigint", is_nullable => 1 },
  "tm_start_primer",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "tm_end_primer",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "ann_high",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "ann_low",
  { data_type => "varchar", is_nullable => 1, size => 10 },
);
__PACKAGE__->set_primary_key("ssr_id");

=head1 RELATIONS

=head2 marker

Type: belongs_to

Related object: L<SGN::Schema::Marker>

=cut

__PACKAGE__->belongs_to(
  "marker",
  "SGN::Schema::Marker",
  { marker_id => "marker_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 ssr_primer_unigenes_matches

Type: has_many

Related object: L<SGN::Schema::SsrPrimerUnigeneMatches>

=cut

__PACKAGE__->has_many(
  "ssr_primer_unigenes_matches",
  "SGN::Schema::SsrPrimerUnigeneMatches",
  { "foreign.ssr_id" => "self.ssr_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ssr_repeats

Type: has_many

Related object: L<SGN::Schema::SsrRepeat>

=cut

__PACKAGE__->has_many(
  "ssr_repeats",
  "SGN::Schema::SsrRepeat",
  { "foreign.ssr_id" => "self.ssr_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TflEqlyz1y3SHhPw5I6mAw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
