package SGN::Schema::TrimFeatureType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::TrimFeatureType

=cut

__PACKAGE__->table("trim_feature_types");

=head1 ACCESSORS

=head2 trim_type_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'trim_feature_types_trim_type_id_seq'

=head2 comment

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "trim_type_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "trim_feature_types_trim_type_id_seq",
  },
  "comment",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("trim_type_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wd2zH99Ru0tHfHcUEC1ZiQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
