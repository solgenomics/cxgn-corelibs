package SGN::Schema::Interpro;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Interpro

=cut

__PACKAGE__->table("interpro");

=head1 ACCESSORS

=head2 interpro_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'interpro_interpro_id_seq'

=head2 interpro_accession

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 description_fulltext

  data_type: 'tsvector'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "interpro_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "interpro_interpro_id_seq",
  },
  "interpro_accession",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "description_fulltext",
  { data_type => "tsvector", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("interpro_id");
__PACKAGE__->add_unique_constraint("interpro_interpro_accession_key", ["interpro_accession"]);

=head1 RELATIONS

=head2 interpros_go

Type: has_many

Related object: L<SGN::Schema::InterproGo>

=cut

__PACKAGE__->has_many(
  "interpros_go",
  "SGN::Schema::InterproGo",
  { "foreign.interpro_accession" => "self.interpro_accession" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:goZBzUs2dp7PRwn/DDOY0A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
