package SGN::Schema::Sequence;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("sequence");
__PACKAGE__->add_columns(
  "sequence_id",
  {
    data_type => "bigint",
    default_value => "nextval('sequence_sequence_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 8,
  },
  "sequence",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("sequence_id");
__PACKAGE__->add_unique_constraint("sequence_unique", ["sequence"]);
__PACKAGE__->has_many(
  "pcr_experiment_primer_id_fwds",
  "SGN::Schema::PcrExperiment",
  { "foreign.primer_id_fwd" => "self.sequence_id" },
);
__PACKAGE__->has_many(
  "pcr_experiment_primer_id_revs",
  "SGN::Schema::PcrExperiment",
  { "foreign.primer_id_rev" => "self.sequence_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eVs1qu+FGIECyCsPsjlZBg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
