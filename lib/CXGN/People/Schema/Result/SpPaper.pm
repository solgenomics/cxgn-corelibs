use utf8;
package CXGN::People::Schema::Result::SpPaper;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpPaper

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_papers>

=cut

__PACKAGE__->table("sp_papers");

=head1 ACCESSORS

=head2 sp_paper_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_papers_sp_paper_id_seq'

=head2 person_id

  data_type: 'integer'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 1

=head2 author_list

  data_type: 'text'
  is_nullable: 1

=head2 journal

  data_type: 'text'
  is_nullable: 1

=head2 volume

  data_type: 'bigint'
  is_nullable: 1

=head2 pages

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 keywords

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sp_paper_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_papers_sp_paper_id_seq",
  },
  "person_id",
  {
    data_type      => "integer",
    default_value  => 0,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "title",
  { data_type => "text", is_nullable => 1 },
  "author_list",
  { data_type => "text", is_nullable => 1 },
  "journal",
  { data_type => "text", is_nullable => 1 },
  "volume",
  { data_type => "bigint", is_nullable => 1 },
  "pages",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "keywords",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_paper_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_paper_id");

=head1 RELATIONS

=head2 person

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpPerson>

=cut

__PACKAGE__->belongs_to(
  "person",
  "CXGN::People::Schema::Result::SpPerson",
  { sp_person_id => "person_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-26 16:04:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LzBDeKW3MRybsvH98JeUtQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
