package SGN::Schema::FamilyBuild;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::FamilyBuild

=cut

__PACKAGE__->table("family_build");

=head1 ACCESSORS

=head2 family_build_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'family_build_family_build_id_seq'

=head2 group_id

  data_type: 'bigint'
  is_nullable: 1

=head2 build_nr

  data_type: 'bigint'
  is_nullable: 1

=head2 i_value

  data_type: 'double precision'
  is_nullable: 1

=head2 build_date

  data_type: 'timestamp'
  default_value: ('now'::text)::timestamp(6) with time zone
  is_nullable: 0

=head2 status

  data_type: 'char'
  default_value: 'C'
  is_nullable: 1
  size: 1

=cut

__PACKAGE__->add_columns(
  "family_build_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "family_build_family_build_id_seq",
  },
  "group_id",
  { data_type => "bigint", is_nullable => 1 },
  "build_nr",
  { data_type => "bigint", is_nullable => 1 },
  "i_value",
  { data_type => "double precision", is_nullable => 1 },
  "build_date",
  {
    data_type     => "timestamp",
    default_value => \"('now'::text)::timestamp(6) with time zone",
    is_nullable   => 0,
  },
  "status",
  { data_type => "char", default_value => "C", is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("family_build_id");

=head1 RELATIONS

=head2 families

Type: has_many

Related object: L<SGN::Schema::Family>

=cut

__PACKAGE__->has_many(
  "families",
  "SGN::Schema::Family",
  { "foreign.family_build_id" => "self.family_build_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QaGnsmu4vvcnLGzPzibWjg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
