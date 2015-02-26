use utf8;
package CXGN::People::Schema::Result::CloneValidationLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::CloneValidationLog

=head1 DESCRIPTION

table showing which clones have been validated by a variety of methods.  columns may be added to this without warning.  details about each validation experiment should be written into the comment field on the detail page for the clone

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<clone_validation_log>

=cut

__PACKAGE__->table("clone_validation_log");

=head1 ACCESSORS

=head2 clone_validation_log_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.clone_validation_log_clone_validation_log_id_seq'

=head2 sp_person_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 clone_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 val_overgo

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 val_bac_ends

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 is_current

  data_type: 'boolean'
  default_value: true
  is_nullable: 1

=head2 created

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "clone_validation_log_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.clone_validation_log_clone_validation_log_id_seq",
  },
  "sp_person_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "clone_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "val_overgo",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "val_bac_ends",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "is_current",
  { data_type => "boolean", default_value => \"true", is_nullable => 1 },
  "created",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
);

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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bgZM1LX8ZJ035h9rDe0B6Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
