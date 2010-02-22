
package CXGN::Biosource::Schema;

use strict;
use warnings;
use Carp;

use Module::Find;
use CXGN::Metadata::Schema;
use Bio::Chado::Schema;
use base 'DBIx::Class::Schema';


###############
### PERLDOC ###
###############

=head1 NAME

CXGN::Biosource::Schema
a DBIx::Class::Schema object to manipulate the biosource schema.

=cut

our $VERSION = '0.01';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

 my $schema_list = 'biosource,metadata,public'; 

 my $schema = CXGN::Biosource::Schema->connect( sub { $dbh }, 
                                          { on_connect_do => ["SET search_path TO $schema_list"] }, );
 
 ## Using DBICFactory:

 my @schema_list = split(/,/, $schema_list); 
 my $schema = CXGN::DB::DBICFactory->open_schema( 'CXGN::Biosource::Schema', search_path => \@schema_list, );


=head1 DESCRIPTION

 This class create a new DBIx::Class::Schema object and load the dependencies of other schema classes as
 metadata, or chado.
 
 It need set_path to be able to use all of them.

 Also load the relations between schemas.

=head1 AUTHOR

Aureliano Bombarely <ab782@cornell.edu>


=head1 CLASS METHODS

The following class methods are implemented:

=cut 



### The biosource schema use chado and metadata schemas, so it will load this classes

my (@biosource_classes, @metadata_classes, @chado_classes);

## Get all the biosource classes using findallmod

my @biosource_modules = findallmod 'CXGN::Biosource::Schema';
foreach my $biosource_module (@biosource_modules) {
    $biosource_module =~ s/CXGN::Biosource::Schema:://;
    push @biosource_classes, $biosource_module;
}

## Get all the metadata classes using findallmod

my @metadata_modules = findallmod 'CXGN::Metadata::Schema';
foreach my $metadata_module (@metadata_modules) {
    $metadata_module =~ s/CXGN::Metadata::Schema:://;
    push @metadata_classes, $metadata_module;
}

## Get all the chado classes using findallmod
my @chado_modules = findallmod 'Bio::Chado::Schema';
foreach my $chado_module (@chado_modules) {
    $chado_module =~ s/Bio::Chado::Schema:://;
    push @chado_classes, $chado_module;
}



## Load in the package all the classes

__PACKAGE__->load_classes( @biosource_classes, 
			   { 
			      'CXGN::Metadata::Schema' => [@metadata_classes],
			      'Bio::Chado::Schema'     => [@chado_modules],
			   }
                         );


## Finally add the relationships (all the biosource tables will be metadata_id relation)

 my @metadata_relation_parameters = ('metadata_id', 
                                     "CXGN::Metadata::Schema::MdMetadata", 
                                     { 'foreign.metadata_id' => 'self.metadata_id' } );

foreach my $biosource_class (@biosource_classes) { 
    
  __PACKAGE__->source($biosource_class)
 	     ->add_relationship( @metadata_relation_parameters );
}



=head2 get_all_last_ids

  Usage: my $all_last_ids_href = $schema->get_all_last_ids();
 
  Desc: Get all the last ids and store then in an hash reference for a specified schema
 
  Ret: $all_last_ids_href, a hash reference with keys = SQL_sequence_name and value = last_value
 
  Args: $schema, a CXGN::Biosource::Schema object
 
  Side Effects: If the seq name don't have the schema name (schema.sequence_seq) is ignored 
 
  Example: my $all_last_ids_href = $schema->get_all_last_ids();

=cut

sub get_all_last_ids {
    my $schema = shift || die("None argument was supplied to the subroutine get_all_last_ids()");
    my %last_ids;
    my @source_names = $schema->sources();
    
    
    foreach my $source_name (sort @source_names) {

        my $source = $schema->source($source_name);
	my $table_name = $schema->class($source_name)
	                        ->table();

	my ($seq_name, $last_value);

	if ( $schema->exists_dbtable($table_name) == 1) {
	    
	    my ($primary_key_col) = $source->primary_columns();
	    
	    if (defined $primary_key_col) {
	    
		my $primary_key_col_info = $source->column_info($primary_key_col)
		                                  ->{'default_value'};
	    
		$last_value = $schema->resultset($source_name)
		                     ->get_column($primary_key_col)
                                     ->max();
		
		if (defined $primary_key_col_info) {
		    if ($primary_key_col_info =~ m/\'(\w+\..*?_seq)\'/) {
			$seq_name = $1;
		    }
		} 
		else {
		    print STDERR "The source:$source_name ($source) with primary_key_col:$primary_key_col hasn't primary_key_col_info.\n";
		}
	    }
	    if (defined $seq_name) {
		$last_ids{$seq_name} = $last_value || 0;
	    }
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

=head2 exists_dbtable

  Usage: $schema->exists_dbtable($dbtablename, $dbschemaname);
 
  Desc: Check in exists a table in the database
 
  Ret: A boolean, 1 for true and 0 for false
 
  Args: $dbtablename and $dbschemaname. If none schename is supplied, 
        it will use the schema set in search_path

 
  Side Effects: None
 
  Example: if ($schema->exists_dbtable($table)) { ## do something }

=cut

sub exists_dbtable {
    my $schema = shift;
    my $tablename = shift;
    my $schemaname = shift;

    my $dbh = $schema->storage()
	             ->dbh();

    ## First get all the path setted for this object

    my @schemalist;
    if (defined $schemaname) {
	push @schemalist, $schemaname;
    }
    else {
	my ($path) = $dbh->selectrow_array("SHOW search_path");
	@schemalist = split(/, /, $path);
    }
    
    my $dbtrue = 0;
    foreach my $schema_name (@schemalist) {
	my $query = "SELECT count(*) FROM pg_tables WHERE tablename = ? AND schemaname = ?";
	my ($predbtrue) = $dbh->selectrow_array($query, undef, $tablename, $schema_name);
	if ($predbtrue > $dbtrue) {
	    $dbtrue = $predbtrue;
	}
    }
 
    return $dbtrue;
}


####
1;##
####
