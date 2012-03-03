package SGN::Schema::FishExperimenter;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::FishExperimenter

=cut

__PACKAGE__->table("fish_experimenter");

=head1 ACCESSORS

=head2 fish_experimenter_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'fish_experimenter_fish_experimenter_id_seq'

=head2 fish_experimenter_name

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=cut

__PACKAGE__->add_columns(
  "fish_experimenter_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "fish_experimenter_fish_experimenter_id_seq",
  },
  "fish_experimenter_name",
  { data_type => "varchar", is_nullable => 1, size => 20 },
);
__PACKAGE__->set_primary_key("fish_experimenter_id");
__PACKAGE__->add_unique_constraint("fish_expermenter_name_uniq", ["fish_experimenter_name"]);

=head1 RELATIONS

=head2 fish_results

Type: has_many

Related object: L<SGN::Schema::FishResult>

=cut

__PACKAGE__->has_many(
  "fish_results",
  "SGN::Schema::FishResult",
  { "foreign.fish_experimenter_id" => "self.fish_experimenter_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HqAPxapG9dVDcUi2WIPIWA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
