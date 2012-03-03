package SGN::Schema::UnigeneMember;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::UnigeneMember

=cut

__PACKAGE__->table("unigene_member");

=head1 ACCESSORS

=head2 unigene_member_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'unigene_member_unigene_member_id_seq'

=head2 unigene_id

  data_type: 'integer'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0

=head2 est_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 start

  data_type: 'bigint'
  is_nullable: 1

=head2 stop

  data_type: 'bigint'
  is_nullable: 1

=head2 qstart

  data_type: 'bigint'
  is_nullable: 1

=head2 qend

  data_type: 'bigint'
  is_nullable: 1

=head2 dir

  data_type: 'char'
  is_nullable: 1
  size: 1

=cut

__PACKAGE__->add_columns(
  "unigene_member_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "unigene_member_unigene_member_id_seq",
  },
  "unigene_id",
  {
    data_type      => "integer",
    default_value  => 0,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "est_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "start",
  { data_type => "bigint", is_nullable => 1 },
  "stop",
  { data_type => "bigint", is_nullable => 1 },
  "qstart",
  { data_type => "bigint", is_nullable => 1 },
  "qend",
  { data_type => "bigint", is_nullable => 1 },
  "dir",
  { data_type => "char", is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("unigene_member_id");

=head1 RELATIONS

=head2 unigene

Type: belongs_to

Related object: L<SGN::Schema::Unigene>

=cut

__PACKAGE__->belongs_to(
  "unigene",
  "SGN::Schema::Unigene",
  { unigene_id => "unigene_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 est

Type: belongs_to

Related object: L<SGN::Schema::Est>

=cut

__PACKAGE__->belongs_to(
  "est",
  "SGN::Schema::Est",
  { est_id => "est_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2oZk+NBGlTaYYsoDTPnXHQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
