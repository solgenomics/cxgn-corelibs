package SGN::Schema::EnzymeRestrictionSite;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

SGN::Schema::EnzymeRestrictionSite

=cut

__PACKAGE__->table("enzyme_restriction_sites");

=head1 ACCESSORS

=head2 enzyme_id

  data_type: 'integer'
  is_nullable: 1

=head2 restriction_site

  data_type: 'text'
  is_nullable: 1

=head2 enzyme_restriction_sites_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'enzyme_restriction_sites_enzyme_restriction_sites_id_seq'

=cut

__PACKAGE__->add_columns(
  "enzyme_id",
  { data_type => "integer", is_nullable => 1 },
  "restriction_site",
  { data_type => "text", is_nullable => 1 },
  "enzyme_restriction_sites_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "enzyme_restriction_sites_enzyme_restriction_sites_id_seq",
  },
);
__PACKAGE__->set_primary_key("enzyme_restriction_sites_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:35:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SYxEfX3A5/LD9KaY5DERug


# You can replace this text with custom content, and it will be preserved on regeneration
1;
