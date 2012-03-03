package SGN::Schema::Misc;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Misc

=cut

__PACKAGE__->table("misc");

=head1 ACCESSORS

=head2 misc_unique_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'misc_misc_unique_id_seq'

=head2 misc_id

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 value

  data_type: 'bytea'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "misc_unique_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "misc_misc_unique_id_seq",
  },
  "misc_id",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "value",
  { data_type => "bytea", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("misc_unique_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oYvzANrnfJnxudkR0KNN6g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
