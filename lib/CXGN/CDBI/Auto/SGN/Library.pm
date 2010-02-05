package CXGN::CDBI::Auto::SGN::Library;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::SGN::Library - object abstraction for rows in the sgn.library table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      library_id

  Columns:
      library_id
      type
      submit_user_id
      library_name
      library_shortname
      authors
      organism_id
      cultivar
      accession
      tissue
      development_stage
      treatment_conditions
      cloning_host
      vector
      rs1
      rs2
      cloning_kit
      comments
      contact_information
      order_routing_id
      sp_person_id
      forward_adapter
      reverse_adapter
      obsolete
      modified_date
      create_date
      chado_organism_id

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'sgn.library' );

our @primary_key_names =
    qw/
      library_id
      /;

our @column_names =
    qw/
      library_id
      type
      submit_user_id
      library_name
      library_shortname
      authors
      organism_id
      cultivar
      accession
      tissue
      development_stage
      treatment_conditions
      cloning_host
      vector
      rs1
      rs2
      cloning_kit
      comments
      contact_information
      order_routing_id
      sp_person_id
      forward_adapter
      reverse_adapter
      obsolete
      modified_date
      create_date
      chado_organism_id
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###