package SGN::Schema::RflpUnigeneAssociation;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("rflp_unigene_associations");
__PACKAGE__->add_columns(
  "rflp_unigene_assoc_id",
  {
    data_type => "integer",
    default_value => "nextval('rflp_unigene_associations_rflp_unigene_assoc_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "rflp_seq_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "unigene_id",
  {
    data_type => "bigint",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "e_val",
  {
    data_type => "double precision",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "align_length",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "query_start",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "query_end",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("rflp_unigene_assoc_id");
__PACKAGE__->belongs_to(
  "unigene",
  "SGN::Schema::Unigene",
  { unigene_id => "unigene_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "rflp_seq",
  "SGN::Schema::RflpSequence",
  { seq_id => "rflp_seq_id" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cti2ZvC/TzakSCOwWT0bpA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
