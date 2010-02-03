package SGN::Schema::PcrProduct;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("pcr_product");
__PACKAGE__->add_columns(
  "pcr_product_id",
  {
    data_type => "bigint",
    default_value => "nextval('pcr_product_pcr_product_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "pcr_exp_accession_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "enzyme_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "multiple_flag",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "band_size",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "predicted",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
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
__PACKAGE__->belongs_to(
  "enzyme",
  "SGN::Schema::Enzyme",
  { enzyme_id => "enzyme_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "pcr_exp_accession",
  "SGN::Schema::PcrExpAccession",
  { pcr_exp_accession_id => "pcr_exp_accession_id" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yoyMxXvBqSBDOlALFXab2A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
