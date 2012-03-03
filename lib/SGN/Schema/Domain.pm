package SGN::Schema::Domain;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Domain

=cut

__PACKAGE__->table("domain");

=head1 ACCESSORS

=head2 domain_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'domain_domain_id_seq'

=head2 method_id

  data_type: 'bigint'
  is_nullable: 1

=head2 domain_accession

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 interpro_id

  data_type: 'bigint'
  is_nullable: 1

=head2 description_fulltext

  data_type: 'tsvector'
  is_nullable: 1

=head2 dbxref_id

  data_type: 'bigint'
  is_nullable: 1

=head2 metadata_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "domain_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "domain_domain_id_seq",
  },
  "method_id",
  { data_type => "bigint", is_nullable => 1 },
  "domain_accession",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "interpro_id",
  { data_type => "bigint", is_nullable => 1 },
  "description_fulltext",
  { data_type => "tsvector", is_nullable => 1 },
  "dbxref_id",
  { data_type => "bigint", is_nullable => 1 },
  "metadata_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("domain_id");

=head1 RELATIONS

=head2 metadata

Type: belongs_to

Related object: L<SGN::Schema::Metadata>

=cut

__PACKAGE__->belongs_to(
  "metadata",
  "SGN::Schema::Metadata",
  { metadata_id => "metadata_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 domain_matches

Type: has_many

Related object: L<SGN::Schema::DomainMatch>

=cut

__PACKAGE__->has_many(
  "domain_matches",
  "SGN::Schema::DomainMatch",
  { "foreign.domain_id" => "self.domain_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+6BgaigBWwHVaAw929m+tQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
