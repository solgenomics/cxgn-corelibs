use utf8;
package CXGN::People::Schema::Result::SpOrganism;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpOrganism

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_organisms>

=cut

__PACKAGE__->table("sp_organisms");

=head1 ACCESSORS

=head2 organism_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_organisms_organism_id_seq'

=head2 organism_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "organism_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_organisms_organism_id_seq",
  },
  "organism_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</organism_id>

=back

=cut

__PACKAGE__->set_primary_key("organism_id");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-26 16:04:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XWDhrXybsJMKOIp19muKlQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
