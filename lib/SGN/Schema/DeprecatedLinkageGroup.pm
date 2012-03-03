package SGN::Schema::DeprecatedLinkageGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::DeprecatedLinkageGroup

=cut

__PACKAGE__->table("deprecated_linkage_groups");

=head1 ACCESSORS

=head2 lg_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'deprecated_linkage_groups_lg_id_seq'

=head2 map_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 lg_order

  data_type: 'bigint'
  is_nullable: 1

=head2 lg_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "lg_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "deprecated_linkage_groups_lg_id_seq",
  },
  "map_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "lg_order",
  { data_type => "bigint", is_nullable => 1 },
  "lg_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("lg_id");

=head1 RELATIONS

=head2 map

Type: belongs_to

Related object: L<SGN::Schema::DeprecatedMap>

=cut

__PACKAGE__->belongs_to(
  "map",
  "SGN::Schema::DeprecatedMap",
  { map_id => "map_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 deprecated_mapdatas

Type: has_many

Related object: L<SGN::Schema::DeprecatedMapdata>

=cut

__PACKAGE__->has_many(
  "deprecated_mapdatas",
  "SGN::Schema::DeprecatedMapdata",
  { "foreign.lg_id" => "self.lg_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9dFb1FK633Dd6TcghBivCA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
