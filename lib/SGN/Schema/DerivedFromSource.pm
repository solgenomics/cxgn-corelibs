package SGN::Schema::DerivedFromSource;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::DerivedFromSource

=cut

__PACKAGE__->table("derived_from_source");

=head1 ACCESSORS

=head2 derived_from_source_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'derived_from_source_derived_from_source_id_seq'

=head2 source_name

  accessor: undef
  data_type: 'text'
  is_nullable: 1

=head2 source_schema

  data_type: 'text'
  is_nullable: 1

=head2 source_table

  data_type: 'text'
  is_nullable: 1

=head2 source_col

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "derived_from_source_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "derived_from_source_derived_from_source_id_seq",
  },
  "source_name",
  { accessor => undef, data_type => "text", is_nullable => 1 },
  "source_schema",
  { data_type => "text", is_nullable => 1 },
  "source_table",
  { data_type => "text", is_nullable => 1 },
  "source_col",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("derived_from_source_id");
__PACKAGE__->add_unique_constraint(
  "derived_from_source_source_schema_key",
  ["source_schema", "source_table", "source_col"],
);

=head1 RELATIONS

=head2 markers_derived_from

Type: has_many

Related object: L<SGN::Schema::MarkerDerivedFrom>

=cut

__PACKAGE__->has_many(
  "markers_derived_from",
  "SGN::Schema::MarkerDerivedFrom",
  {
    "foreign.derived_from_source_id" => "self.derived_from_source_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ruLxFFQtkZYBM0p4UbMSJw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
