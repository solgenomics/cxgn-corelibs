
package CXGN::People::Schema::Result::SpStageGateDefinition;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("sp_stage_gate_definition");

__PACKAGE__->add_columns(
  "sp_stage_gate_definition_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "sgn_people.sp_stage_gate_definition_sp_stage_gate_definition_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "description",
  { data_type => "text", is_nullable => 1 },
);


__PACKAGE__->set_primary_key("sp_stage_gate_definition_id");



__PACKAGE__->has_many(
  "sp_stage_gate",
  "CXGN::People::Schema::Result::SpStageGate",
  { "foreign.sp_stage_gate_definition_id" => "self.sp_stage_gate_definition_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


1;
