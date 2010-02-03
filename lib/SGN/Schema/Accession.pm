package SGN::Schema::Accession;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("accession");
__PACKAGE__->add_columns(
  "accession_id",
  {
    data_type => "integer",
    default_value => "nextval('accession_accession_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "organism_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "common_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "accession_name_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("accession_id");
__PACKAGE__->add_unique_constraint("unique_accession_name", ["accession_name_id"]);
__PACKAGE__->belongs_to(
  "organism",
  "SGN::Schema::Organism",
  { organism_id => "organism_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "accession_name",
  "SGN::Schema::AccessionName",
  { accession_name_id => "accession_name_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->has_many(
  "accession_names",
  "SGN::Schema::AccessionName",
  { "foreign.accession_id" => "self.accession_id" },
);
__PACKAGE__->has_many(
  "map_ancestors",
  "SGN::Schema::Map",
  { "foreign.ancestor" => "self.accession_id" },
);
__PACKAGE__->has_many(
  "map_parent_2s",
  "SGN::Schema::Map",
  { "foreign.parent_2" => "self.accession_id" },
);
__PACKAGE__->has_many(
  "map_parent_1s",
  "SGN::Schema::Map",
  { "foreign.parent_1" => "self.accession_id" },
);
__PACKAGE__->has_many(
  "pcr_exp_accessions",
  "SGN::Schema::PcrExpAccession",
  { "foreign.accession_id" => "self.accession_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PpupFuImZrTs71w3q/kLvw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
