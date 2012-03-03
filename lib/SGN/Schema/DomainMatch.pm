package SGN::Schema::DomainMatch;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::DomainMatch

=cut

__PACKAGE__->table("domain_match");

=head1 ACCESSORS

=head2 domain_match_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'domain_match_domain_match_id_seq'

=head2 cds_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 unigene_id

  data_type: 'bigint'
  is_nullable: 1

=head2 domain_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 match_begin

  data_type: 'integer'
  is_nullable: 1

=head2 match_end

  data_type: 'integer'
  is_nullable: 1

=head2 e_value

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 hit_status

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 run_id

  data_type: 'bigint'
  is_nullable: 1

=head2 metadata_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "domain_match_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "domain_match_domain_match_id_seq",
  },
  "cds_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "unigene_id",
  { data_type => "bigint", is_nullable => 1 },
  "domain_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "match_begin",
  { data_type => "integer", is_nullable => 1 },
  "match_end",
  { data_type => "integer", is_nullable => 1 },
  "e_value",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "hit_status",
  { data_type => "char", is_nullable => 1, size => 1 },
  "run_id",
  { data_type => "bigint", is_nullable => 1 },
  "metadata_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("domain_match_id");

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

=head2 domain

Type: belongs_to

Related object: L<SGN::Schema::Domain>

=cut

__PACKAGE__->belongs_to(
  "domain",
  "SGN::Schema::Domain",
  { domain_id => "domain_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 cd

Type: belongs_to

Related object: L<SGN::Schema::Cd>

=cut

__PACKAGE__->belongs_to(
  "cd",
  "SGN::Schema::Cd",
  { cds_id => "cds_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0wucSV8vE26N2AjTvcBIzw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
