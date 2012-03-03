package SGN::Schema::AnnotationTargetType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::AnnotationTargetType

=cut

__PACKAGE__->table("annotation_target_type");

=head1 ACCESSORS

=head2 annotation_target_type_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'annotation_target_type_annotation_target_type_id_seq'

=head2 type_name

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 type_description

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=head2 table_name

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=head2 index_field_name

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=cut

__PACKAGE__->add_columns(
  "annotation_target_type_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "annotation_target_type_annotation_target_type_id_seq",
  },
  "type_name",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "type_description",
  { data_type => "varchar", is_nullable => 1, size => 250 },
  "table_name",
  { data_type => "varchar", is_nullable => 1, size => 250 },
  "index_field_name",
  { data_type => "varchar", is_nullable => 1, size => 250 },
);
__PACKAGE__->set_primary_key("annotation_target_type_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Bjf4bx76aEIipEgUK70buw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
