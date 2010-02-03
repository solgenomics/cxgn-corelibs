package SGN::Schema::Marker;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("marker");
__PACKAGE__->add_columns(
  "marker_id",
  {
    data_type => "integer",
    default_value => "nextval('marker_marker_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "dummy_field",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("marker_id");
__PACKAGE__->has_many(
  "cosii_orthologs",
  "SGN::Schema::CosiiOrtholog",
  { "foreign.marker_id" => "self.marker_id" },
);
__PACKAGE__->has_many(
  "cos_markers",
  "SGN::Schema::CosMarker",
  { "foreign.marker_id" => "self.marker_id" },
);
__PACKAGE__->has_many(
  "ests_mapped_by_clones",
  "SGN::Schema::EstsMappedByClone",
  { "foreign.marker_id" => "self.marker_id" },
);
__PACKAGE__->has_many(
  "marker_alias",
  "SGN::Schema::MarkerAlia",
  { "foreign.marker_id" => "self.marker_id" },
);
__PACKAGE__->has_many(
  "marker_collectibles",
  "SGN::Schema::MarkerCollectible",
  { "foreign.marker_id" => "self.marker_id" },
);
__PACKAGE__->has_many(
  "marker_experiments",
  "SGN::Schema::MarkerExperiment",
  { "foreign.marker_id" => "self.marker_id" },
);
__PACKAGE__->has_many(
  "pcr_experiments",
  "SGN::Schema::PcrExperiment",
  { "foreign.marker_id" => "self.marker_id" },
);
__PACKAGE__->has_many(
  "p_markers",
  "SGN::Schema::PMarker",
  { "foreign.marker_id" => "self.marker_id" },
);
__PACKAGE__->has_many(
  "primer_unigene_matches",
  "SGN::Schema::PrimerUnigeneMatch",
  { "foreign.marker_id" => "self.marker_id" },
);
__PACKAGE__->has_many(
  "rflp_markers",
  "SGN::Schema::RflpMarker",
  { "foreign.marker_id" => "self.marker_id" },
);
__PACKAGE__->has_many(
  "ssrs",
  "SGN::Schema::Ssr",
  { "foreign.marker_id" => "self.marker_id" },
);
__PACKAGE__->has_many(
  "ssr_repeats",
  "SGN::Schema::SsrRepeat",
  { "foreign.marker_id" => "self.marker_id" },
);
__PACKAGE__->has_many(
  "tm_markers",
  "SGN::Schema::TmMarker",
  { "foreign.marker_id" => "self.marker_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:V5P7TW1z/mtDGvIGRG0rfw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
