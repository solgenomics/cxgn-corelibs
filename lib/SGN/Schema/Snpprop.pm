package SGN::Schema::Snpprop;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Snpprop

=cut

__PACKAGE__->table("snpprop");

=head1 ACCESSORS

=head2 snpprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn.snpprop_snpprop_id_seq'

=head2 snp_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 value

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 rank

  data_type: 'integer'
  is_nullable: 1

=head2 type_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "snpprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn.snpprop_snpprop_id_seq",
  },
  "snp_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "value",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "rank",
  { data_type => "integer", is_nullable => 1 },
  "type_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("snpprop_id");

=head1 RELATIONS

=head2 snp

Type: belongs_to

Related object: L<SGN::Schema::Snp>

=cut

__PACKAGE__->belongs_to(
  "snp",
  "SGN::Schema::Snp",
  { snp_id => "snp_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GGWqOxLl9yAsP+lY6vtD6A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
