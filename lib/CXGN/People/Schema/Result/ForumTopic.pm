use utf8;
package CXGN::People::Schema::Result::ForumTopic;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::ForumTopic

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<forum_topic>

=cut

__PACKAGE__->table("forum_topic");

=head1 ACCESSORS

=head2 forum_topic_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.forum_topic_forum_topic_id_seq'

=head2 person_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 topic_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 parent_topic

  data_type: 'bigint'
  is_nullable: 1

=head2 topic_class

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 page_type

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 page_object_id

  data_type: 'bigint'
  is_nullable: 1

=head2 topic_description

  data_type: 'text'
  is_nullable: 1

=head2 sort_order

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=cut

__PACKAGE__->add_columns(
  "forum_topic_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.forum_topic_forum_topic_id_seq",
  },
  "person_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "topic_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "parent_topic",
  { data_type => "bigint", is_nullable => 1 },
  "topic_class",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "page_type",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "page_object_id",
  { data_type => "bigint", is_nullable => 1 },
  "topic_description",
  { data_type => "text", is_nullable => 1 },
  "sort_order",
  { data_type => "varchar", is_nullable => 1, size => 10 },
);

=head1 PRIMARY KEY

=over 4

=item * L</forum_topic_id>

=back

=cut

__PACKAGE__->set_primary_key("forum_topic_id");

=head1 RELATIONS

=head2 forum_posts

Type: has_many

Related object: L<CXGN::People::Schema::Result::ForumPost>

=cut

__PACKAGE__->has_many(
  "forum_posts",
  "CXGN::People::Schema::Result::ForumPost",
  { "foreign.forum_topic_id" => "self.forum_topic_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 person

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpPerson>

=cut

__PACKAGE__->belongs_to(
  "person",
  "CXGN::People::Schema::Result::SpPerson",
  { sp_person_id => "person_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-26 16:04:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mvvQ2JtqTni9efQZhlkgng


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
