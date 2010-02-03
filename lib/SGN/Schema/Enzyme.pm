package SGN::Schema::Enzyme;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("enzymes");
__PACKAGE__->add_columns(
  "enzyme_id",
  {
    data_type => "integer",
    default_value => "nextval('enzymes_enzyme_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "enzyme_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
);
__PACKAGE__->set_primary_key("enzyme_id");
__PACKAGE__->add_unique_constraint("enzymes_enzyme_name_key", ["enzyme_name"]);
__PACKAGE__->has_many(
  "pcr_products",
  "SGN::Schema::PcrProduct",
  { "foreign.enzyme_id" => "self.enzyme_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JeQmHKNgqLPrUL0vYl0gRQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
