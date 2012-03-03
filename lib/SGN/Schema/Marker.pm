package SGN::Schema::Marker;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::Marker

=cut

__PACKAGE__->table("marker");

=head1 ACCESSORS

=head2 marker_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'marker_marker_id_seq'

=head2 dummy_field

  data_type: 'boolean'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "marker_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "marker_marker_id_seq",
  },
  "dummy_field",
  { data_type => "boolean", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("marker_id");

=head1 RELATIONS

=head2 cosii_orthologs

Type: has_many

Related object: L<SGN::Schema::CosiiOrtholog>

=cut

__PACKAGE__->has_many(
  "cosii_orthologs",
  "SGN::Schema::CosiiOrtholog",
  { "foreign.marker_id" => "self.marker_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cos_markers

Type: has_many

Related object: L<SGN::Schema::CosMarker>

=cut

__PACKAGE__->has_many(
  "cos_markers",
  "SGN::Schema::CosMarker",
  { "foreign.marker_id" => "self.marker_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ests_mapped_by_clone

Type: has_many

Related object: L<SGN::Schema::EstMappedByClone>

=cut

__PACKAGE__->has_many(
  "ests_mapped_by_clone",
  "SGN::Schema::EstMappedByClone",
  { "foreign.marker_id" => "self.marker_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 marker_aliases

Type: has_many

Related object: L<SGN::Schema::MarkerAlias>

=cut

__PACKAGE__->has_many(
  "marker_aliases",
  "SGN::Schema::MarkerAlias",
  { "foreign.marker_id" => "self.marker_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 marker_collectibles

Type: has_many

Related object: L<SGN::Schema::MarkerCollectible>

=cut

__PACKAGE__->has_many(
  "marker_collectibles",
  "SGN::Schema::MarkerCollectible",
  { "foreign.marker_id" => "self.marker_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 marker_experiments

Type: has_many

Related object: L<SGN::Schema::MarkerExperiment>

=cut

__PACKAGE__->has_many(
  "marker_experiments",
  "SGN::Schema::MarkerExperiment",
  { "foreign.marker_id" => "self.marker_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pcr_experiments

Type: has_many

Related object: L<SGN::Schema::PcrExperiment>

=cut

__PACKAGE__->has_many(
  "pcr_experiments",
  "SGN::Schema::PcrExperiment",
  { "foreign.marker_id" => "self.marker_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 p_markers

Type: has_many

Related object: L<SGN::Schema::PMarker>

=cut

__PACKAGE__->has_many(
  "p_markers",
  "SGN::Schema::PMarker",
  { "foreign.marker_id" => "self.marker_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 primer_unigene_matches

Type: has_many

Related object: L<SGN::Schema::PrimerUnigeneMatch>

=cut

__PACKAGE__->has_many(
  "primer_unigene_matches",
  "SGN::Schema::PrimerUnigeneMatch",
  { "foreign.marker_id" => "self.marker_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 rflp_markers

Type: has_many

Related object: L<SGN::Schema::RflpMarker>

=cut

__PACKAGE__->has_many(
  "rflp_markers",
  "SGN::Schema::RflpMarker",
  { "foreign.marker_id" => "self.marker_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 snps

Type: has_many

Related object: L<SGN::Schema::Snp>

=cut

__PACKAGE__->has_many(
  "snps",
  "SGN::Schema::Snp",
  { "foreign.marker_id" => "self.marker_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ssrs

Type: has_many

Related object: L<SGN::Schema::Ssr>

=cut

__PACKAGE__->has_many(
  "ssrs",
  "SGN::Schema::Ssr",
  { "foreign.marker_id" => "self.marker_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ssr_repeats

Type: has_many

Related object: L<SGN::Schema::SsrRepeat>

=cut

__PACKAGE__->has_many(
  "ssr_repeats",
  "SGN::Schema::SsrRepeat",
  { "foreign.marker_id" => "self.marker_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 tm_markers

Type: has_many

Related object: L<SGN::Schema::TmMarker>

=cut

__PACKAGE__->has_many(
  "tm_markers",
  "SGN::Schema::TmMarker",
  { "foreign.marker_id" => "self.marker_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TcM/fzk1Rzekob/ZX5Q3pg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
