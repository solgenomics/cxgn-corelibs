package CXGN::SEDM::Schema::TemplatesDbxref;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("templates_dbxref");
__PACKAGE__->add_columns(
  "template_dbxref_id",
  {
    data_type => "bigint",
    default_value => "nextval('sed.templates_dbxref_template_dbxref_id_seq'::regclass)",
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
__PACKAGE__->add_unique_constraint("templates_dbxref_pkey", ["template_dbxref_id"]);
__PACKAGE__->belongs_to(
  "metadata_id",
  "CXGN::SEDM::Schema::Metadata",
  { metadata_id => "metadata_id" },
);
__PACKAGE__->belongs_to(
  "template_id",
  "CXGN::SEDM::Schema::Templates",
  { template_id => "template_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-09-23 18:11:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:82w3ojwrvXB2H0qlUD0KSw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
