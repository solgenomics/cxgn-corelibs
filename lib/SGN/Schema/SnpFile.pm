package SGN::Schema::SnpFile;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::SnpFile

=cut

__PACKAGE__->table("snp_file");

=head1 ACCESSORS

=head2 snp_file_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn.snp_file_snp_file_id_seq'

=head2 snp_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 file_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "snp_file_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn.snp_file_snp_file_id_seq",
  },
  "snp_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "file_id",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("snp_file_id");

=head1 RELATIONS

=head2 snp

Type: belongs_to

Related object: L<SGN::Schema::Snp>

=cut

__PACKAGE__->belongs_to(
  "snp",
  "SGN::Schema::Snp",
  { snp_id => "snp_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hflJ0div2gwrhhgfJYql5w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
