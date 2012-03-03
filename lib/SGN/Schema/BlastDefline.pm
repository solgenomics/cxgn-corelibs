package SGN::Schema::BlastDefline;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::BlastDefline

=cut

__PACKAGE__->table("blast_defline");

=head1 ACCESSORS

=head2 defline_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'blast_defline_defline_id_seq'

=head2 blast_target_id

  data_type: 'integer'
  is_nullable: 1

=head2 target_db_id

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 defline

  data_type: 'text'
  is_nullable: 1

=head2 defline_fulltext

  data_type: 'tsvector'
  is_nullable: 1

=head2 identifier_defline_fulltext

  data_type: 'tsvector'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "defline_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "blast_defline_defline_id_seq",
  },
  "blast_target_id",
  { data_type => "integer", is_nullable => 1 },
  "target_db_id",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "defline",
  { data_type => "text", is_nullable => 1 },
  "defline_fulltext",
  { data_type => "tsvector", is_nullable => 1 },
  "identifier_defline_fulltext",
  { data_type => "tsvector", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("defline_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:c3T+el9V3/ziJEFzPnmUUg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
