package SGN::Schema::CloningVector;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::CloningVector

=cut

__PACKAGE__->table("cloning_vector");

=head1 ACCESSORS

=head2 cloning_vector_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cloning_vector_cloning_vector_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 seq

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cloning_vector_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cloning_vector_cloning_vector_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "seq",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("cloning_vector_id");
__PACKAGE__->add_unique_constraint("cloning_vector_name_key", ["name"]);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YrZRLoEggB+pEDvYt5XrSQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
