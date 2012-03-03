package SGN::Schema::Facility;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Facility

=cut

__PACKAGE__->table("facility");

=head1 ACCESSORS

=head2 facility_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'facility_facility_id_seq'

=head2 submit_user_id

  data_type: 'integer'
  is_nullable: 1

=head2 facility_moniker

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 facility_shortname

  data_type: 'varchar'
  is_nullable: 1
  size: 12

=head2 facility_name

  data_type: 'varchar'
  is_nullable: 1
  size: 80

=head2 facility_contact

  data_type: 'varchar'
  is_nullable: 1
  size: 80

=head2 facility_address

  data_type: 'text'
  is_nullable: 1

=head2 funding_agency

  data_type: 'varchar'
  is_nullable: 1
  size: 80

=head2 funding_comment

  data_type: 'text'
  is_nullable: 1

=head2 sequencing_primers

  data_type: 'varchar'
  is_nullable: 1
  size: 80

=head2 machine

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 chemistry

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 attribution_display

  data_type: 'text'
  is_nullable: 1

=head2 sp_person_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "facility_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "facility_facility_id_seq",
  },
  "submit_user_id",
  { data_type => "integer", is_nullable => 1 },
  "facility_moniker",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "facility_shortname",
  { data_type => "varchar", is_nullable => 1, size => 12 },
  "facility_name",
  { data_type => "varchar", is_nullable => 1, size => 80 },
  "facility_contact",
  { data_type => "varchar", is_nullable => 1, size => 80 },
  "facility_address",
  { data_type => "text", is_nullable => 1 },
  "funding_agency",
  { data_type => "varchar", is_nullable => 1, size => 80 },
  "funding_comment",
  { data_type => "text", is_nullable => 1 },
  "sequencing_primers",
  { data_type => "varchar", is_nullable => 1, size => 80 },
  "machine",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "chemistry",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "attribution_display",
  { data_type => "text", is_nullable => 1 },
  "sp_person_id",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("facility_id");

=head1 RELATIONS

=head2 seqreads

Type: has_many

Related object: L<SGN::Schema::Seqread>

=cut

__PACKAGE__->has_many(
  "seqreads",
  "SGN::Schema::Seqread",
  { "foreign.facility_id" => "self.facility_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XLirPpQidO8sVoh61D2sjg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
