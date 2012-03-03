package SGN::Schema::Snp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Snp

=cut

__PACKAGE__->table("snp");

=head1 ACCESSORS

=head2 snp_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn.snp_snp_id_seq'

=head2 marker_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 reference_nucleotide

  data_type: 'varchar'
  is_nullable: 1
  size: 4

=head2 snp_nucleotide

  data_type: 'varchar'
  is_nullable: 0
  size: 4

=head2 confirmed

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 sequence_left_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 sequence_right_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 reference_stock_id

  data_type: 'integer'
  is_nullable: 1

=head2 stock_id

  data_type: 'integer'
  is_nullable: 0

=head2 metadata_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "snp_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn.snp_snp_id_seq",
  },
  "marker_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "reference_nucleotide",
  { data_type => "varchar", is_nullable => 1, size => 4 },
  "snp_nucleotide",
  { data_type => "varchar", is_nullable => 0, size => 4 },
  "confirmed",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "sequence_left_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "sequence_right_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "reference_stock_id",
  { data_type => "integer", is_nullable => 1 },
  "stock_id",
  { data_type => "integer", is_nullable => 0 },
  "metadata_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("snp_id");

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

=head2 sequence_right

Type: belongs_to

Related object: L<SGN::Schema::Sequence>

=cut

__PACKAGE__->belongs_to(
  "sequence_right",
  "SGN::Schema::Sequence",
  { sequence_id => "sequence_right_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 sequence_left

Type: belongs_to

Related object: L<SGN::Schema::Sequence>

=cut

__PACKAGE__->belongs_to(
  "sequence_left",
  "SGN::Schema::Sequence",
  { sequence_id => "sequence_left_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 snp_files

Type: has_many

Related object: L<SGN::Schema::SnpFile>

=cut

__PACKAGE__->has_many(
  "snp_files",
  "SGN::Schema::SnpFile",
  { "foreign.snp_id" => "self.snp_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 snpprops

Type: has_many

Related object: L<SGN::Schema::Snpprop>

=cut

__PACKAGE__->has_many(
  "snpprops",
  "SGN::Schema::Snpprop",
  { "foreign.snp_id" => "self.snp_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wfxYe/YDtWLO0p2PSd+akw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
