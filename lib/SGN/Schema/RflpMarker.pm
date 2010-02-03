package SGN::Schema::RflpMarker;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("rflp_markers");
__PACKAGE__->add_columns(
  "rflp_id",
  {
    data_type => "integer",
    default_value => "nextval('rflp_markers_rflp_id_seq'::regclass)",
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
  "rflp_name",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 64,
  },
  "library_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 64,
  },
  "clone_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 16,
  },
  "vector",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "cutting_site",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "forward_seq_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "reverse_seq_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "insert_size",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "drug_resistance",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 16,
  },
  "marker_prefix",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "marker_suffix",
  {
    data_type => "smallint",
    default_value => undef,
    is_nullable => 1,
    size => 2,
  },
);
__PACKAGE__->set_primary_key("rflp_id");
__PACKAGE__->has_many(
  "marker_experiments",
  "SGN::Schema::MarkerExperiment",
  { "foreign.rflp_experiment_id" => "self.rflp_id" },
);
__PACKAGE__->belongs_to(
  "reverse_seq",
  "SGN::Schema::RflpSequence",
  { seq_id => "reverse_seq_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to("marker", "SGN::Schema::Marker", { marker_id => "marker_id" });
__PACKAGE__->belongs_to(
  "forward_seq",
  "SGN::Schema::RflpSequence",
  { seq_id => "forward_seq_id" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JxKKWqpAeSVS1J43w+eieA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
