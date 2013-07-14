
package SGN::Schema::BlastDbBlastDbGroup;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("blast_db_blast_db_group");

__PACKAGE__->add_columns( 
    "blast_db_blast_db_group_id",
    {
	data_type         => "integer",
	is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "blast_db_blast_db_group_blast_db_blast_db_group_id_seq"
    },
    "blast_db_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
    "blast_db_blast_db_group_id",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },

    );

__PACKAGE__->set_primary_key("blast_db_blast_db_group_id");

__PACKAGE__->belongs_to(
  "blast_db",
  "SGN::Schema::BlastDb",
  { blast_db_id => "blast_db_id" },
  {
      #is_deferrable => 1,
    join_type     => "LEFT",
  },
);

__PACKAGE__->belongs_to(
    "blast_db_group",
    "SGN::Schema::BlastDbGroup",
    { blast_db_group_id => "blast_db_group_id" },
    { is_deferrable => 1,
      join_type     => "LEFT",
    },
    );

1;
