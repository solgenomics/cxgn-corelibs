package SGN::Schema::MarkerAlias;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::MarkerAlias

=cut

__PACKAGE__->table("marker_alias");

=head1 ACCESSORS

=head2 alias_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'marker_alias_alias_id_seq'

=head2 alias

  data_type: 'text'
  is_nullable: 0

=head2 marker_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 preferred

  data_type: 'boolean'
  default_value: true
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "alias_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "marker_alias_alias_id_seq",
  },
  "alias",
  { data_type => "text", is_nullable => 0 },
  "marker_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "preferred",
  { data_type => "boolean", default_value => \"true", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("alias_id");
__PACKAGE__->add_unique_constraint("marker_alias_alias_key", ["alias"]);

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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:E+03TkLOicO7zNp3CmApfA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
