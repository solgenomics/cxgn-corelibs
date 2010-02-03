package SGN::Schema::ManualAnnotation;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("manual_annotations");
__PACKAGE__->add_columns(
  "manual_annotations_id",
  {
    data_type => "bigint",
    default_value => "nextval('manual_annotations_manual_annotations_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "annotation_target_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "annotation_target_type_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "annotation_text",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "author_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "date_entered",
  { data_type => "date", default_value => undef, is_nullable => 1, size => 4 },
  "last_modified",
  { data_type => "date", default_value => undef, is_nullable => 1, size => 4 },
  "annotation_text_fulltext",
  {
    data_type => "tsvector",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("manual_annotations_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:K8QGDYaUCQtnVbQ9FY22QQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
