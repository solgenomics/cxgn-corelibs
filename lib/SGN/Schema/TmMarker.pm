package SGN::Schema::TmMarker;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::TmMarker

=cut

__PACKAGE__->table("tm_markers");

=head1 ACCESSORS

=head2 tm_id

  data_type: 'integer'
  is_auto_increment: 1
  is_foreign_key: 1
  is_nullable: 0
  sequence: 'tm_markers_tm_id_seq'

=head2 marker_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 tm_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 32

=head2 old_cos_id

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 seq_id

  data_type: 'bigint'
  is_nullable: 1

=head2 est_read_id

  data_type: 'bigint'
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "tm_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_foreign_key    => 1,
    is_nullable       => 0,
    sequence          => "tm_markers_tm_id_seq",
  },
  "marker_id",
  {
    data_type      => "bigint",
    default_value  => "0)::bigint",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "tm_name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 32 },
  "old_cos_id",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "seq_id",
  { data_type => "bigint", is_nullable => 1 },
  "est_read_id",
  { data_type => "bigint", is_nullable => 1 },
  "comment",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("tm_id");

=head1 RELATIONS

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

=head2 tm

Type: belongs_to

Related object: L<SGN::Schema::TmMarker>

=cut

__PACKAGE__->belongs_to(
  "tm",
  "SGN::Schema::TmMarker",
  { tm_id => "tm_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 tm_marker

Type: might_have

Related object: L<SGN::Schema::TmMarker>

=cut

__PACKAGE__->might_have(
  "tm_marker",
  "SGN::Schema::TmMarker",
  { "foreign.tm_id" => "self.tm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BU0F27X8KB5C22+IezQUxA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
