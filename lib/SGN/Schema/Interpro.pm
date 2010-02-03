package SGN::Schema::Interpro;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("interpro");
__PACKAGE__->add_columns(
  "interpro_id",
  {
    data_type => "bigint",
    default_value => "nextval('interpro_interpro_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "interpro_accession",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "description_fulltext",
  {
    data_type => "tsvector",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("interpro_id");
__PACKAGE__->add_unique_constraint("interpro_interpro_accession_key", ["interpro_accession"]);
__PACKAGE__->has_many(
  "interpro_goes",
  "SGN::Schema::InterproGo",
  { "foreign.interpro_accession" => "self.interpro_accession" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eOKpm49x0BGacxaavYLf2Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
