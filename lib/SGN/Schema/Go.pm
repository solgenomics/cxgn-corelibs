package SGN::Schema::Go;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("go");
__PACKAGE__->add_columns(
  "go_id",
  {
    data_type => "bigint",
    default_value => "nextval('go_go_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "go_accession",
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
__PACKAGE__->set_primary_key("go_id");
__PACKAGE__->add_unique_constraint("go_go_accession_key", ["go_accession"]);
__PACKAGE__->has_many(
  "interpro_goes",
  "SGN::Schema::InterproGo",
  { "foreign.go_accession" => "self.go_accession" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oO8KY9cre9CuhJK8J/FkWA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
