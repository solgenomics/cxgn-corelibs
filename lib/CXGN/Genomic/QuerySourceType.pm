package CXGN::Genomic::QuerySourceType;

=head1 NAME

    CXGN::Genomic::QuerySourceType - genomic.query_source_type object abstraction

=head1 DESCRIPTION

none yet

=head1 SYNOPSIS

none yet

=cut

use strict;
use English;

=head1 DATA FIELDS

  Primary Keys:
      query_source_type_id

  Columns:
      query_source_type_id
      name
      shortname

  Sequence:
      (genomic base schema).query_source_type_query_source_type_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table('genomic' . '.query_source_type');

our @primary_key_names =
    qw/
      query_source_type_id
      /;

our @column_names =
    qw/
      query_source_type_id
      name
      shortname
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('genomic').'.query_source_type_query_source_type_id_seq' );

=head1 AUTHOR

Robert Buels

=cut

####
1; # do not remove
####
