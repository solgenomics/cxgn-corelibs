package SGN::Schema::Clone;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Clone

=cut

__PACKAGE__->table("clone");

=head1 ACCESSORS

=head2 clone_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'clone_clone_id_seq'

=head2 library_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 clone_name

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 clone_group_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "clone_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "clone_clone_id_seq",
  },
  "library_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "clone_name",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "clone_group_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("clone_id");
__PACKAGE__->add_unique_constraint("clone_name_library_id_unique", ["clone_name", "library_id"]);
__PACKAGE__->add_unique_constraint("library_id_clone_name_key", ["library_id", "clone_name"]);

=head1 RELATIONS

=head2 library

Type: belongs_to

Related object: L<SGN::Schema::Library>

=cut

__PACKAGE__->belongs_to(
  "library",
  "SGN::Schema::Library",
  { library_id => "library_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 seqreads

Type: has_many

Related object: L<SGN::Schema::Seqread>

=cut

__PACKAGE__->has_many(
  "seqreads",
  "SGN::Schema::Seqread",
  { "foreign.clone_id" => "self.clone_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qHcI1QlJSTctgHcs6FedCg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
