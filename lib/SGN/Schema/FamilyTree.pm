package SGN::Schema::FamilyTree;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::FamilyTree

=cut

__PACKAGE__->table("family_tree");

=head1 ACCESSORS

=head2 family_tree_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'family_tree_family_tree_id_seq'

=head2 family_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 tree_nr

  data_type: 'integer'
  is_nullable: 1

=head2 newick_cds

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 newick_unigene

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "family_tree_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "family_tree_family_tree_id_seq",
  },
  "family_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "tree_nr",
  { data_type => "integer", is_nullable => 1 },
  "newick_cds",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "newick_unigene",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
);
__PACKAGE__->set_primary_key("family_tree_id");

=head1 RELATIONS

=head2 family

Type: belongs_to

Related object: L<SGN::Schema::Family>

=cut

__PACKAGE__->belongs_to(
  "family",
  "SGN::Schema::Family",
  { family_id => "family_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:olyNyjmYqt3GuL+Ry+I+qg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
