package SGN::Schema::Est;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("est");
__PACKAGE__->add_columns(
  "est_id",
  {
    data_type => "integer",
    default_value => "nextval('est_est_id_seq'::regclass)",
    is_auto_increment => 1,
    is_nullable => 0,
    size => 4,
  },
  "read_id",
  {
    data_type => "integer",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 4,
  },
  "version",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "basecaller",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 40,
  },
  "seq",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "qscore",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "call_positions",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "status",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "flags",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "date",
  { data_type => "date", default_value => undef, is_nullable => 1, size => 4 },
  "genbank_submission_date",
  { data_type => "date", default_value => undef, is_nullable => 1, size => 4 },
  "genbank_confirmed",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("est_id");
__PACKAGE__->belongs_to(
  "read",
  "SGN::Schema::Seqread",
  { read_id => "read_id" },
  { join_type => "LEFT" },
);
__PACKAGE__->has_many(
  "est_dbxrefs",
  "SGN::Schema::EstDbxref",
  { "foreign.est_id" => "self.est_id" },
);
__PACKAGE__->might_have(
  "qc_report",
  "SGN::Schema::QcReport",
  { "foreign.est_id" => "self.est_id" },
);
__PACKAGE__->has_many(
  "unigene_members",
  "SGN::Schema::UnigeneMember",
  { "foreign.est_id" => "self.est_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04999_07 @ 2009-09-04 13:21:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/9dRnSHAEUwZAT6rU6Fl8Q

sub hqi_seq {
    my ( $self ) = @_;

    if( my $qc = $self->qc_report ) {
        return substr( $self->seq, $qc->hqi_start, $qc->hqi_length );
    } else {
        return $self->seq;
    }
}


# You can replace this text with custom content, and it will be preserved on regeneration
1;
