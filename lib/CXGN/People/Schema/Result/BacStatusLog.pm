use utf8;
package CXGN::People::Schema::Result::BacStatusLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::BacStatusLog

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<bac_status_log>

=cut

__PACKAGE__->table("bac_status_log");

=head1 ACCESSORS

=head2 bac_status_log_id

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.bac_status_log_bac_status_log_id_seq'

=head2 bac_id

  data_type: 'bigint'
  is_nullable: 1

=head2 person_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 status

  data_type: 'varchar'
  is_nullable: 1
  size: 13

=head2 genbank_status

  data_type: 'varchar'
  is_nullable: 1
  size: 5

=head2 timestamp

  data_type: 'timestamp'
  default_value: ('now'::text)::timestamp(6) with time zone
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "bac_status_log_id",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.bac_status_log_bac_status_log_id_seq",
  },
  "bac_id",
  { data_type => "bigint", is_nullable => 1 },
  "person_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 13 },
  "genbank_status",
  { data_type => "varchar", is_nullable => 1, size => 5 },
  "timestamp",
  {
    data_type     => "timestamp",
    default_value => \"('now'::text)::timestamp(6) with time zone",
    is_nullable   => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</bac_status_log_id>

=back

=cut

__PACKAGE__->set_primary_key("bac_status_log_id");

=head1 RELATIONS

=head2 person

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpPerson>

=cut

__PACKAGE__->belongs_to(
  "person",
  "CXGN::People::Schema::Result::SpPerson",
  { sp_person_id => "person_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-26 16:04:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dHCmNell4vi9kXk1F7s9Gw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
