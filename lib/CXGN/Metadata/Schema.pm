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



=head2 get_all_last_ids

  Usage: my $all_last_ids_href = $schema->get_all_last_ids();
 
  Desc: Get all the last ids and store then in an hash reference for a specified schema
 
  Ret: $all_last_ids_href, a hash reference with keys = SQL_sequence_name and value = last_value
 
  Args: $schema, a CXGN::SEDM::Schema object
 
  Side Effects: If the seq name don't have the schema name (schema.sequence_seq) is ignored 
 
  Example: my $all_last_ids_href = $schema->get_all_last_ids();

=cut

sub get_all_last_ids {
    my $schema = shift || die("None argument was supplied to the subroutine get_all_last_ids()");
    my %last_ids;
    my @source_names = $schema->sources();
    foreach my $source_name (@source_names) {
        my $source = $schema->source($source_name);

        my ($primary_key_col) = $source->primary_columns();
        my $primary_key_col_info = $source->column_info($primary_key_col)->{'default_value'};

        my $last_value = $schema->resultset($source_name)->get_column($primary_key_col)->max();

        my $seq_name;
        if (defined $primary_key_col_info) {
            if ($primary_key_col_info =~ m/\'(\w+\..*?_seq)\'/) {
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
    return \%last_ids;
}

=head2 set_sqlseq_values_to_original_state

  Usage: $schema->set_sqlseq_values_to_original_state($seqvalues_href);
 
  Desc: set the sequence values to the values specified in the $seqvalues_href
 
  Ret: none 
 
  Args: $schema, a schema object
        $seqvalues_href, a hash reference with keys=sequence_name and value=value to set
        $on_message, enable the message option
 
  Side Effects: If value to set is undef set value to the first seq
 
  Example: $schema->set_sqlseq_values_to_original_state($seqvalues_href, 1);

=cut

sub set_sqlseq_values_to_original_state {
    my $schema = shift || die("None argument was supplied to the subroutine set_sqlseq_values_to_original_state().\n");
    my $seqvalues_href = shift || die("None argument was supplied to the subroutine set_sqlseq_values_to_original_state().\n");
    my $on_message = shift;  ## To enable messages

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




1;

