package CXGN::Genomic::BlastDefline;

=head1 NAME

    CXGN::Genomic::BlastDefline - genomic.blast_defline object abstraction

=head1 DESCRIPTION

none yet

=head1 SYNOPSIS

none yet

=head1 METHODS

=cut

use strict;
use English;
use Carp;


=head1 DATA FIELDS

  Primary Keys:
      blast_defline_id

  Columns:
      blast_defline_id
      blast_db_id
      identifier
      defline
      identifier_defline_fulltext

  Sequence:
      (genomic base schema).blast_defline_blast_defline_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table('genomic' . '.blast_defline');

our @primary_key_names =
    qw/
      blast_defline_id
      /;

our @column_names =
    qw/
      blast_defline_id
      blast_db_id
      identifier
      defline
      identifier_defline_fulltext
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('genomic').'.blast_defline_blast_defline_id_seq' );

our $tablename = __PACKAGE__->table;
our @persistentfields = map {[$_]} __PACKAGE__->columns;
our $persistent_field_count = @persistentfields;
our $dbname = 'genomic';


=head2 blasthit_objects

  Desc: L<Class::DBI> has_many relation to get all the L<CXGN::Genomic::BlastHit>
        objects that reference this one
  Args: none
  Ret : array of L<CXGN::Genomic::BlastHit> objects that reference this defline
  Side Effects:
  Example:

=cut

__PACKAGE__->has_many(blasthit_objects => 'CXGN::Genomic::BlastHit');


=head2 delete_unreferenced

  Desc: delete all BlastDefline rows that are not referenced by
        a BlastHit.
  Args: none
  Ret : does the following:
     1. creates a temporary table called unreferenced_defline_ids
     2. fills it with the ids of all blast_defline objects that are not
        referenced by any rows in the blast_hits table.
     3. deletes all of these from the blast_defline table.
     4. drop the temporary table created in step 1.



=cut

__PACKAGE__->set_sql( dur_create_temp_table => <<EOSQL );
CREATE TEMPORARY TABLE $dbname.unreferenced_defline_ids (id int)
EOSQL

__PACKAGE__->set_sql( dur_fill_temp_table => <<EOSQL );
INSERT INTO $dbname.unreferenced_defline_ids (id)
SELECT dl.blast_defline_id
FROM $dbname.blast_defline as dl
LEFT JOIN $dbname.blast_hit as bh
  USING(blast_defline_id)
WHERE bh.blast_defline_id IS NULL
EOSQL

__PACKAGE__->set_sql( dur_delete_unreferenced => <<EOSQL );
DELETE FROM $dbname.blast_defline
USING 	$dbname.blast_defline as dl,
	$dbname.unreferenced_defline_ids as ur
WHERE dl.blast_defline_id=ur.id
EOSQL

__PACKAGE__->set_sql( dur_drop_temp_table => <<EOSQL );
DROP TABLE $dbname.unreferenced_defline_ids
EOSQL

sub delete_unreferenced {
  my $class = shift;

  $class->sql_dur_create_temp_table;
  $class->sql_dur_fill_temp_table;
  $class->sql_dur_delete_unreferenced;
  $class->sql_dur_drop_temp_table;
}

=head1 AUTHOR

Robert Buels

=cut

###
1;#do not remove
###
