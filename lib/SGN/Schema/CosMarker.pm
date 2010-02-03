package SGN::Schema::CosMarker;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("cos_markers");
__PACKAGE__->add_columns(
  "cos_marker_id",
  {
    data_type => "integer",
    default_value => "nextval('cos_markers_cos_marker_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "marker_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 8,
  },
  "est_read_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "cos_id",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 10,
  },
  "at_match",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "bac_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "at_position",
  {
    data_type => "numeric",
    default_value => undef,
    is_nullable => 1,
    size => "7,11",
  },
  "best_gb_prot_hit",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "at_evalue",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "at_identities",
  {
    data_type => "numeric",
    default_value => undef,
    is_nullable => 1,
    size => "3,11",
  },
  "mips_cat",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 11,
  },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "comment",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "tomato_copy_number",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 11,
  },
  "gbprot_evalue",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "gbprot_identities",
  {
    data_type => "numeric",
    default_value => undef,
    is_nullable => 1,
    size => "3,11",
  },
);
__PACKAGE__->set_primary_key("cos_marker_id");
__PACKAGE__->belongs_to("marker", "SGN::Schema::Marker", { marker_id => "marker_id" });


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:y6I+pZU5VatEMooJfHOFHw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
