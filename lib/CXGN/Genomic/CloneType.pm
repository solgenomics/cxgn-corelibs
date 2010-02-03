package CXGN::Genomic::CloneType;

=head1 NAME

    CXGN::Genomic::CloneType - genomic.clone_type object

=head1 DESCRIPTION

none yet

=head1 SYNOPSIS

none yet

=head1 METHODS

=cut

use strict;
use English;


=head1 DATA FIELDS

  Primary Keys:
      clone_type_id

  Columns:
      clone_type_id
      name
      shortname

  Sequence:
      (genomic base schema).clone_type_clone_type_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table('genomic' . '.clone_type');

our @primary_key_names =
    qw/
      clone_type_id
      /;

our @column_names =
    qw/
      clone_type_id
      name
      shortname
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('genomic').'.clone_type_clone_type_id_seq' );

our $tablename = __PACKAGE__->table;
our @persistentfields = map {[$_]} __PACKAGE__->columns;
our $persistent_field_count = @persistentfields;
our $dbname = 'genomic';

=head1 AUTHOR

Robert Buels

=cut

####
1; # do not remove
####
