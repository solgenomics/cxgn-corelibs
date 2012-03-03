package SGN::Schema::Seqread;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Seqread

=cut

__PACKAGE__->table("seqread");

=head1 ACCESSORS

=head2 read_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'seqread_read_id_seq'

=head2 clone_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 facility_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 submitter_id

  data_type: 'integer'
  is_nullable: 1

=head2 batch_id

  data_type: 'integer'
  is_nullable: 1

=head2 primer

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 direction

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 trace_name

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 trace_location

  data_type: 'text'
  is_nullable: 1

=head2 attribution_id

  data_type: 'integer'
  is_nullable: 1

=head2 date

  data_type: 'timestamp'
  default_value: ('now'::text)::timestamp(6) with time zone
  is_nullable: 0

=head2 censor_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "read_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "seqread_read_id_seq",
  },
  "clone_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "facility_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "submitter_id",
  { data_type => "integer", is_nullable => 1 },
  "batch_id",
  { data_type => "integer", is_nullable => 1 },
  "primer",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "direction",
  { data_type => "char", is_nullable => 1, size => 1 },
  "trace_name",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "trace_location",
  { data_type => "text", is_nullable => 1 },
  "attribution_id",
  { data_type => "integer", is_nullable => 1 },
  "date",
  {
    data_type     => "timestamp",
    default_value => \"('now'::text)::timestamp(6) with time zone",
    is_nullable   => 0,
  },
  "censor_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("read_id");

=head1 RELATIONS

=head2 ests

Type: has_many

Related object: L<SGN::Schema::Est>

=cut

__PACKAGE__->has_many(
  "ests",
  "SGN::Schema::Est",
  { "foreign.read_id" => "self.read_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 clone

Type: belongs_to

Related object: L<SGN::Schema::Clone>

=cut

__PACKAGE__->belongs_to(
  "clone",
  "SGN::Schema::Clone",
  { clone_id => "clone_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 facility

Type: belongs_to

Related object: L<SGN::Schema::Facility>

=cut

__PACKAGE__->belongs_to(
  "facility",
  "SGN::Schema::Facility",
  { facility_id => "facility_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hwCjt/hB/1BG2Uor6qL/tA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
