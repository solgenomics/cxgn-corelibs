package SGN::Schema::IdLinkage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::IdLinkage

=cut

__PACKAGE__->table("id_linkage");

=head1 ACCESSORS

=head2 id_linkage_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'id_linkage_id_linkage_id_seq'

=head2 link_id

  data_type: 'varchar'
  is_nullable: 1
  size: 80

=head2 link_id_type

  data_type: 'integer'
  is_nullable: 1

=head2 internal_id

  data_type: 'integer'
  is_nullable: 1

=head2 internal_id_type

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id_linkage_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "id_linkage_id_linkage_id_seq",
  },
  "link_id",
  { data_type => "varchar", is_nullable => 1, size => 80 },
  "link_id_type",
  { data_type => "integer", is_nullable => 1 },
  "internal_id",
  { data_type => "integer", is_nullable => 1 },
  "internal_id_type",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id_linkage_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3lxwVVcsl6z0eWnMu9HAZQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
