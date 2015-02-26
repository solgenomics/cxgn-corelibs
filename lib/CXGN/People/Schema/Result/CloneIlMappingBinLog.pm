use utf8;
package CXGN::People::Schema::Result::CloneIlMappingBinLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::CloneIlMappingBinLog

=head1 DESCRIPTION

linking table showing which phenome.genotype_region a given clone has been mapped to. also provides a modification history with its is_current and created columns

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<clone_il_mapping_bin_log>

=cut

__PACKAGE__->table("clone_il_mapping_bin_log");

=head1 ACCESSORS

=head2 sp_clone_il_mapping_bin_log_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.clone_il_mapping_bin_log_sp_clone_il_mapping_bin_log_id_seq'

=head2 genotype_region_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 sp_person_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 clone_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 is_current

  data_type: 'boolean'
  default_value: true
  is_nullable: 1

=head2 created

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 chromosome

  data_type: 'integer'
  is_nullable: 1

=head2 notes

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "sp_clone_il_mapping_bin_log_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.clone_il_mapping_bin_log_sp_clone_il_mapping_bin_log_id_seq",
  },
  "genotype_region_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "sp_person_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "clone_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "is_current",
  { data_type => "boolean", default_value => \"true", is_nullable => 1 },
  "created",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "chromosome",
  { data_type => "integer", is_nullable => 1 },
  "notes",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_clone_il_mapping_bin_log_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_clone_il_mapping_bin_log_id");

=head1 RELATIONS

=head2 sp_person

Type: belongs_to

Related object: L<CXGN::People::Schema::Result::SpPerson>

=cut

__PACKAGE__->belongs_to(
  "sp_person",
  "CXGN::People::Schema::Result::SpPerson",
  { sp_person_id => "sp_person_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-26 16:04:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LlEEz6075aM6u+SLFl9QwA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
