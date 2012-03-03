package SGN::Schema::UnigeneBuild;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::UnigeneBuild

=cut

__PACKAGE__->table("unigene_build");

=head1 ACCESSORS

=head2 unigene_build_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'unigene_build_unigene_build_id_seq'

=head2 source_data_group_id

  data_type: 'integer'
  is_nullable: 1

=head2 organism_group_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 build_nr

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 build_date

  data_type: 'date'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 method_id

  data_type: 'integer'
  is_nullable: 1

=head2 status

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 superseding_build_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 next_build_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 latest_build_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 blast_db_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "unigene_build_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "unigene_build_unigene_build_id_seq",
  },
  "source_data_group_id",
  { data_type => "integer", is_nullable => 1 },
  "organism_group_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "build_nr",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "build_date",
  {
    data_type     => "date",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "method_id",
  { data_type => "integer", is_nullable => 1 },
  "status",
  { data_type => "char", is_nullable => 1, size => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "superseding_build_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "next_build_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "latest_build_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "blast_db_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("unigene_build_id");

=head1 RELATIONS

=head2 unigenes

Type: has_many

Related object: L<SGN::Schema::Unigene>

=cut

__PACKAGE__->has_many(
  "unigenes",
  "SGN::Schema::Unigene",
  { "foreign.unigene_build_id" => "self.unigene_build_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 superseding_build

Type: belongs_to

Related object: L<SGN::Schema::UnigeneBuild>

=cut

__PACKAGE__->belongs_to(
  "superseding_build",
  "SGN::Schema::UnigeneBuild",
  { unigene_build_id => "superseding_build_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 unigene_build_superseding_builds

Type: has_many

Related object: L<SGN::Schema::UnigeneBuild>

=cut

__PACKAGE__->has_many(
  "unigene_build_superseding_builds",
  "SGN::Schema::UnigeneBuild",
  { "foreign.superseding_build_id" => "self.unigene_build_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organism_group

Type: belongs_to

Related object: L<SGN::Schema::Group>

=cut

__PACKAGE__->belongs_to(
  "organism_group",
  "SGN::Schema::Group",
  { group_id => "organism_group_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 next_build

Type: belongs_to

Related object: L<SGN::Schema::UnigeneBuild>

=cut

__PACKAGE__->belongs_to(
  "next_build",
  "SGN::Schema::UnigeneBuild",
  { unigene_build_id => "next_build_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 unigene_build_next_builds

Type: has_many

Related object: L<SGN::Schema::UnigeneBuild>

=cut

__PACKAGE__->has_many(
  "unigene_build_next_builds",
  "SGN::Schema::UnigeneBuild",
  { "foreign.next_build_id" => "self.unigene_build_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 latest_build

Type: belongs_to

Related object: L<SGN::Schema::UnigeneBuild>

=cut

__PACKAGE__->belongs_to(
  "latest_build",
  "SGN::Schema::UnigeneBuild",
  { unigene_build_id => "latest_build_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 unigene_build_latest_builds

Type: has_many

Related object: L<SGN::Schema::UnigeneBuild>

=cut

__PACKAGE__->has_many(
  "unigene_build_latest_builds",
  "SGN::Schema::UnigeneBuild",
  { "foreign.latest_build_id" => "self.unigene_build_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 blast_db

Type: belongs_to

Related object: L<SGN::Schema::BlastDb>

=cut

__PACKAGE__->belongs_to(
  "blast_db",
  "SGN::Schema::BlastDb",
  { blast_db_id => "blast_db_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EsKIExQ2mGfjNs4pxg8qfw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
