package SGN::Schema::Cd;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Cd

=cut

__PACKAGE__->table("cds");

=head1 ACCESSORS

=head2 cds_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cds_cds_id_seq'

=head2 unigene_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 seq_text

  data_type: 'text'
  is_nullable: 1

=head2 seq_edits

  data_type: 'text'
  is_nullable: 1

=head2 protein_seq

  data_type: 'text'
  is_nullable: 1

=head2 begin

  data_type: 'integer'
  is_nullable: 1

=head2 end

  data_type: 'integer'
  is_nullable: 1

=head2 forward_reverse

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 run_id

  data_type: 'bigint'
  is_nullable: 1

=head2 score

  data_type: 'integer'
  is_nullable: 1

=head2 method

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 frame

  data_type: 'varchar'
  is_nullable: 1
  size: 2

=head2 preferred

  data_type: 'boolean'
  is_nullable: 1

=head2 cds_seq

  data_type: 'text'
  is_nullable: 1

=head2 protein_feature_id

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cds_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cds_cds_id_seq",
  },
  "unigene_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "seq_text",
  { data_type => "text", is_nullable => 1 },
  "seq_edits",
  { data_type => "text", is_nullable => 1 },
  "protein_seq",
  { data_type => "text", is_nullable => 1 },
  "begin",
  { data_type => "integer", is_nullable => 1 },
  "end",
  { data_type => "integer", is_nullable => 1 },
  "forward_reverse",
  { data_type => "char", is_nullable => 1, size => 1 },
  "run_id",
  { data_type => "bigint", is_nullable => 1 },
  "score",
  { data_type => "integer", is_nullable => 1 },
  "method",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "frame",
  { data_type => "varchar", is_nullable => 1, size => 2 },
  "preferred",
  { data_type => "boolean", is_nullable => 1 },
  "cds_seq",
  { data_type => "text", is_nullable => 1 },
  "protein_feature_id",
  { data_type => "bigint", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("cds_id");

=head1 RELATIONS

=head2 unigene

Type: belongs_to

Related object: L<SGN::Schema::Unigene>

=cut

__PACKAGE__->belongs_to(
  "unigene",
  "SGN::Schema::Unigene",
  { unigene_id => "unigene_id" },
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
  { "foreign.cds_id" => "self.cds_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U8lI8JoWcDtZrDhqgQ/yLg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
