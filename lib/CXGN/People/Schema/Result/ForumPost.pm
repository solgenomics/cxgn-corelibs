use utf8;
package CXGN::People::Schema::Result::ForumPost;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::ForumPost

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<forum_post>

=cut

__PACKAGE__->table("forum_post");

=head1 ACCESSORS

=head2 forum_post_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.forum_post_forum_post_id_seq'

=head2 person_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 post_text

  data_type: 'text'
  is_nullable: 1

=head2 parent_post_id

  data_type: 'bigint'
  is_nullable: 1

=head2 forum_topic_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 subject

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 post_time

  data_type: 'timestamp'
  default_value: ('now'::text)::timestamp(6) with time zone
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "forum_post_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.forum_post_forum_post_id_seq",
  },
  "person_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "post_text",
  { data_type => "text", is_nullable => 1 },
  "parent_post_id",
  { data_type => "bigint", is_nullable => 1 },
  "forum_topic_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "subject",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "post_time",
  {
    data_type     => "timestamp",
    default_value => \"('now'::text)::timestamp(6) with time zone",
    is_nullable   => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</forum_post_id>

=back

=cut

__PACKAGE__->set_primary_key("forum_post_id");

=head1 RELATIONS

=head2 forum_topic

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::ForumTopic>

=cut

__PACKAGE__->belongs_to(
  "forum_topic",
  "CXGN::People::Schema::Result::ForumTopic",
  { forum_topic_id => "forum_topic_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kWJ3BeGPQG/C85OpYxoCnw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
