package SGN::Schema::AccessionName;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::AccessionName

=cut

__PACKAGE__->table("accession_names");

=head1 ACCESSORS

=head2 accession_name_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'accession_names_accession_name_id_seq'

=head2 accession_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 accession_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "accession_name_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "accession_names_accession_name_id_seq",
  },
  "accession_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "accession_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("accession_name_id");

=head1 RELATIONS

=head2 accession

Type: might_have

Related object: L<SGN::Schema::Accession>

=cut

__PACKAGE__->might_have(
  "accession",
  "SGN::Schema::Accession",
  { "foreign.accession_name_id" => "self.accession_name_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 accession

Type: belongs_to

Related object: L<SGN::Schema::Accession>

=cut

__PACKAGE__->belongs_to(
  "accession",
  "SGN::Schema::Accession",
  { accession_id => "accession_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:AWnIAIDyVrbybKPzRs9kKQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
