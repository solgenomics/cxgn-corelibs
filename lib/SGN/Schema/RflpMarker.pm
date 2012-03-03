package SGN::Schema::RflpMarker;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::RflpMarker

=cut

__PACKAGE__->table("rflp_markers");

=head1 ACCESSORS

=head2 rflp_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'rflp_markers_rflp_id_seq'

=head2 marker_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 rflp_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 64

=head2 library_name

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 clone_name

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 vector

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 cutting_site

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 forward_seq_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 reverse_seq_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 insert_size

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=head2 drug_resistance

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 marker_prefix

  data_type: 'varchar'
  is_nullable: 1
  size: 8

=head2 marker_suffix

  data_type: 'smallint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "rflp_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "rflp_markers_rflp_id_seq",
  },
  "marker_id",
  {
    data_type      => "bigint",
    default_value  => "0)::bigint",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "rflp_name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 64 },
  "library_name",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "clone_name",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "vector",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "cutting_site",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "forward_seq_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "reverse_seq_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "insert_size",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "drug_resistance",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "marker_prefix",
  { data_type => "varchar", is_nullable => 1, size => 8 },
  "marker_suffix",
  { data_type => "smallint", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("rflp_id");

=head1 RELATIONS

=head2 marker_experiments

Type: has_many

Related object: L<SGN::Schema::MarkerExperiment>

=cut

__PACKAGE__->has_many(
  "marker_experiments",
  "SGN::Schema::MarkerExperiment",
  { "foreign.rflp_experiment_id" => "self.rflp_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 reverse_seq

Type: belongs_to

Related object: L<SGN::Schema::RflpSequence>

=cut

__PACKAGE__->belongs_to(
  "reverse_seq",
  "SGN::Schema::RflpSequence",
  { seq_id => "reverse_seq_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
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

=head2 forward_seq

Type: belongs_to

Related object: L<SGN::Schema::RflpSequence>

=cut

__PACKAGE__->belongs_to(
  "forward_seq",
  "SGN::Schema::RflpSequence",
  { seq_id => "forward_seq_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wLUUV2wuSGLIcP3pr3Gbbw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
