package SGN::Schema::AnnotationTargetType;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("annotation_target_type");
__PACKAGE__->add_columns(
  "annotation_target_type_id",
  {
    data_type => "bigint",
    default_value => "nextval('annotation_target_type_annotation_target_type_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "type_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 25,
  },
  "type_description",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "table_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "index_field_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
);
__PACKAGE__->set_primary_key("annotation_target_type_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VZTFOr/UFqbpEMKJI1xlzg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
