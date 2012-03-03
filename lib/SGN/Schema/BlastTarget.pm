package SGN::Schema::BlastTarget;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::BlastTarget

=cut

__PACKAGE__->table("blast_targets");

=head1 ACCESSORS

=head2 blast_target_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'blast_targets_blast_target_id_seq'

=head2 blast_program

  data_type: 'varchar'
  is_nullable: 1
  size: 7

=head2 db_name

  data_type: 'varchar'
  is_nullable: 1
  size: 80

=head2 db_path

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 local_copy_timestamp

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "blast_target_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "blast_targets_blast_target_id_seq",
  },
  "blast_program",
  { data_type => "varchar", is_nullable => 1, size => 7 },
  "db_name",
  { data_type => "varchar", is_nullable => 1, size => 80 },
  "db_path",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "local_copy_timestamp",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("blast_target_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vAn2GVNUrs9RPpEzKHuf+Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
