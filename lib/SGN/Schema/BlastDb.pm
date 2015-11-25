use utf8;
package SGN::Schema::BlastDb;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

SGN::Schema::BlastDb

=head1 DESCRIPTION

This table holds metadata about the BLAST databases that we keep in stock.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<blast_db>

=cut

__PACKAGE__->table("blast_db");

=head1 ACCESSORS

=head2 blast_db_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn.blast_db_blast_db_id_seq'

=head2 file_base

  data_type: 'varchar'
  is_nullable: 0
  size: 120

the basename of the blast db files, relative to the root of the databases repository.  A blast DB is usually composed of 3 files, all with a given basename, and with the extensions .[pn]in, .[pn]sq, and .[pn]hr.

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 80

=head2 type

  data_type: 'varchar'
  is_nullable: 0
  size: 80

=head2 source_url

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 lookup_url

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 update_freq

  data_type: 'varchar'
  default_value: 'monthly'
  is_nullable: 0
  size: 80

=head2 info_url

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 index_seqs

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

corresponds to formatdb -o option.  Set true if formatdb should be given a '-o T'.  This is used only if you later want to fetch specific sequences out of this blast db.

=head2 blast_db_group_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

blast_db_group this belongs to, for displaying on web

=head2 web_interface_visible

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

whether this blast DB is available for BLASTing via web interfaces

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 jbrowse_src

  data_type: 'varchar'
  is_nullable: 1
  size: 80

=cut

__PACKAGE__->add_columns(
  "blast_db_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn.blast_db_blast_db_id_seq",
  },
  "file_base",
  { data_type => "varchar", is_nullable => 0, size => 120 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 80 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 80 },
  "source_url",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "lookup_url",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "update_freq",
  {
    data_type => "varchar",
    default_value => "monthly",
    is_nullable => 0,
    size => 80,
  },
  "info_url",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "index_seqs",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "blast_db_group_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "web_interface_visible",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "jbrowse_src",
  { data_type => "varchar", is_nullable => 1, size => 80 },
);

=head1 PRIMARY KEY

=over 4

=item * L</blast_db_id>

=back

=cut

__PACKAGE__->set_primary_key("blast_db_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<blast_db_file_base_key>

=over 4

=item * L</file_base>

=back

=cut

__PACKAGE__->add_unique_constraint("blast_db_file_base_key", ["file_base"]);

=head1 RELATIONS

=head2 blast_db_blast_db_groups

Type: has_many

Related object: L<SGN::Schema::BlastDbBlastDbGroup>

=cut

__PACKAGE__->has_many(
  "blast_db_blast_db_groups",
  "SGN::Schema::BlastDbBlastDbGroup",
  { "foreign.blast_db_id" => "self.blast_db_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 blast_db_group

Type: belongs_to

Related object: L<SGN::Schema::BlastDbGroup>

=cut

__PACKAGE__->belongs_to(
  "blast_db_group",
  "SGN::Schema::BlastDbGroup",
  { blast_db_group_id => "blast_db_group_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 blast_db_organisms

Type: has_many

Related object: L<SGN::Schema::BlastDbOrganism>

=cut

__PACKAGE__->has_many(
  "blast_db_organisms",
  "SGN::Schema::BlastDbOrganism",
  { "foreign.blast_db_id" => "self.blast_db_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 unigenes_build

Type: has_many

Related object: L<SGN::Schema::UnigeneBuild>

=cut

__PACKAGE__->has_many(
  "unigenes_build",
  "SGN::Schema::UnigeneBuild",
  { "foreign.blast_db_id" => "self.blast_db_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-11-25 02:57:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ywh4MuOW2h0G6hTEw4zwcA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
