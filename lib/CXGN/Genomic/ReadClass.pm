package CXGN::Genomic::ReadClass;

=head1 NAME

    CXGN::Genomic::ReadClass - genomic.read_class object abstraction

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
      read_class_id

  Columns:
      read_class_id
      class_name

  Sequence:
      (genomic base schema).read_class_read_class_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table('genomic' . '.read_class');

our @primary_key_names =
    qw/
      read_class_id
      /;

our @column_names =
    qw/
      read_class_id
      class_name
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('genomic').'.read_class_read_class_id_seq' );

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
