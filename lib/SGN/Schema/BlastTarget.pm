package SGN::Schema::BlastTarget;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("blast_targets");
__PACKAGE__->add_columns(
  "blast_target_id",
  {
    data_type => "integer",
    default_value => "nextval('blast_targets_blast_target_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "blast_program",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 7,
  },
  "db_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "db_path",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "local_copy_timestamp",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("blast_target_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:J/73wB//mUYLUj1wybSdhw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
