package SGN::Schema::PcrProduct;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::PcrProduct

=cut

__PACKAGE__->table("pcr_product");

=head1 ACCESSORS

=head2 pcr_product_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'pcr_product_pcr_product_id_seq'

=head2 pcr_exp_accession_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 enzyme_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 multiple_flag

  data_type: 'bigint'
  is_nullable: 1

=head2 band_size

  data_type: 'bigint'
  is_nullable: 1

=head2 predicted

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "pcr_product_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "pcr_product_pcr_product_id_seq",
  },
  "pcr_exp_accession_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "enzyme_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "multiple_flag",
  { data_type => "bigint", is_nullable => 1 },
  "band_size",
  { data_type => "bigint", is_nullable => 1 },
  "predicted",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("pcr_product_id");
__PACKAGE__->add_unique_constraint(
  "unique_acc_enz_mult_pred_size",
  [
    "pcr_exp_accession_id",
    "enzyme_id",
    "multiple_flag",
    "band_size",
    "predicted",
  ],
);

=head1 RELATIONS

=head2 enzyme

Type: belongs_to

Related object: L<SGN::Schema::Enzyme>

=cut

__PACKAGE__->belongs_to(
  "enzyme",
  "SGN::Schema::Enzyme",
  { enzyme_id => "enzyme_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 pcr_exp_accession

Type: belongs_to

Related object: L<SGN::Schema::PcrExpAccession>

=cut

__PACKAGE__->belongs_to(
  "pcr_exp_accession",
  "SGN::Schema::PcrExpAccession",
  { pcr_exp_accession_id => "pcr_exp_accession_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0+jPJ6tov5a43+Pnryom0Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
