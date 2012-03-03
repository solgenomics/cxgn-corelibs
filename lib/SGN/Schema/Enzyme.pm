package SGN::Schema::Enzyme;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Enzyme

=cut

__PACKAGE__->table("enzymes");

=head1 ACCESSORS

=head2 enzyme_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'enzymes_enzyme_id_seq'

=head2 enzyme_name

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "enzyme_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "enzymes_enzyme_id_seq",
  },
  "enzyme_name",
  { data_type => "varchar", is_nullable => 1, size => 32 },
);
__PACKAGE__->set_primary_key("enzyme_id");
__PACKAGE__->add_unique_constraint("enzymes_enzyme_name_key", ["enzyme_name"]);

=head1 RELATIONS

=head2 pcr_products

Type: has_many

Related object: L<SGN::Schema::PcrProduct>

=cut

__PACKAGE__->has_many(
  "pcr_products",
  "SGN::Schema::PcrProduct",
  { "foreign.enzyme_id" => "self.enzyme_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7LZeXCaVkuG7Yq8TRquAHw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
