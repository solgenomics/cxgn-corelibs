package SGN::Schema::Facility;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("facility");
__PACKAGE__->add_columns(
  "facility_id",
  {
    data_type => "integer",
    default_value => "nextval('facility_facility_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "submit_user_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "facility_moniker",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
  "facility_shortname",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 12,
  },
  "facility_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "facility_contact",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "facility_address",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "funding_agency",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "funding_comment",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "sequencing_primers",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 80,
  },
  "machine",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 40,
  },
  "chemistry",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 40,
  },
  "attribution_display",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "sp_person_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("facility_id");
__PACKAGE__->has_many(
  "seqreads",
  "SGN::Schema::Seqread",
  { "foreign.facility_id" => "self.facility_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:T/2zUyjpP6CvfX69ixSiuQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
