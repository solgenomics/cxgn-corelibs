package CXGN::Genomic::GSSSubmittedToGenbank;

=head1 NAME

    CXGN::Genomic::GSSSubmittedToGenbank -
       genomic.gss_submitted_to_genbank object abstraction

=head1 DESCRIPTION

genomic.gss_submitted_to_genbank is a linking table between genomic.gss
and genomic.genbank_submission.  It also holds the genbank identifiers of
sequences submitted to genbank.

=head1 SYNOPSIS

none yet

=head1 METHODS

=cut

use strict;
use English;


=head1 DATA FIELDS

  Primary Keys:
      gss_submitted_to_genbank_id

  Columns:
      gss_submitted_to_genbank_id
      genbank_submission_id
      gss_id
      genbank_identifier
      genbank_dbgss_id

  Sequence:
      (genomic base schema).gss_submitted_to_genbank_gss_submitted_to_genbank_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table('genomic' . '.gss_submitted_to_genbank');

our @primary_key_names =
    qw/
      gss_submitted_to_genbank_id
      /;

our @column_names =
    qw/
      gss_submitted_to_genbank_id
      genbank_submission_id
      gss_id
      genbank_identifier
      genbank_dbgss_id
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('genomic').'.gss_submitted_to_genbank_gss_submitted_to_genbank_id_seq' );

our $tablename = __PACKAGE__->table;
our @persistentfields = map {[$_]} __PACKAGE__->columns;
our $persistent_field_count = @persistentfields;
our $dbname = 'genomic';

__PACKAGE__->has_a(gss_id => 'CXGN::Genomic::GSS');
__PACKAGE__->has_a(genbank_submission_id => 'CXGN::Genomic::GenbankSubmission');

=head1 AUTHOR

Robert Buels

=cut

####
1; # do not remove
####
