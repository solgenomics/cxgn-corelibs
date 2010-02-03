package SGN::Schema::FamilyTree;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("family_tree");
__PACKAGE__->add_columns(
  "family_tree_id",
  {
    data_type => "integer",
    default_value => "nextval('family_tree_family_tree_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "family_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "tree_nr",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "newick_cds",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "newick_unigene",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("family_tree_id");
__PACKAGE__->belongs_to("family", "SGN::Schema::Family", { family_id => "family_id" });


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:96Pb3uKjjqxmmtCCzval2Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
