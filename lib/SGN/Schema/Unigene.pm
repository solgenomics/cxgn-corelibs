package SGN::Schema::Unigene;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("unigene");
__PACKAGE__->add_columns(
  "unigene_id",
  {
    data_type => "integer",
    default_value => "nextval('unigene_unigene_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "unigene_build_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "consensi_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "cluster_no",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "contig_no",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "nr_members",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "database_name",
  {
    data_type => "character varying",
    default_value => "'SGN'::character varying",
    is_nullable => 0,
    size => undef,
  },
  "sequence_name",
  { data_type => "bigint", default_value => undef, is_nullable => 0, size => 8 },
);
__PACKAGE__->set_primary_key("unigene_id");
__PACKAGE__->has_many(
  "blast_annotations",
  "SGN::Schema::BlastAnnotation",
  { "foreign.apply_id" => "self.unigene_id" },
);
__PACKAGE__->has_many(
  "cds",
  "SGN::Schema::Cd",
  { "foreign.unigene_id" => "self.unigene_id" },
);
__PACKAGE__->has_many(
  "primer_unigene_matches",
  "SGN::Schema::PrimerUnigeneMatch",
  { "foreign.unigene_id" => "self.unigene_id" },
);
__PACKAGE__->has_many(
  "rflp_unigene_associations",
  "SGN::Schema::RflpUnigeneAssociation",
  { "foreign.unigene_id" => "self.unigene_id" },
);
__PACKAGE__->has_many(
  "ssr_primer_unigene_matches",
  "SGN::Schema::SsrPrimerUnigeneMatch",
  { "foreign.unigene_id" => "self.unigene_id" },
);
__PACKAGE__->belongs_to(
  "consensi",
  "SGN::Schema::UnigeneConsensi",
  { consensi_id => "consensi_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->belongs_to(
  "unigene_build",
  "SGN::Schema::UnigeneBuild",
  { unigene_build_id => "unigene_build_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->has_many(
  "unigene_members",
  "SGN::Schema::UnigeneMember",
  { "foreign.unigene_id" => "self.unigene_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/WBLY/XERG0gUSp/aJJTvw

use Carp ();

sub seq {
    my ($self) = @_;

    if( $self->nr_members > 1 ) {
        return $self->consensi->seq;
    } elsif( $self->nr_members == 1 ) {
        return $self->unigene_members->single->est->hqi_seq;
    } else {
        Carp::confess( 'unigene SGN-U'.$self->unigene_id.' has invalid nr_members ('.$self->nr_members.')' );
    }
}


# You can replace this text with custom content, and it will be preserved on regeneration
1;
