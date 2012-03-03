package SGN::Schema::Accession;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Accession

=cut

__PACKAGE__->table("accession");

=head1 ACCESSORS

=head2 accession_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'accession_accession_id_seq'

=head2 organism_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 common_name

  data_type: 'varchar'
  is_nullable: 1
  size: 80

=head2 accession_name_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 chado_organism_id

  data_type: 'integer'
  is_nullable: 1

=head2 stock_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "accession_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "accession_accession_id_seq",
  },
  "organism_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "common_name",
  { data_type => "varchar", is_nullable => 1, size => 80 },
  "accession_name_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "chado_organism_id",
  { data_type => "integer", is_nullable => 1 },
  "stock_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("accession_id");
__PACKAGE__->add_unique_constraint("unique_accession_name", ["accession_name_id"]);

=head1 RELATIONS

=head2 organism

Type: belongs_to

Related object: L<SGN::Schema::Organism>

=cut

__PACKAGE__->belongs_to(
  "organism",
  "SGN::Schema::Organism",
  { organism_id => "organism_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 accession_name

Type: belongs_to

Related object: L<SGN::Schema::AccessionName>

=cut

__PACKAGE__->belongs_to(
  "accession_name",
  "SGN::Schema::AccessionName",
  { accession_name_id => "accession_name_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 accession_names

Type: has_many

Related object: L<SGN::Schema::AccessionName>

=cut

__PACKAGE__->has_many(
  "accession_names",
  "SGN::Schema::AccessionName",
  { "foreign.accession_id" => "self.accession_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 map_ancestors

Type: has_many

Related object: L<SGN::Schema::Map>

=cut

__PACKAGE__->has_many(
  "map_ancestors",
  "SGN::Schema::Map",
  { "foreign.ancestor" => "self.accession_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 map_parent_2s

Type: has_many

Related object: L<SGN::Schema::Map>

=cut

__PACKAGE__->has_many(
  "map_parent_2s",
  "SGN::Schema::Map",
  { "foreign.parent_2" => "self.accession_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 map_parent_1s

Type: has_many

Related object: L<SGN::Schema::Map>

=cut

__PACKAGE__->has_many(
  "map_parent_1s",
  "SGN::Schema::Map",
  { "foreign.parent_1" => "self.accession_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pcr_exp_accessions

Type: has_many

Related object: L<SGN::Schema::PcrExpAccession>

=cut

__PACKAGE__->has_many(
  "pcr_exp_accessions",
  "SGN::Schema::PcrExpAccession",
  { "foreign.accession_id" => "self.accession_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:838fnA2hrzzcn5PKEGLZRA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
