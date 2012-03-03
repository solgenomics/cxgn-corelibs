package SGN::Schema::LocType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::LocType

=cut

__PACKAGE__->table("loc_types");

=head1 ACCESSORS

=head2 loc_type_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'loc_types_loc_type_id_seq'

=head2 type_code

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 10

=head2 type_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 12

=cut

__PACKAGE__->add_columns(
  "loc_type_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "loc_types_loc_type_id_seq",
  },
  "type_code",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 10 },
  "type_name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 12 },
);
__PACKAGE__->set_primary_key("loc_type_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:n2Sy/U9Sb8EDwZZ1HUnpPg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
