package SGN::Schema::EnzymeRestrictionSite;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("enzyme_restriction_sites");
__PACKAGE__->add_columns(
  "enzyme_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "restriction_site",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "enzyme_restriction_sites_id",
  {
    data_type => "integer",
    default_value => "nextval('enzyme_restriction_sites_enzyme_restriction_sites_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
);
__PACKAGE__->set_primary_key("enzyme_restriction_sites_id");


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NCE8PNR5UyuHqK/wsXFMHw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
