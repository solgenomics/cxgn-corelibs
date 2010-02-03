package SGN::Schema::Taxonomy;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("taxonomy");
__PACKAGE__->add_columns(
  "tax_id",
  {
    data_type => "integer",
    default_value => "nextval('taxonomy_tax_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "tax_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 50,
  },
  "tax_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
);
__PACKAGE__->set_primary_key("tax_id");
__PACKAGE__->has_many(
  "organism_order_taxes",
  "SGN::Schema::Organism",
  { "foreign.order_tax" => "self.tax_id" },
);
__PACKAGE__->has_many(
  "organism_family_taxes",
  "SGN::Schema::Organism",
  { "foreign.family_tax" => "self.tax_id" },
);
__PACKAGE__->has_many(
  "organism_genus_taxes",
  "SGN::Schema::Organism",
  { "foreign.genus_tax" => "self.tax_id" },
);
__PACKAGE__->has_many(
  "organism_subfamily_taxes",
  "SGN::Schema::Organism",
  { "foreign.subfamily_tax" => "self.tax_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wKYjK6ac5YuoHDMfyWHi7w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
