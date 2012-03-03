package SGN::Schema::EstDbxref;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::EstDbxref

=cut

__PACKAGE__->table("est_dbxref");

=head1 ACCESSORS

=head2 est_dbxref_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'est_dbxref_est_dbxref_id_seq'

=head2 est_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 dbxref_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "est_dbxref_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "est_dbxref_est_dbxref_id_seq",
  },
  "est_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "dbxref_id",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("est_dbxref_id");
__PACKAGE__->add_unique_constraint("est_dbxref_est_id_key", ["est_id", "dbxref_id"]);

=head1 RELATIONS

=head2 est

Type: belongs_to

Related object: L<SGN::Schema::Est>

=cut

__PACKAGE__->belongs_to(
  "est",
  "SGN::Schema::Est",
  { est_id => "est_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yyhJ86bEnQ+gyZW2jwkD6A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
