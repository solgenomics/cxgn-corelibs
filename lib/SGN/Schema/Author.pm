package SGN::Schema::Author;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Author

=cut

__PACKAGE__->table("authors");

=head1 ACCESSORS

=head2 author_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'authors_author_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 institution

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "author_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "authors_author_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 1 },
  "institution",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("author_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fA2/6P0m0s2ItG4IkmiJ9g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
