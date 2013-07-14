package SGN::Schema::BlastDbGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::BlastDbGroup

=cut

__PACKAGE__->table("blast_db_group");

=head1 ACCESSORS

=head2 blast_db_group_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'blast_db_group_blast_db_group_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 ordinal

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "blast_db_group_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "blast_db_group_blast_db_group_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "ordinal",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("blast_db_group_id");

=head1 RELATIONS

=head2 blast_dbs

Type: has_many

Related object: L<SGN::Schema::BlastDb>

=cut

#__PACKAGE__->has_many(
#  "blast_dbs",
#  "SGN::Schema::BlastDb",
#  { "foreign.blast_db_group_id" => "self.blast_db_group_id" },
#  { cascade_copy => 0 }, #cascade_delete => 0 },
#);

 __PACKAGE__->has_many(
     "blast_db_blast_db_groups",
     "SGN::Schema::BlastDbBlastDbGroup",
     { "foreign.blast_db_group_id" => "self.blast_db_group_id"},
     #{cascade_copy => 0, }, # cascade_delete => 0 },
     );

 __PACKAGE__->many_to_many("blast_dbs", "blast_db_blast_db_groups", "blast_db");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aH2DxlwsJstedBgQOG01rQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
