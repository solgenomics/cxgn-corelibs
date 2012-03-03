package SGN::Schema::Microarray;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Microarray

=cut

__PACKAGE__->table("microarray");

=head1 ACCESSORS

=head2 microarray_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'microarray_microarray_id_seq'

=head2 chip_name

  data_type: 'varchar'
  is_nullable: 1
  size: 80

=head2 release

  data_type: 'bigint'
  is_nullable: 1

=head2 version

  data_type: 'bigint'
  is_nullable: 1

=head2 spot_id

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 content_specific_tag

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 clone_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "microarray_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "microarray_microarray_id_seq",
  },
  "chip_name",
  { data_type => "varchar", is_nullable => 1, size => 80 },
  "release",
  { data_type => "bigint", is_nullable => 1 },
  "version",
  { data_type => "bigint", is_nullable => 1 },
  "spot_id",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "content_specific_tag",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "clone_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("microarray_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:D7MV8jLQPry3+egSyEAinA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
