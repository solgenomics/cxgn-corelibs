package SGN::Schema::Map;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Map

=cut

__PACKAGE__->table("map");

=head1 ACCESSORS

=head2 map_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'map_map_id_seq'

=head2 short_name

  data_type: 'text'
  is_nullable: 0

=head2 long_name

  data_type: 'text'
  is_nullable: 1

=head2 abstract

  data_type: 'text'
  is_nullable: 1

=head2 map_type

  data_type: 'text'
  is_nullable: 1

=head2 parent_1

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 parent_2

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 units

  data_type: 'text'
  default_value: 'cM'
  is_nullable: 1

=head2 ancestor

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 population_id

  data_type: 'integer'
  is_nullable: 1

=head2 parent1_stock_id

  data_type: 'bigint'
  is_nullable: 1

=head2 parent2_stock_id

  data_type: 'bigint'
  is_nullable: 1

=head2 population_stock_id

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "map_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "map_map_id_seq",
  },
  "short_name",
  { data_type => "text", is_nullable => 0 },
  "long_name",
  { data_type => "text", is_nullable => 1 },
  "abstract",
  { data_type => "text", is_nullable => 1 },
  "map_type",
  { data_type => "text", is_nullable => 1 },
  "parent_1",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "parent_2",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "units",
  { data_type => "text", default_value => "cM", is_nullable => 1 },
  "ancestor",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "population_id",
  { data_type => "integer", is_nullable => 1 },
  "parent1_stock_id",
  { data_type => "bigint", is_nullable => 1 },
  "parent2_stock_id",
  { data_type => "bigint", is_nullable => 1 },
  "population_stock_id",
  { data_type => "bigint", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("map_id");

=head1 RELATIONS

=head2 ancestor

Type: belongs_to

Related object: L<SGN::Schema::Accession>

=cut

__PACKAGE__->belongs_to(
  "ancestor",
  "SGN::Schema::Accession",
  { accession_id => "ancestor" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 parent_2

Type: belongs_to

Related object: L<SGN::Schema::Accession>

=cut

__PACKAGE__->belongs_to(
  "parent_2",
  "SGN::Schema::Accession",
  { accession_id => "parent_2" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 parent_1

Type: belongs_to

Related object: L<SGN::Schema::Accession>

=cut

__PACKAGE__->belongs_to(
  "parent_1",
  "SGN::Schema::Accession",
  { accession_id => "parent_1" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 map_versions

Type: has_many

Related object: L<SGN::Schema::MapVersion>

=cut

__PACKAGE__->has_many(
  "map_versions",
  "SGN::Schema::MapVersion",
  { "foreign.map_id" => "self.map_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pcr_experiments

Type: has_many

Related object: L<SGN::Schema::PcrExperiment>

=cut

__PACKAGE__->has_many(
  "pcr_experiments",
  "SGN::Schema::PcrExperiment",
  { "foreign.map_id" => "self.map_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AYZYWOx5WJ4XydpNX0pWIw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
