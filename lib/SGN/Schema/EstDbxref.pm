package SGN::Schema::EstDbxref;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("est_dbxref");
__PACKAGE__->add_columns(
  "est_dbxref_id",
  {
    data_type => "integer",
    default_value => "nextval('est_dbxref_est_dbxref_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "est_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 4,
  },
  "dbxref_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
);
__PACKAGE__->set_primary_key("est_dbxref_id");
__PACKAGE__->add_unique_constraint("est_dbxref_est_id_key", ["est_id", "dbxref_id"]);
__PACKAGE__->belongs_to("est", "SGN::Schema::Est", { est_id => "est_id" });


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KSmD9wFQDRyRFOJbg0Bvfw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
