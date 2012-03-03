package SGN::Schema::EstMappedByClone;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::EstMappedByClone

=cut

__PACKAGE__->table("ests_mapped_by_clone");

=head1 ACCESSORS

=head2 embc_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'ests_mapped_by_clone_embc_id_seq'

=head2 marker_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 clone_id

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "embc_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "ests_mapped_by_clone_embc_id_seq",
  },
  "marker_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "clone_id",
  { data_type => "bigint", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("embc_id");

=head1 RELATIONS

=head2 marker

Type: belongs_to

Related object: L<SGN::Schema::Marker>

=cut

__PACKAGE__->belongs_to(
  "marker",
  "SGN::Schema::Marker",
  { marker_id => "marker_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PC0s36N6gQ0VsLP00ZBreQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
