package SGN::Schema::Go;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Go

=cut

__PACKAGE__->table("go");

=head1 ACCESSORS

=head2 go_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'go_go_id_seq'

=head2 go_accession

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
  "go_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "go_go_id_seq",
  },
  "go_accession",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "description_fulltext",
  { data_type => "tsvector", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("go_id");
__PACKAGE__->add_unique_constraint("go_go_accession_key", ["go_accession"]);

=head1 RELATIONS

=head2 interpros_go

Type: has_many

Related object: L<SGN::Schema::InterproGo>

=cut

__PACKAGE__->has_many(
  "interpros_go",
  "SGN::Schema::InterproGo",
  { "foreign.go_accession" => "self.go_accession" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XuyLAWBLxoap9z3FlcVShQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
