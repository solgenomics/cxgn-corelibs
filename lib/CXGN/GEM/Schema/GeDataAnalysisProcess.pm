package CXGN::GEM::Schema::GeDataAnalysisProcess;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("ge_data_analysis_process");
__PACKAGE__->add_columns(
  "data_analysis_process_id",
  {
    data_type => "integer",
    default_value => "nextval('gem.ge_data_analysis_process_data_analysis_process_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "process_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 250,
  },
  "target_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "source_dataset_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "result_dataset_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "file_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "metadata_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("data_analysis_process_id");
__PACKAGE__->add_unique_constraint("ge_data_analysis_process_pkey", ["data_analysis_process_id"]);
__PACKAGE__->belongs_to(
  "target_id",
  "CXGN::GEM::Schema::GeTarget",
  { target_id => "target_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-11-24 17:00:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:F8wWqPFq2IErDH5d3ZjBBg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
