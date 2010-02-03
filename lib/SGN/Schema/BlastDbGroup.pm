package SGN::Schema::BlastDbGroup;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("blast_db_group");
__PACKAGE__->add_columns(
  "blast_db_group_id",
  {
    data_type => "integer",
    default_value => "nextval('blast_db_group_blast_db_group_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 50,
  },
  "ordinal",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("blast_db_group_id");
__PACKAGE__->has_many(
  "blast_dbs",
  "SGN::Schema::BlastDb",
  { "foreign.blast_db_group_id" => "self.blast_db_group_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6C3I38meStK8O5wEoU2A9A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
