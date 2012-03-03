package SGN::Schema::Type;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Type

=cut

__PACKAGE__->table("types");

=head1 ACCESSORS

=head2 type_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'types_type_id_seq'

=head2 comment

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "type_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "types_type_id_seq",
  },
  "comment",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("type_id");

=head1 RELATIONS

=head2 libraries

Type: has_many

Related object: L<SGN::Schema::Library>

=cut

__PACKAGE__->has_many(
  "libraries",
  "SGN::Schema::Library",
  { "foreign.type" => "self.type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U/OEq1RKwfw2+Qb3jx4B9Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
