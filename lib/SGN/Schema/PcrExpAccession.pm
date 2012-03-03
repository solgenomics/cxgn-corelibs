package SGN::Schema::PcrExpAccession;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::PcrExpAccession

=cut

__PACKAGE__->table("pcr_exp_accession");

=head1 ACCESSORS

=head2 pcr_exp_accession_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'pcr_exp_accession_pcr_exp_accession_id_seq'

=head2 pcr_experiment_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 accession_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 stock_id

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "pcr_exp_accession_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "pcr_exp_accession_pcr_exp_accession_id_seq",
  },
  "pcr_experiment_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "accession_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "stock_id",
  { data_type => "bigint", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("pcr_exp_accession_id");

=head1 RELATIONS

=head2 accession

Type: belongs_to

Related object: L<SGN::Schema::Accession>

=cut

__PACKAGE__->belongs_to(
  "accession",
  "SGN::Schema::Accession",
  { accession_id => "accession_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 pcr_experiment

Type: belongs_to

Related object: L<SGN::Schema::PcrExperiment>

=cut

__PACKAGE__->belongs_to(
  "pcr_experiment",
  "SGN::Schema::PcrExperiment",
  { pcr_experiment_id => "pcr_experiment_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 pcr_products

Type: has_many

Related object: L<SGN::Schema::PcrProduct>

=cut

__PACKAGE__->has_many(
  "pcr_products",
  "SGN::Schema::PcrProduct",
  { "foreign.pcr_exp_accession_id" => "self.pcr_exp_accession_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Y3RZikf9JL4YQNNoTtAMuw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
