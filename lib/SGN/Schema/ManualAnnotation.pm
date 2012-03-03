package SGN::Schema::ManualAnnotation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::ManualAnnotation

=cut

__PACKAGE__->table("manual_annotations");

=head1 ACCESSORS

=head2 manual_annotations_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'manual_annotations_manual_annotations_id_seq'

=head2 annotation_target_id

  data_type: 'bigint'
  is_nullable: 1

=head2 annotation_target_type_id

  data_type: 'bigint'
  is_nullable: 1

=head2 annotation_text

  data_type: 'text'
  is_nullable: 1

=head2 author_id

  data_type: 'bigint'
  is_nullable: 1

=head2 date_entered

  data_type: 'date'
  is_nullable: 1

=head2 last_modified

  data_type: 'date'
  is_nullable: 1

=head2 annotation_text_fulltext

  data_type: 'tsvector'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "manual_annotations_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "manual_annotations_manual_annotations_id_seq",
  },
  "annotation_target_id",
  { data_type => "bigint", is_nullable => 1 },
  "annotation_target_type_id",
  { data_type => "bigint", is_nullable => 1 },
  "annotation_text",
  { data_type => "text", is_nullable => 1 },
  "author_id",
  { data_type => "bigint", is_nullable => 1 },
  "date_entered",
  { data_type => "date", is_nullable => 1 },
  "last_modified",
  { data_type => "date", is_nullable => 1 },
  "annotation_text_fulltext",
  { data_type => "tsvector", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("manual_annotations_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Gcxm7n7LvfxTdi36jg+9Gg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
