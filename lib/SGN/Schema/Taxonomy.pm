package SGN::Schema::Taxonomy;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Taxonomy

=cut

__PACKAGE__->table("taxonomy");

=head1 ACCESSORS

=head2 tax_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'taxonomy_tax_id_seq'

=head2 tax_name

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 tax_type

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=cut

__PACKAGE__->add_columns(
  "tax_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "taxonomy_tax_id_seq",
  },
  "tax_name",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "tax_type",
  { data_type => "varchar", is_nullable => 1, size => 50 },
);
__PACKAGE__->set_primary_key("tax_id");

=head1 RELATIONS

=head2 organism_order_taxes

Type: has_many

Related object: L<SGN::Schema::Organism>

=cut

__PACKAGE__->has_many(
  "organism_order_taxes",
  "SGN::Schema::Organism",
  { "foreign.order_tax" => "self.tax_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organism_family_taxes

Type: has_many

Related object: L<SGN::Schema::Organism>

=cut

__PACKAGE__->has_many(
  "organism_family_taxes",
  "SGN::Schema::Organism",
  { "foreign.family_tax" => "self.tax_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organism_genus_taxes

Type: has_many

Related object: L<SGN::Schema::Organism>

=cut

__PACKAGE__->has_many(
  "organism_genus_taxes",
  "SGN::Schema::Organism",
  { "foreign.genus_tax" => "self.tax_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organism_subfamily_taxes

Type: has_many

Related object: L<SGN::Schema::Organism>

=cut

__PACKAGE__->has_many(
  "organism_subfamily_taxes",
  "SGN::Schema::Organism",
  { "foreign.subfamily_tax" => "self.tax_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oDr8F1joqs5Q8VT/s0g9Ow


# You can replace this text with custom content, and it will be preserved on regeneration
1;
