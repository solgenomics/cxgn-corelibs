package SGN::Schema::InterproGo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::InterproGo

=cut

__PACKAGE__->table("interpro_go");

=head1 ACCESSORS

=head2 interpro_go_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'interpro_go_interpro_go_id_seq'

=head2 interpro_accession

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 1
  size: 20

=head2 go_accession

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 1
  size: 20

=cut

__PACKAGE__->add_columns(
  "interpro_go_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "interpro_go_interpro_go_id_seq",
  },
  "interpro_accession",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 1, size => 20 },
  "go_accession",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 1, size => 20 },
);
__PACKAGE__->set_primary_key("interpro_go_id");

=head1 RELATIONS

=head2 go_accession

Type: belongs_to

Related object: L<SGN::Schema::Go>

=cut

__PACKAGE__->belongs_to(
  "go_accession",
  "SGN::Schema::Go",
  { go_accession => "go_accession" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 interpro_accession

Type: belongs_to

Related object: L<SGN::Schema::Interpro>

=cut

__PACKAGE__->belongs_to(
  "interpro_accession",
  "SGN::Schema::Interpro",
  { interpro_accession => "interpro_accession" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xsDCm4apdwyu7QR/kIlmJg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
