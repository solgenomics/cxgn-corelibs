package SGN::Schema::UnigeneConsensi;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::UnigeneConsensi

=cut

__PACKAGE__->table("unigene_consensi");

=head1 ACCESSORS

=head2 consensi_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'unigene_consensi_consensi_id_seq'

=head2 seq

  data_type: 'text'
  is_nullable: 1

=head2 qscores

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "consensi_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "unigene_consensi_consensi_id_seq",
  },
  "seq",
  { data_type => "text", is_nullable => 1 },
  "qscores",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("consensi_id");

=head1 RELATIONS

=head2 unigenes

Type: has_many

Related object: L<SGN::Schema::Unigene>

=cut

__PACKAGE__->has_many(
  "unigenes",
  "SGN::Schema::Unigene",
  { "foreign.consensi_id" => "self.consensi_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uXwmz0s7eNMeVns4gDuI6Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
