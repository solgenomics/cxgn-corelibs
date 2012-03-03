package SGN::Schema::CommonName;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::CommonName

=cut

__PACKAGE__->table("common_name");

=head1 ACCESSORS

=head2 common_name_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'common_name_common_name_id_seq'

=head2 common_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "common_name_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "common_name_common_name_id_seq",
  },
  "common_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("common_name_id");
__PACKAGE__->add_unique_constraint("common_name_unique", ["common_name"]);

=head1 RELATIONS

=head2 common_nameprops

Type: has_many

Related object: L<SGN::Schema::CommonNameprop>

=cut

__PACKAGE__->has_many(
  "common_nameprops",
  "SGN::Schema::CommonNameprop",
  { "foreign.common_name_id" => "self.common_name_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organisms

Type: has_many

Related object: L<SGN::Schema::Organism>

=cut

__PACKAGE__->has_many(
  "organisms",
  "SGN::Schema::Organism",
  { "foreign.common_name_id" => "self.common_name_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OZwtKEhvlAoHbT+X5USNAA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
