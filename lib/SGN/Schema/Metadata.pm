package SGN::Schema::Metadata;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Metadata

=cut

__PACKAGE__->table("metadata");

=head1 ACCESSORS

=head2 metadata_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'metadata_metadata_id_seq'

=head2 create_date

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 create_person_id

  data_type: 'integer'
  is_nullable: 0

=head2 modified_date

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 modified_person_id

  data_type: 'integer'
  is_nullable: 1

=head2 previous_metadata_id

  data_type: 'integer'
  is_nullable: 1

=head2 obsolete

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=head2 obsolete_note

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=cut

__PACKAGE__->add_columns(
  "metadata_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "metadata_metadata_id_seq",
  },
  "create_date",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "create_person_id",
  { data_type => "integer", is_nullable => 0 },
  "modified_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "modified_person_id",
  { data_type => "integer", is_nullable => 1 },
  "previous_metadata_id",
  { data_type => "integer", is_nullable => 1 },
  "obsolete",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "obsolete_note",
  { data_type => "varchar", is_nullable => 1, size => 250 },
);
__PACKAGE__->set_primary_key("metadata_id");

=head1 RELATIONS

=head2 domains

Type: has_many

Related object: L<SGN::Schema::Domain>

=cut

__PACKAGE__->has_many(
  "domains",
  "SGN::Schema::Domain",
  { "foreign.metadata_id" => "self.metadata_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 domain_matches

Type: has_many

Related object: L<SGN::Schema::DomainMatch>

=cut

__PACKAGE__->has_many(
  "domain_matches",
  "SGN::Schema::DomainMatch",
  { "foreign.metadata_id" => "self.metadata_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BLIbTLwRw2MATmnZ/869rA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
