package SGN::Schema::Library;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Library

=cut

__PACKAGE__->table("library");

=head1 ACCESSORS

=head2 library_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'library_library_id_seq'

=head2 type

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 submit_user_id

  data_type: 'integer'
  is_nullable: 1

=head2 library_name

  data_type: 'varchar'
  is_nullable: 1
  size: 80

=head2 library_shortname

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 authors

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 organism_id

  data_type: 'integer'
  is_nullable: 1

=head2 cultivar

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 accession

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 tissue

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 development_stage

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 treatment_conditions

  data_type: 'text'
  is_nullable: 1

=head2 cloning_host

  data_type: 'varchar'
  is_nullable: 1
  size: 80

=head2 vector

  data_type: 'varchar'
  is_nullable: 1
  size: 80

=head2 rs1

  data_type: 'varchar'
  is_nullable: 1
  size: 12

=head2 rs2

  data_type: 'varchar'
  is_nullable: 1
  size: 12

=head2 cloning_kit

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 comments

  data_type: 'text'
  is_nullable: 1

=head2 contact_information

  data_type: 'text'
  is_nullable: 1

=head2 order_routing_id

  data_type: 'bigint'
  is_nullable: 1

=head2 sp_person_id

  data_type: 'integer'
  is_nullable: 1

=head2 forward_adapter

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 reverse_adapter

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 obsolete

  data_type: 'boolean'
  is_nullable: 1

=head2 modified_date

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 create_date

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 chado_organism_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "library_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "library_library_id_seq",
  },
  "type",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "submit_user_id",
  { data_type => "integer", is_nullable => 1 },
  "library_name",
  { data_type => "varchar", is_nullable => 1, size => 80 },
  "library_shortname",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "authors",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "organism_id",
  { data_type => "integer", is_nullable => 1 },
  "cultivar",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "accession",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "tissue",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "development_stage",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "treatment_conditions",
  { data_type => "text", is_nullable => 1 },
  "cloning_host",
  { data_type => "varchar", is_nullable => 1, size => 80 },
  "vector",
  { data_type => "varchar", is_nullable => 1, size => 80 },
  "rs1",
  { data_type => "varchar", is_nullable => 1, size => 12 },
  "rs2",
  { data_type => "varchar", is_nullable => 1, size => 12 },
  "cloning_kit",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "comments",
  { data_type => "text", is_nullable => 1 },
  "contact_information",
  { data_type => "text", is_nullable => 1 },
  "order_routing_id",
  { data_type => "bigint", is_nullable => 1 },
  "sp_person_id",
  { data_type => "integer", is_nullable => 1 },
  "forward_adapter",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "reverse_adapter",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "obsolete",
  { data_type => "boolean", is_nullable => 1 },
  "modified_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "create_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "chado_organism_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("library_id");
__PACKAGE__->add_unique_constraint("library_shortname_idx", ["library_shortname"]);

=head1 RELATIONS

=head2 clones

Type: has_many

Related object: L<SGN::Schema::Clone>

=cut

__PACKAGE__->has_many(
  "clones",
  "SGN::Schema::Clone",
  { "foreign.library_id" => "self.library_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 type

Type: belongs_to

Related object: L<SGN::Schema::Type>

=cut

__PACKAGE__->belongs_to(
  "type",
  "SGN::Schema::Type",
  { type_id => "type" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mEVMxr8tPb/rp+t5593leg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
