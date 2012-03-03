package SGN::Schema::Organism;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Organism

=cut

__PACKAGE__->table("organism");

=head1 ACCESSORS

=head2 organism_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'organism_organism_id_seq'

=head2 organism_name

  data_type: 'varchar'
  is_nullable: 1
  size: 80

=head2 common_name_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 organism_descrip

  data_type: 'text'
  is_nullable: 1

=head2 specie_tax

  data_type: 'varchar'
  is_nullable: 1
  size: 80

=head2 genus_tax

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 subfamily_tax

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 family_tax

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 order_tax

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 chr_n_gnmc

  data_type: 'integer'
  is_nullable: 1

=head2 polypl_gnmc

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 genom_size_gnmc

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 genom_proj_gnmc

  data_type: 'text'
  is_nullable: 1

=head2 est_attribution_tqmc

  data_type: 'text'
  is_nullable: 1

=head2 chado_organism_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "organism_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "organism_organism_id_seq",
  },
  "organism_name",
  { data_type => "varchar", is_nullable => 1, size => 80 },
  "common_name_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "organism_descrip",
  { data_type => "text", is_nullable => 1 },
  "specie_tax",
  { data_type => "varchar", is_nullable => 1, size => 80 },
  "genus_tax",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "subfamily_tax",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "family_tax",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "order_tax",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "chr_n_gnmc",
  { data_type => "integer", is_nullable => 1 },
  "polypl_gnmc",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "genom_size_gnmc",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "genom_proj_gnmc",
  { data_type => "text", is_nullable => 1 },
  "est_attribution_tqmc",
  { data_type => "text", is_nullable => 1 },
  "chado_organism_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("organism_id");
__PACKAGE__->add_unique_constraint("unique_organism_name", ["organism_name"]);

=head1 RELATIONS

=head2 accessions

Type: has_many

Related object: L<SGN::Schema::Accession>

=cut

__PACKAGE__->has_many(
  "accessions",
  "SGN::Schema::Accession",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 deprecated_map_crosses

Type: has_many

Related object: L<SGN::Schema::DeprecatedMapCross>

=cut

__PACKAGE__->has_many(
  "deprecated_map_crosses",
  "SGN::Schema::DeprecatedMapCross",
  { "foreign.organism_id" => "self.organism_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 order_tax

Type: belongs_to

Related object: L<SGN::Schema::Taxonomy>

=cut

__PACKAGE__->belongs_to(
  "order_tax",
  "SGN::Schema::Taxonomy",
  { tax_id => "order_tax" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 family_tax

Type: belongs_to

Related object: L<SGN::Schema::Taxonomy>

=cut

__PACKAGE__->belongs_to(
  "family_tax",
  "SGN::Schema::Taxonomy",
  { tax_id => "family_tax" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 genus_tax

Type: belongs_to

Related object: L<SGN::Schema::Taxonomy>

=cut

__PACKAGE__->belongs_to(
  "genus_tax",
  "SGN::Schema::Taxonomy",
  { tax_id => "genus_tax" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 subfamily_tax

Type: belongs_to

Related object: L<SGN::Schema::Taxonomy>

=cut

__PACKAGE__->belongs_to(
  "subfamily_tax",
  "SGN::Schema::Taxonomy",
  { tax_id => "subfamily_tax" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 common_name

Type: belongs_to

Related object: L<SGN::Schema::CommonName>

=cut

__PACKAGE__->belongs_to(
  "common_name",
  "SGN::Schema::CommonName",
  { common_name_id => "common_name_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:P659Eo8bylRSynQff1O2mg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
