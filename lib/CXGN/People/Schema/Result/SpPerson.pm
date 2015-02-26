use utf8;
package CXGN::People::Schema::Result::SpPerson;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::People::Schema::Result::SpPerson

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sp_person>

=cut

__PACKAGE__->table("sp_person");

=head1 ACCESSORS

=head2 sp_person_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'sgn_people.sp_person_sp_person_id_seq'

=head2 censor

  data_type: 'bigint'
  default_value: 0
  is_nullable: 1

=head2 salutation

  data_type: 'varchar'
  is_nullable: 1
  size: 8

=head2 last_name

  data_type: 'varchar'
  is_nullable: 1
  size: 63

=head2 first_name

  data_type: 'varchar'
  is_nullable: 1
  size: 63

=head2 organization

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 address

  data_type: 'text'
  is_nullable: 1

=head2 country

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 phone_number

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 fax

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 contact_email

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 webpage

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 research_keywords

  data_type: 'text'
  is_nullable: 1

=head2 user_format

  data_type: 'varchar'
  is_nullable: 1
  size: 8

=head2 research_interests

  data_type: 'text'
  is_nullable: 1

=head2 formatted_interests

  data_type: 'text'
  is_nullable: 1

=head2 contact_update

  data_type: 'date'
  is_nullable: 1

=head2 research_update

  data_type: 'date'
  is_nullable: 1

=head2 sp_login_id

  data_type: 'bigint'
  is_nullable: 1

=head2 username

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 private_email

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 pending_email

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 password

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 confirm_code

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 disabled

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 user_type

  data_type: 'varchar'
  default_value: 'user'
  is_nullable: 1
  size: 20

=head2 cookie_string

  data_type: 'text'
  is_nullable: 1

=head2 last_access_time

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 user_prefs

  data_type: 'varchar'
  is_nullable: 1
  size: 4096

=head2 developer_settings

  data_type: 'varchar'
  is_nullable: 1
  size: 4096

=cut

__PACKAGE__->add_columns(
  "sp_person_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_person_sp_person_id_seq",
  },
  "censor",
  { data_type => "bigint", default_value => 0, is_nullable => 1 },
  "salutation",
  { data_type => "varchar", is_nullable => 1, size => 8 },
  "last_name",
  { data_type => "varchar", is_nullable => 1, size => 63 },
  "first_name",
  { data_type => "varchar", is_nullable => 1, size => 63 },
  "organization",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "address",
  { data_type => "text", is_nullable => 1 },
  "country",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "phone_number",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "fax",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "contact_email",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "webpage",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "research_keywords",
  { data_type => "text", is_nullable => 1 },
  "user_format",
  { data_type => "varchar", is_nullable => 1, size => 8 },
  "research_interests",
  { data_type => "text", is_nullable => 1 },
  "formatted_interests",
  { data_type => "text", is_nullable => 1 },
  "contact_update",
  { data_type => "date", is_nullable => 1 },
  "research_update",
  { data_type => "date", is_nullable => 1 },
  "sp_login_id",
  { data_type => "bigint", is_nullable => 1 },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "private_email",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pending_email",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "password",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "confirm_code",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "disabled",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "user_type",
  {
    data_type => "varchar",
    default_value => "user",
    is_nullable => 1,
    size => 20,
  },
  "cookie_string",
  { data_type => "text", is_nullable => 1 },
  "last_access_time",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "user_prefs",
  { data_type => "varchar", is_nullable => 1, size => 4096 },
  "developer_settings",
  { data_type => "varchar", is_nullable => 1, size => 4096 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sp_person_id>

=back

=cut

__PACKAGE__->set_primary_key("sp_person_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<cookie_string_unique>

=over 4

=item * L</cookie_string>

=back

=cut

__PACKAGE__->add_unique_constraint("cookie_string_unique", ["cookie_string"]);

=head2 C<sp_person_username_key>

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->add_unique_constraint("sp_person_username_key", ["username"]);

=head1 RELATIONS

=head2 bac_status_logs

Type: has_many

Related object: L<CXGN::People::Schema::Result::BacStatusLog>

=cut

__PACKAGE__->has_many(
  "bac_status_logs",
  "CXGN::People::Schema::Result::BacStatusLog",
  { "foreign.person_id" => "self.sp_person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 bac_statuses

Type: has_many

Related object: L<CXGN::People::Schema::Result::BacStatus>

=cut

__PACKAGE__->has_many(
  "bac_statuses",
  "CXGN::People::Schema::Result::BacStatus",
  { "foreign.person_id" => "self.sp_person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 clone_il_mapping_bin_logs

Type: has_many

Related object: L<CXGN::People::Schema::Result::CloneIlMappingBinLog>

=cut

__PACKAGE__->has_many(
  "clone_il_mapping_bin_logs",
  "CXGN::People::Schema::Result::CloneIlMappingBinLog",
  { "foreign.sp_person_id" => "self.sp_person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 clone_validation_logs

Type: has_many

Related object: L<CXGN::People::Schema::Result::CloneValidationLog>

=cut

__PACKAGE__->has_many(
  "clone_validation_logs",
  "CXGN::People::Schema::Result::CloneValidationLog",
  { "foreign.sp_person_id" => "self.sp_person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 clone_verification_logs

Type: has_many

Related object: L<CXGN::People::Schema::Result::CloneVerificationLog>

=cut

__PACKAGE__->has_many(
  "clone_verification_logs",
  "CXGN::People::Schema::Result::CloneVerificationLog",
  { "foreign.sp_person_id" => "self.sp_person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 forum_posts

Type: has_many

Related object: L<CXGN::People::Schema::Result::ForumPost>

=cut

__PACKAGE__->has_many(
  "forum_posts",
  "CXGN::People::Schema::Result::ForumPost",
  { "foreign.person_id" => "self.sp_person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 forum_topics

Type: has_many

Related object: L<CXGN::People::Schema::Result::ForumTopic>

=cut

__PACKAGE__->has_many(
  "forum_topics",
  "CXGN::People::Schema::Result::ForumTopic",
  { "foreign.person_id" => "self.sp_person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 lists

Type: has_many

Related object: L<CXGN::People::Schema::Result::List>

=cut

__PACKAGE__->has_many(
  "lists",
  "CXGN::People::Schema::Result::List",
  { "foreign.owner" => "self.sp_person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sp_clone_il_mapping_segment_logs

Type: has_many

Related object: L<CXGN::People::Schema::Result::SpCloneIlMappingSegmentLog>

=cut

__PACKAGE__->has_many(
  "sp_clone_il_mapping_segment_logs",
  "CXGN::People::Schema::Result::SpCloneIlMappingSegmentLog",
  { "foreign.sp_person_id" => "self.sp_person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sp_group_members

Type: has_many

Related object: L<CXGN::People::Schema::Result::SpGroupMember>

=cut

__PACKAGE__->has_many(
  "sp_group_members",
  "CXGN::People::Schema::Result::SpGroupMember",
  { "foreign.sp_person_id" => "self.sp_person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sp_organization_people

Type: has_many

Related object: L<CXGN::People::Schema::Result::SpOrganizationPerson>

=cut

__PACKAGE__->has_many(
  "sp_organization_people",
  "CXGN::People::Schema::Result::SpOrganizationPerson",
  { "foreign.sp_person_id" => "self.sp_person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sp_papers

Type: has_many

Related object: L<CXGN::People::Schema::Result::SpPaper>

=cut

__PACKAGE__->has_many(
  "sp_papers",
  "CXGN::People::Schema::Result::SpPaper",
  { "foreign.person_id" => "self.sp_person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sp_person_organisms

Type: has_many

Related object: L<CXGN::People::Schema::Result::SpPersonOrganism>

=cut

__PACKAGE__->has_many(
  "sp_person_organisms",
  "CXGN::People::Schema::Result::SpPersonOrganism",
  { "foreign.sp_person_id" => "self.sp_person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sp_person_roles

Type: has_many

Related object: L<CXGN::People::Schema::Result::SpPersonRole>

=cut

__PACKAGE__->has_many(
  "sp_person_roles",
  "CXGN::People::Schema::Result::SpPersonRole",
  { "foreign.sp_person_id" => "self.sp_person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sp_project_il_mapping_clone_logs

Type: has_many

Related object: L<CXGN::People::Schema::Result::SpProjectIlMappingCloneLog>

=cut

__PACKAGE__->has_many(
  "sp_project_il_mapping_clone_logs",
  "CXGN::People::Schema::Result::SpProjectIlMappingCloneLog",
  { "foreign.sp_person_id" => "self.sp_person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 sp_project_people

Type: has_many

Related object: L<CXGN::People::Schema::Result::SpProjectPerson>

=cut

__PACKAGE__->has_many(
  "sp_project_people",
  "CXGN::People::Schema::Result::SpProjectPerson",
  { "foreign.sp_person_id" => "self.sp_person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_map_datas

Type: has_many

Related object: L<CXGN::People::Schema::Result::UserMapData>

=cut

__PACKAGE__->has_many(
  "user_map_datas",
  "CXGN::People::Schema::Result::UserMapData",
  { "foreign.sp_person_id" => "self.sp_person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_maps

Type: has_many

Related object: L<CXGN::People::Schema::Result::UserMap>

=cut

__PACKAGE__->has_many(
  "user_maps",
  "CXGN::People::Schema::Result::UserMap",
  { "foreign.sp_person_id" => "self.sp_person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-02-26 16:04:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wsrgcinW5giKbyUobgTQ7g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
