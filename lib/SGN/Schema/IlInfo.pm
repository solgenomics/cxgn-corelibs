package SGN::Schema::IlInfo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::IlInfo

=cut

__PACKAGE__->table("il_info");

=head1 ACCESSORS

=head2 ns_marker_id

  data_type: 'integer'
  is_nullable: 1

=head2 sn_marker_id

  data_type: 'integer'
  is_nullable: 1

=head2 map_id

  data_type: 'integer'
  is_nullable: 1

=head2 map_version_id

  data_type: 'integer'
  is_nullable: 1

=head2 population_id

  data_type: 'bigint'
  is_nullable: 1

=head2 ns_position

  data_type: 'numeric'
  is_nullable: 1
  size: [8,5]

=head2 sn_position

  data_type: 'numeric'
  is_nullable: 1
  size: [8,5]

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 ns_alias

  data_type: 'text'
  is_nullable: 1

=head2 sn_alias

  data_type: 'text'
  is_nullable: 1

=head2 lg_name

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "ns_marker_id",
  { data_type => "integer", is_nullable => 1 },
  "sn_marker_id",
  { data_type => "integer", is_nullable => 1 },
  "map_id",
  { data_type => "integer", is_nullable => 1 },
  "map_version_id",
  { data_type => "integer", is_nullable => 1 },
  "population_id",
  { data_type => "bigint", is_nullable => 1 },
  "ns_position",
  { data_type => "numeric", is_nullable => 1, size => [8, 5] },
  "sn_position",
  { data_type => "numeric", is_nullable => 1, size => [8, 5] },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "ns_alias",
  { data_type => "text", is_nullable => 1 },
  "sn_alias",
  { data_type => "text", is_nullable => 1 },
  "lg_name",
  { data_type => "text", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bolPyJfTePfg3/kyvYUg/g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
