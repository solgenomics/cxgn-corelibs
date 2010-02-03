package SGN::Schema::InterproGo;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("interpro_go");
__PACKAGE__->add_columns(
  "interpro_go_id",
  {
    data_type => "bigint",
    default_value => "nextval('interpro_go_interpro_go_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "interpro_accession",
  {
    data_type => "character varying",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 20,
  },
  "go_accession",
  {
    data_type => "character varying",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 20,
  },
);
__PACKAGE__->set_primary_key("interpro_go_id");
__PACKAGE__->belongs_to(
  "go_accession",
  "SGN::Schema::Go",
  { go_accession => "go_accession" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "interpro_accession",
  "SGN::Schema::Interpro",
  { interpro_accession => "interpro_accession" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DY8Jg7Fa9DNO0wrdyZ6MGw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
