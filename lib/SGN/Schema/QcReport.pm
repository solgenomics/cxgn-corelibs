package SGN::Schema::QcReport;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::QcReport

=cut

__PACKAGE__->table("qc_report");

=head1 ACCESSORS

=head2 qc_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'qc_report_qc_id_seq'

=head2 est_id

  data_type: 'integer'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0

=head2 basecaller

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 qc_status

  data_type: 'bigint'
  is_nullable: 1

=head2 vs_status

  data_type: 'bigint'
  is_nullable: 1

=head2 qstart

  data_type: 'bigint'
  is_nullable: 1

=head2 qend

  data_type: 'bigint'
  is_nullable: 1

=head2 istart

  data_type: 'bigint'
  is_nullable: 1

=head2 iend

  data_type: 'bigint'
  is_nullable: 1

=head2 hqi_start

  data_type: 'bigint'
  is_nullable: 1

=head2 hqi_length

  data_type: 'bigint'
  is_nullable: 1

=head2 entropy

  data_type: 'real'
  is_nullable: 1

=head2 expected_error

  data_type: 'real'
  is_nullable: 1

=head2 quality_trim_threshold

  data_type: 'real'
  is_nullable: 1

=head2 vector_tokens

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "qc_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "qc_report_qc_id_seq",
  },
  "est_id",
  {
    data_type      => "integer",
    default_value  => 0,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "basecaller",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "qc_status",
  { data_type => "bigint", is_nullable => 1 },
  "vs_status",
  { data_type => "bigint", is_nullable => 1 },
  "qstart",
  { data_type => "bigint", is_nullable => 1 },
  "qend",
  { data_type => "bigint", is_nullable => 1 },
  "istart",
  { data_type => "bigint", is_nullable => 1 },
  "iend",
  { data_type => "bigint", is_nullable => 1 },
  "hqi_start",
  { data_type => "bigint", is_nullable => 1 },
  "hqi_length",
  { data_type => "bigint", is_nullable => 1 },
  "entropy",
  { data_type => "real", is_nullable => 1 },
  "expected_error",
  { data_type => "real", is_nullable => 1 },
  "quality_trim_threshold",
  { data_type => "real", is_nullable => 1 },
  "vector_tokens",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("qc_id");
__PACKAGE__->add_unique_constraint("qc_report_est_id_key", ["est_id"]);

=head1 RELATIONS

=head2 est

Type: belongs_to

Related object: L<SGN::Schema::Est>

=cut

__PACKAGE__->belongs_to(
  "est",
  "SGN::Schema::Est",
  { est_id => "est_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qGjD3Odu3GmEF6yX4Kcsww


# You can replace this text with custom content, and it will be preserved on regeneration
1;
