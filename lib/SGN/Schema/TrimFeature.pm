package SGN::Schema::TrimFeature;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::TrimFeature

=cut

__PACKAGE__->table("trim_feature");

=head1 ACCESSORS

=head2 feature_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'trim_feature_feature_id_seq'

=head2 est_id

  data_type: 'integer'
  is_nullable: 1

=head2 start

  data_type: 'bigint'
  is_nullable: 1

=head2 end

  data_type: 'bigint'
  is_nullable: 1

=head2 type

  data_type: 'bigint'
  is_nullable: 1

=head2 value

  data_type: 'bytea'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "feature_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "trim_feature_feature_id_seq",
  },
  "est_id",
  { data_type => "integer", is_nullable => 1 },
  "start",
  { data_type => "bigint", is_nullable => 1 },
  "end",
  { data_type => "bigint", is_nullable => 1 },
  "type",
  { data_type => "bigint", is_nullable => 1 },
  "value",
  { data_type => "bytea", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("feature_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Kf4D6jnlOIcrZeWLnY9jLg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
