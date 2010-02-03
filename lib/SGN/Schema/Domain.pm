package SGN::Schema::Domain;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("domain");
__PACKAGE__->add_columns(
  "domain_id",
  {
    data_type => "bigint",
    default_value => "nextval('domain_domain_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "method_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "domain_accession",
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
  "interpro_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "description_fulltext",
  {
    data_type => "tsvector",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "dbxref_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("domain_id");
__PACKAGE__->belongs_to(
  "metadata",
  "SGN::Schema::Metadata",
  { metadata_id => "metadata_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->has_many(
  "domain_matches",
  "SGN::Schema::DomainMatch",
  { "foreign.domain_id" => "self.domain_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:K5I03ILpPrUzILGjyYY77A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
