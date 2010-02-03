package SGN::Schema::Metadata;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("metadata");
__PACKAGE__->add_columns(
  "metadata_id",
  {
    data_type => "bigint",
    default_value => "nextval('metadata_metadata_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "create_date",
  {
    data_type => "timestamp with time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "create_person_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "modified_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "modified_person_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "previous_metadata_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "obsolete",
  { data_type => "integer", default_value => 0, is_nullable => 1, size => 4 },
  "obsolete_note",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
);
__PACKAGE__->set_primary_key("metadata_id");
__PACKAGE__->has_many(
  "domains",
  "SGN::Schema::Domain",
  { "foreign.metadata_id" => "self.metadata_id" },
);
__PACKAGE__->has_many(
  "domain_matches",
  "SGN::Schema::DomainMatch",
  { "foreign.metadata_id" => "self.metadata_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4TPwTAwr+QSPbKsSYw2VDQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
