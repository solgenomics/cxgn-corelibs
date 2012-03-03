package SGN::Schema::CommonNameprop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::CommonNameprop

=cut

__PACKAGE__->table("common_nameprop");

=head1 ACCESSORS

=head2 common_nameprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'organismprop_organismprop_id_seq'

=head2 common_name_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_nullable: 0

=head2 value

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "common_nameprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "organismprop_organismprop_id_seq",
  },
  "common_name_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_nullable => 0 },
  "value",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("common_nameprop_id");

=head1 RELATIONS

=head2 common_name

Type: belongs_to

Related object: L<SGN::Schema::CommonName>

=cut

__PACKAGE__->belongs_to(
  "common_name",
  "SGN::Schema::CommonName",
  { common_name_id => "common_name_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BuIRBz+5C+oT0LP0u7coNg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
