package SGN::Schema::CosMarker;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::CosMarker

=cut

__PACKAGE__->table("cos_markers");

=head1 ACCESSORS

=head2 cos_marker_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cos_markers_cos_marker_id_seq'

=head2 marker_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 est_read_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=head2 cos_id

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 10

=head2 at_match

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 bac_id

  data_type: 'bigint'
  is_nullable: 1

=head2 at_position

  data_type: 'numeric'
  is_nullable: 1
  size: [11,7]

=head2 best_gb_prot_hit

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 at_evalue

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 at_identities

  data_type: 'numeric'
  is_nullable: 1
  size: [11,3]

=head2 mips_cat

  data_type: 'varchar'
  is_nullable: 1
  size: 11

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 tomato_copy_number

  data_type: 'varchar'
  is_nullable: 1
  size: 11

=head2 gbprot_evalue

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 gbprot_identities

  data_type: 'numeric'
  is_nullable: 1
  size: [11,3]

=cut

__PACKAGE__->add_columns(
  "cos_marker_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cos_markers_cos_marker_id_seq",
  },
  "marker_id",
  {
    data_type      => "bigint",
    default_value  => "0)::bigint",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "est_read_id",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "cos_id",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 10 },
  "at_match",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "bac_id",
  { data_type => "bigint", is_nullable => 1 },
  "at_position",
  { data_type => "numeric", is_nullable => 1, size => [11, 7] },
  "best_gb_prot_hit",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "at_evalue",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "at_identities",
  { data_type => "numeric", is_nullable => 1, size => [11, 3] },
  "mips_cat",
  { data_type => "varchar", is_nullable => 1, size => 11 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "tomato_copy_number",
  { data_type => "varchar", is_nullable => 1, size => 11 },
  "gbprot_evalue",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "gbprot_identities",
  { data_type => "numeric", is_nullable => 1, size => [11, 3] },
);
__PACKAGE__->set_primary_key("cos_marker_id");

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


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:L36UiM4d0cDlEEISeWAGhQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
