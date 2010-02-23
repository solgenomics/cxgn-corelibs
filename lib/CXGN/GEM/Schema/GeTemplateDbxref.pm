package CXGN::GEM::Schema::GeTemplateDbxref;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_template_dbxref");
__PACKAGE__->add_columns(
  "template_dbxref_id",
  {
    data_type => "bigint",
    default_value => "nextval('gem.ge_template_dbxref_template_dbxref_id_seq'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "template_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "dbxref_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("template_dbxref_id");
__PACKAGE__->add_unique_constraint("ge_template_dbxref_pkey", ["template_dbxref_id"]);
__PACKAGE__->belongs_to(
  "template_id",
  "CXGN::GEM::Schema::GeTemplate",
  { template_id => "template_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-02-01 11:35:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:A06SE5Bd768Cjq8QWvUoHA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
