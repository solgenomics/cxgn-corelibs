package SGN::Schema::ManualCensorReason;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::ManualCensorReason

=cut

__PACKAGE__->table("manual_censor_reasons");

=head1 ACCESSORS

=head2 censor_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'manual_censor_reasons_censor_id_seq'

=head2 reason

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "censor_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "manual_censor_reasons_censor_id_seq",
  },
  "reason",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("censor_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Q79FT+pen42efio+jHsBHQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
