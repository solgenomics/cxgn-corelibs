package SGN::Schema::Organism;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("organism");
__PACKAGE__->add_columns(
  "organism_id",
  {
    data_type => "integer",
    default_value => "nextval('organism_organism_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "organism_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "common_name_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 8,
  },
  "organism_descrip",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "specie_tax",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "genus_tax",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "subfamily_tax",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "family_tax",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "order_tax",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "chr_n_gnmc",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "polypl_gnmc",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "genom_size_gnmc",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "genom_proj_gnmc",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "est_attribution_tqmc",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("organism_id");
__PACKAGE__->add_unique_constraint("unique_organism_name", ["organism_name"]);
__PACKAGE__->has_many(
  "accessions",
  "SGN::Schema::Accession",
  { "foreign.organism_id" => "self.organism_id" },
);
__PACKAGE__->has_many(
  "deprecated_map_crosses",
  "SGN::Schema::DeprecatedMapCross",
  { "foreign.organism_id" => "self.organism_id" },
);
__PACKAGE__->belongs_to(
  "order_tax",
  "SGN::Schema::Taxonomy",
  { tax_id => "order_tax" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "family_tax",
  "SGN::Schema::Taxonomy",
  { tax_id => "family_tax" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "genus_tax",
  "SGN::Schema::Taxonomy",
  { tax_id => "genus_tax" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "subfamily_tax",
  "SGN::Schema::Taxonomy",
  { tax_id => "subfamily_tax" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "common_name",
  "SGN::Schema::CommonName",
  { common_name_id => "common_name_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hIsxt1nQ/SSj6bkmAl7lzg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
