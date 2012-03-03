package SGN::Schema::DeprecatedMapCross;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::DeprecatedMapCross

=cut

__PACKAGE__->table("deprecated_map_cross");

=head1 ACCESSORS

=head2 map_cross_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'deprecated_map_cross_map_cross_id_seq'

=head2 map_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 organism_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "map_cross_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "deprecated_map_cross_map_cross_id_seq",
  },
  "map_id",
  {
    data_type      => "bigint",
    default_value  => "0)::bigint",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "organism_id",
  {
    data_type      => "bigint",
    default_value  => "0)::bigint",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);
__PACKAGE__->set_primary_key("map_cross_id");

=head1 RELATIONS

=head2 organism

Type: belongs_to

Related object: L<SGN::Schema::Organism>

=cut

__PACKAGE__->belongs_to(
  "organism",
  "SGN::Schema::Organism",
  { organism_id => "organism_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 map

Type: belongs_to

Related object: L<SGN::Schema::DeprecatedMap>

=cut

__PACKAGE__->belongs_to(
  "map",
  "SGN::Schema::DeprecatedMap",
  { map_id => "map_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XLQADezENOFU9cyXWoYgsA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
