use utf8;
package CXGN::People::Schema::Result::SpWikiContent;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpWikiContent

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_wiki_content>

=cut

__PACKAGE__->table("sp_wiki_content");

=head1 ACCESSORS

=head2 sp_wiki_content_id

  data_type: 'bigint'
  is_auto_increment: 1

=head2 sp_wiki_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 page_content

  data_type: 'text'
  is_nullable: 1

=head2 page_version

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sp_wiki_content_id",
  { data_type => "bigint", is_nullable => 0, is_auto_increment => 1 },
  "sp_wiki_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "page_content",
  { data_type => "text", is_nullable => 1 },
  "page_version",
  { data_type => "bigint", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_wiki_content_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_wiki_content_id");

=head1 RELATIONS

=head2 sp_wiki

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpWiki>

=cut

__PACKAGE__->belongs_to(
  "sp_wiki",
  "CXGN::People::Schema::Result::SpWiki",
  { sp_wiki_id => "sp_wiki_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2026-01-28 14:49:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5ZLgA0BBCunyMGULUdHbmQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
