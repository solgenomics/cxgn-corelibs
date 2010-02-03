package SGN::Schema::CloningVector;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("cloning_vector");
__PACKAGE__->add_columns(
  "cloning_vector_id",
  {
    data_type => "integer",
    default_value => "nextval('cloning_vector_cloning_vector_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "seq",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("cloning_vector_id");
__PACKAGE__->add_unique_constraint("cloning_vector_name_key", ["name"]);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mqLP8zODA7uf+yrH8uAiKA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
