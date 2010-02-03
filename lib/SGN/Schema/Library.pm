package SGN::Schema::Library;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("library");
__PACKAGE__->add_columns(
  "library_id",
  {
    data_type => "integer",
    default_value => "nextval('library_library_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "type",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "submit_user_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "library_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "library_shortname",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 16,
  },
  "authors",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "organism_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "cultivar",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "accession",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "tissue",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "development_stage",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "treatment_conditions",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "cloning_host",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "vector",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "rs1",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 12,
  },
  "rs2",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 12,
  },
  "cloning_kit",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "comments",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "contact_information",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "order_routing_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "sp_person_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "forward_adapter",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "reverse_adapter",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "obsolete",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
  "modified_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "create_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("library_id");
__PACKAGE__->add_unique_constraint("library_shortname_idx", ["library_shortname"]);
__PACKAGE__->has_many(
  "clones",
  "SGN::Schema::Clone",
  { "foreign.library_id" => "self.library_id" },
);
__PACKAGE__->belongs_to(
  "type",
  "SGN::Schema::Type",
  { type_id => "type" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vuUbthf1WddZqGJ3Vhpz2w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
