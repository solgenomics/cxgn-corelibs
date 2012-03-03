package SGN::Schema::PMarker;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::PMarker

=cut

__PACKAGE__->table("p_markers");

=head1 ACCESSORS

=head2 pid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'p_markers_pid_seq'

=head2 marker_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 est_clone_id

  data_type: 'bigint'
  default_value: '0)::bigint'
  is_nullable: 0

=head2 p_mrkr_name

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "pid",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "p_markers_pid_seq",
  },
  "marker_id",
  {
    data_type      => "bigint",
    default_value  => "0)::bigint",
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "est_clone_id",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "p_mrkr_name",
  { data_type => "varchar", is_nullable => 1, size => 32 },
);
__PACKAGE__->set_primary_key("pid");

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


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LWa69DPqnjvcUKQ9kGXTnw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
