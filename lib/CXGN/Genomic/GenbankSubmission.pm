package CXGN::Genomic::GenbankSubmission;

=head1 NAME

    CXGN::Genomic::GenbankSubmission -
       genomic.genbank_submission object abstraction

=head1 DESCRIPTION

a row in this table represents a single batch submission to genbank.
this lets us track when things were submitted and when they came back.

if you submit some stuff to genbank, please add a row in this table and
create gss_submitted_to_genbank records for them.  the script
genomic_gss_genbank_submit.pl can help with this.

=head1 SYNOPSIS

none yet

=head1 METHODS

=cut

use strict;
use English;


=head1 DATA FIELDS

  Primary Keys:
      genbank_submission_id

  Columns:
      genbank_submission_id
      date_generated
      date_sent
      submitted_by
      ncbi_reply_date

  Sequence:
      (genomic base schema).genbank_submission_genbank_submission_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table('genomic' . '.genbank_submission');

our @primary_key_names =
    qw/
      genbank_submission_id
      /;

our @column_names =
    qw/
      genbank_submission_id
      date_generated
      date_sent
      submitted_by
      ncbi_reply_date
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('genomic').'.genbank_submission_genbank_submission_id_seq' );

our $tablename = __PACKAGE__->table;
our @persistentfields = map {[$_]} __PACKAGE__->columns;
our $persistent_field_count = @persistentfields;
our $dbname = 'genomic';

__PACKAGE__->has_many( gss_submitted_to_genbank => 'CXGN::Genomic::GSSSubmittedToGenbank' );

=head1 AUTHOR

Robert Buels

=cut

####
1; # do not remove
####
