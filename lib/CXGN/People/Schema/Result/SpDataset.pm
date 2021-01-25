use utf8;
package CXGN::People::Schema::Result::SpDataset;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpDataset

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_dataset>

=cut

__PACKAGE__->table("sp_dataset");

=head1 ACCESSORS

=head2 sp_dataset_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_dataset_sp_dataset_id_seq'

=head2 sp_person_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 dataset

  data_type: 'jsonb'
  is_nullable: 1

=head2 is_live

  data_type: 'boolean'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sp_dataset_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_dataset_sp_dataset_id_seq",
  },
  "sp_person_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "dataset",
  { data_type => "jsonb", is_nullable => 1 },
  "is_live",
  { data_type => "boolean", is_nullable => 1 },
  "is_public",
  { data_type => "boolean", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_dataset_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_dataset_id");

=head1 RELATIONS

=head2 sp_person

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpPerson>

=cut

__PACKAGE__->belongs_to(
  "sp_person",
  "CXGN::People::Schema::Result::SpPerson",
  { sp_person_id => "sp_person_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2017-02-20 16:44:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ffdbmCMp1CWSAGkgjm9/bQ

# End of lines loaded from '/home/vagrant/cxgn/cxgn-corelibs/lib/CXGN/People/Schema/Result/SpDataset.pm'

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
