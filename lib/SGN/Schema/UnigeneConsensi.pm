package SGN::Schema::UnigeneConsensi;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("unigene_consensi");
__PACKAGE__->add_columns(
  "consensi_id",
  {
    data_type => "integer",
    default_value => "nextval('unigene_consensi_consensi_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "seq",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "qscores",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("consensi_id");
__PACKAGE__->has_many(
  "unigenes",
  "SGN::Schema::Unigene",
  { "foreign.consensi_id" => "self.consensi_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:30PBjtpFcTdZHZq9zZbYVw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
