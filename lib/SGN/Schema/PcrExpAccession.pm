package SGN::Schema::PcrExpAccession;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("pcr_exp_accession");
__PACKAGE__->add_columns(
  "pcr_exp_accession_id",
  {
    data_type => "bigint",
    default_value => "nextval('pcr_exp_accession_pcr_exp_accession_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "pcr_experiment_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "accession_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("pcr_exp_accession_id");
__PACKAGE__->belongs_to(
  "accession",
  "SGN::Schema::Accession",
  { accession_id => "accession_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "pcr_experiment",
  "SGN::Schema::PcrExperiment",
  { pcr_experiment_id => "pcr_experiment_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->has_many(
  "pcr_products",
  "SGN::Schema::PcrProduct",
  { "foreign.pcr_exp_accession_id" => "self.pcr_exp_accession_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TDBVF7I+OjYXTIA7nhqBsg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
