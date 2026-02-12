use utf8;
package CXGN::People::Schema::Result::SpWiki;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpWiki

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_wiki>

=cut

__PACKAGE__->table("sp_wiki");

=head1 ACCESSORS

=head2 sp_wiki_id

  data_type: 'bigint'

=head2 page_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 sp_person_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 is_public

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 create_date

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "sp_wiki_id",
  { data_type => "bigint", is_nullable => 0, is_auto_increment => 1 },
  "page_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "sp_person_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "is_public",
  { data_type => "boolean", default_value => "false", is_nullable => 1 },
  "create_date",
  { date_type => "varchar", is_nullable => 0 }
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_wiki_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_wiki_id");

=head1 RELATIONS

=head2 sp_person

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpPerson>

=cut

__PACKAGE__->belongs_to(
  "sp_person",
  "CXGN::People::Schema::Result::SpPerson",
  { sp_person_id => "sp_person_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 sp_wiki_contents

Type: has_many

Related object: L<CXGN::People::Schema::Result::SpWikiContent>

=cut

__PACKAGE__->has_many(
  "sp_wiki_contents",
  "CXGN::People::Schema::Result::SpWikiContent",
  { "foreign.sp_wiki_id" => "self.sp_wiki_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2026-01-28 14:49:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NBsl4Iuwgu/g1xRTP3VA/Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
