package SGN::Schema::DomainMatch;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("domain_match");
__PACKAGE__->add_columns(
  "domain_match_id",
  {
    data_type => "bigint",
    default_value => "nextval('domain_match_domain_match_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "cds_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "unigene_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "domain_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "match_begin",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "match_end",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "e_value",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 10,
  },
  "hit_status",
  {
    data_type => "character",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
  "run_id",
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
__PACKAGE__->set_primary_key("domain_match_id");
__PACKAGE__->belongs_to(
  "metadata",
  "SGN::Schema::Metadata",
  { metadata_id => "metadata_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "domain",
  "SGN::Schema::Domain",
  { domain_id => "domain_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "cd",
  "SGN::Schema::Cd",
  { cds_id => "cds_id" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LknuRUb+6qXkKJRrgEi5bg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
