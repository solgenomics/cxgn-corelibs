package SGN::Schema::MarkerDerivedFrom;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::MarkerDerivedFrom

=cut

__PACKAGE__->table("marker_derived_from");

=head1 ACCESSORS

=head2 marker_derived_dummy_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'marker_derived_from_marker_derived_dummy_id_seq'

=head2 marker_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 derived_from_source_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 id_in_source

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "marker_derived_dummy_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "marker_derived_from_marker_derived_dummy_id_seq",
  },
  "marker_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "derived_from_source_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "id_in_source",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("marker_derived_dummy_id");

=head1 RELATIONS

=head2 derived_from_source

Type: belongs_to

Related object: L<SGN::Schema::DerivedFromSource>

=cut

__PACKAGE__->belongs_to(
  "derived_from_source",
  "SGN::Schema::DerivedFromSource",
  { "derived_from_source_id" => "derived_from_source_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 marker

Type: belongs_to

Related object: L<SGN::Schema::DeprecatedMarker>

=cut

__PACKAGE__->belongs_to(
  "marker",
  "SGN::Schema::DeprecatedMarker",
  { marker_id => "marker_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:V85eQuoqWZtVfXXxk2r19g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
