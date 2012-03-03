package SGN::Schema::PrimerUnigeneMatch;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::PrimerUnigeneMatch

=cut

__PACKAGE__->table("primer_unigene_match");

=head1 ACCESSORS

=head2 primer_unigene_match_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'primer_unigene_match_primer_unigene_match_id_seq'

=head2 marker_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 unigene_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 primer_direction

  data_type: 'smallint'
  is_nullable: 1

=head2 match_length

  data_type: 'integer'
  is_nullable: 1

=head2 primer_match_start

  data_type: 'integer'
  is_nullable: 1

=head2 primer_match_end

  data_type: 'integer'
  is_nullable: 1

=head2 unigene_match_start

  data_type: 'integer'
  is_nullable: 1

=head2 unigene_match_end

  data_type: 'integer'
  is_nullable: 1

=head2 e_value

  data_type: 'double precision'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "primer_unigene_match_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "primer_unigene_match_primer_unigene_match_id_seq",
  },
  "marker_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "unigene_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "primer_direction",
  { data_type => "smallint", is_nullable => 1 },
  "match_length",
  { data_type => "integer", is_nullable => 1 },
  "primer_match_start",
  { data_type => "integer", is_nullable => 1 },
  "primer_match_end",
  { data_type => "integer", is_nullable => 1 },
  "unigene_match_start",
  { data_type => "integer", is_nullable => 1 },
  "unigene_match_end",
  { data_type => "integer", is_nullable => 1 },
  "e_value",
  { data_type => "double precision", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("primer_unigene_match_id");

=head1 RELATIONS

=head2 unigene

Type: belongs_to

Related object: L<SGN::Schema::Unigene>

=cut

__PACKAGE__->belongs_to(
  "unigene",
  "SGN::Schema::Unigene",
  { unigene_id => "unigene_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 marker

Type: belongs_to

Related object: L<SGN::Schema::Marker>

=cut

__PACKAGE__->belongs_to(
  "marker",
  "SGN::Schema::Marker",
  { marker_id => "marker_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yQIcs4lRRMRUxq4ycH1NUQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
