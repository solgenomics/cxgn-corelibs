package CXGN::Metadata::Schema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';


###############
### PERLDOC ###
###############

=head1 NAME

CXGN::GEM::Schema
a DBIx::Class::Schema object to manipulate the gem schema.

=cut

our $VERSION = '0.01';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

 my $schema_list = 'metadata'; 

 my $schema = CXGN::Metadata::Schema->connect( sub { $dbh }, 
                                          { on_connect_do => ["SET search_path TO $schema_list"] }, );

 ## Using DBICFactory:

 my @schema_list = split(/,/, $schema_list); 
 my $schema = CXGN::DB::DBICFactory->open_schema( 'CXGN::Metadata::Schema', search_path => \@schema_list, );


=head1 DESCRIPTION

 This class create a new DBIx::Class::Schema object and load the all the metadata classes.


=head1 AUTHOR

Aureliano Bombarely <ab782@cornell.edu>


=head1 CLASS METHODS

The following class methods are implemented:

=cut 


__PACKAGE__->load_classes;



=head2 get_last_id

  Usage: my %last_id = $schema->get_last_id();
         my $last_table_id = $schema->get_last_id($tableseq_name)
 
  Desc: Get all the last ids and store then in an hash reference for a specified schema
 
  Ret: $all_last_ids_href, a hash reference with keys = SQL_sequence_name and value = last_value
 
  Args: $schema, a CXGN::SEDM::Schema object
        $tableseq_name, a scalar, name of the sequence
 
  Side Effects: If the seq name don't have the schema name (schema.sequence_seq) is ignored 
 
  Example: my %last_id = $schema->get_last_id();
           my $last_table_id = $schema->get_last_id($tableseq_name)

=cut

sub get_last_id {
    my $schema = shift 
	|| die("None argument was supplied to the subroutine get_all_last_ids()");

    warn("WARNING: $schema->get_last_id() is a deprecated method. Use get_nextval().\n");
    
    my $sqlseq = shift;

    my %last_ids;
    my @source_names = $schema->sources();
    foreach my $source_name (@source_names) {
        my $source = $schema->source($source_name);

        my ($primary_key_col) = $source->primary_columns();
        my $primary_key_col_info = $source->column_info($primary_key_col)->{'default_value'};

        my $last_value = $schema->resultset($source_name)->get_column($primary_key_col)->max();

        my $seq_name;
        if (defined $primary_key_col_info) {
            if ($primary_key_col_info =~ m/\'(.+?_seq)\'/) {
                $seq_name = $1;
            }
        } 
	else {
            print STDERR "The source:$source_name ($source) with primary_key_col:$primary_key_col has not any primary_key_col_info.\n";
        }
        if (defined $seq_name) {
            $last_ids{$seq_name} = $last_value || 0;
        }
    }

    if (defined $sqlseq) {
	return $last_ids{$sqlseq};
    }
    else {
	return %last_ids;
    }
}

=head2 set_sqlseq

  Usage: $schema->set_sqlseq($seqvalues_href);
 
  Desc: set the sequence values to the values specified in the $seqvalues_href
 
  Ret: none 
 
  Args: $schema, a schema object
        $seqvalues_href, a hash reference with keys=sequence_name and value=value to set
        $on_message, enable the message option
 
  Side Effects: If value to set is undef set value to the first seq
 
  Example: $schema->set_sqlseq($seqvalues_href, 1);

=cut

sub set_sqlseq {
    my $schema = shift 
	|| die("None argument was supplied to the subroutine set_sqlseq_values_to_original_state().\n");
    my $seqvalues_href = shift 
	|| die("None argument was supplied to the subroutine set_sqlseq_values_to_original_state().\n");
    my $on_message = shift;  ## To enable messages

    warn("WARNING: $schema->set_sqlseq is a deprecated method. Table sequences should be set manually.\n");

    my %seqvalues = %{ $seqvalues_href };

    foreach my $sqlseq (keys %seqvalues) {

        my $sqlseqline = "'".$sqlseq."'";
        my $val = $seqvalues{$sqlseq};
        if ($val > 0) {

            $schema->storage()
		   ->dbh()
		   ->do("SELECT setval ($sqlseqline, $val, true)");
        } 
	else {

            ## If there aren't any value (the table is empty, it set to 1, false)

            $schema->storage()->dbh()->do("SELECT setval ($sqlseqline, 1, false)");
        }
    }
    if (defined $on_message) {
	print STDERR "Setting the SQL sequences to the original values before run the script... done\n";
    }
}

=head2 exists_data

 Usage: $class->exist_data($table, $column, $data);
 
 Desc: This method check if exists or not a concrete data in a concrete table
 
 Ret: 0 for false and 1 for true
 
 Args: $table, a scalar, table name;
       $colum, a scalar, the name of the column
       $data, a scalar, data to check
 
 Side Effects: None
 
 Example: CXGN::Metadata::Schema->exists_data('platforms', 'platform_id', 1);

=cut

sub exists_data {
    my $self = shift;
    my $table = shift;
    my $column = shift;
    my $data = shift;

    unless (defined $table) {
	return 0;
    } 
    else {
	my @source_names = $self->sources();
	my $match = 0;
	foreach my $source (@source_names) {
	    if ($source eq $table) {
		$match = 1;
	    }
	}
	if ($match == 0) {
	    return 0;
	} 
	else {
	    unless (defined $column) {
		return 0;
	    } 
	    else {
		my $source_name;
		my @source_name = split(/_/, $table);
		foreach my $subsource_name (@source_name) {
		    $source_name .= ucfirst($subsource_name);
		}
		unless ( $self->source($source_name)->has_column($column) ) {
		    return 0;
		} else {
		    unless ( defined($self->resultset($source_name)->search( $column => $data)) ) {
			return 0;
		    } else {
			return 1;
		    }
		}
	    }
	}
    }
}

##############################################
## New function to replace get_all_last_ids ##
##############################################

=head2 get_nextval

  Usage: my %nextval = $schema->get_nextval();
 
  Desc: Get all the next values from the table sequences
        and store into hash using SELECT nextval()
 
  Ret: %nextval, a hash with keys = SQL_sequence_name 
       and value = nextval
 
  Args: $schema, a CXGN::GEM::Schema object
 
  Side Effects: If the table has not primary_key or 
                default value sequence, it will be ignore. 
 
  Example: my %nextval = $schema->get_nextval();

=cut

sub get_nextval {
    my $schema = shift 
	|| die("None argument was supplied to the subroutine get_nextval()");
    
    my %nextval;
    my @source_names = $schema->sources();
    
    my $dbh = $schema->storage()
	             ->dbh();

    foreach my $source_name (sort @source_names) {

        my $source = $schema->source($source_name);
	my $table_name = $schema->class($source_name)
                                ->table();

	## To get the sequence
	## 1) Get primary key

	my $seq_name;
	my ($prikey) = $dbh->primary_key(undef, undef, $table_name);
	
	if (defined $prikey) {

	    ## 2) Get default for primary key

	    my $sth = $dbh->column_info( undef, undef, $table_name, $prikey);
	    my ($rel) = (@{$sth->fetchall_arrayref({})});
	    my $default_val = $rel->{'COLUMN_DEF'};
	
	    ## 3) Extract the seq_name

	    if ($default_val =~ m/nextval\('(.+)'::regclass\)/) {
		$seq_name = $1;
	    }
	}
	
	if (defined $seq_name) {
	    if ($schema->is_table($table_name)) {
		
                ## Get the nextval (it is not using currval, because
                ## you can not use it without use nextval before).

		my $query = "SELECT nextval('$seq_name')";
		my ($nextval) = $dbh->selectrow_array($query);
		
		$nextval{$table_name} = $nextval || 0;
	    }
	}
	
    }
    return %nextval;
}

=head2 is_table

  Usage: $schema->is_table($tablename, $schemaname);
 
  Desc: Return 0/1 if exists or not a table into the 
        database
 
  Ret: 0 or 1
 
  Args: $schema, a CXGN::GEM::Schema object
        $tablename, name of a table
        $schemaname, name of a schema
 
  Side Effects: If $tablename is undef. it will return
                0.
                If $schemaname is undef. it will search
                for the tablename in all the schemas.
 
  Example: if ($schema->is_table('ge_experiment')) {
                  ## Do something
           }

=cut

sub is_table {
    my $schema = shift 
	|| die("None argument was supplied to the subroutine is_table()");
 
    my $tablename = shift;
    my $schemaname = shift;

    ## Get the dbh

    my $dbh = $schema->storage()
	             ->dbh();

    ## Define the hash with the tablenames

    my %tables;

    ## Get all the tables with the tablename

    my $presence = 0;

    if (defined $tablename) {
	my $sth = $dbh->table_info('', $schemaname, $tablename, 'TABLE');
	for my $rel (@{$sth->fetchall_arrayref({})}) {
	
	    ## It will search based in LIKE so it need to check the right anme
	    if ($rel->{TABLE_NAME} eq $tablename) {
		$presence = 1;
	    }
	}
    }

    return $presence;
}



####
1;##
####
