package SGN::Schema::SsrRepeat;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::SsrRepeat

=cut

__PACKAGE__->table("ssr_repeats");

=head1 ACCESSORS

=head2 repeat_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'ssr_repeats_repeat_id_seq'

=head2 ssr_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 repeat_motif

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 32

=head2 reapeat_nr

  data_type: 'bigint'
  is_nullable: 1

=head2 marker_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "repeat_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "ssr_repeats_repeat_id_seq",
  },
  "ssr_id",
  {
    data_type      => "bigint",
    default_value  => "0)::bigint",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "repeat_motif",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 32 },
  "reapeat_nr",
  { data_type => "bigint", is_nullable => 1 },
  "marker_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("repeat_id");

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


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eqJ7PQCJuJpBf57paZCwMA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
