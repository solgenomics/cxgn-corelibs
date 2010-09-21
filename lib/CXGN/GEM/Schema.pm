package CXGN::GEM::Schema;

use strict;
use warnings;
use Carp;

use Module::Find;
use CXGN::Biosource::Schema;
use CXGN::Metadata::Schema;
use Bio::Chado::Schema;
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

 my $schema_list = 'gem,biosource,metadata,public'; 

 my $schema = CXGN::GEM::Schema->connect( sub { $dbh }, 
                                          { on_connect_do => ["SET search_path TO $schema_list"] }, );

 ## Using DBICFactory:

 my @schema_list = split(/,/, $schema_list); 
 my $schema = CXGN::DB::DBICFactory->open_schema( 'CXGN::GEM::Schema', search_path => \@schema_list, );


=head1 DESCRIPTION

 This class create a new DBIx::Class::Schema object and load the dependencies of other schema classes as
 metadata, bioosource or chado.
 
 It need set_path to be able to use all of them.

 Also load the relations between schemas.

=head1 AUTHOR

Aureliano Bombarely <ab782@cornell.edu>


=head1 CLASS METHODS

The following class methods are implemented:

=cut 


### The GEM schema use chado, biosource and metadata schemas, so it will load this classes

my (@gem_classes, @biosource_classes, @metadata_classes, @chado_classes);


## Get all the gem classes using findallmod

my @gem_modules = findallmod 'CXGN::GEM::Schema';
foreach my $gem_module (@gem_modules) {
    $gem_module =~ s/CXGN::GEM::Schema:://;
    push @gem_classes, $gem_module;
}

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

__PACKAGE__->load_classes( @gem_classes, 
			   { 
			      'Bio::Chado::Schema'     => [@chado_classes], 
			      'CXGN::Metadata::Schema' => [@metadata_classes],
			      'CXGN::Biosource::Schema'=> [@biosource_classes],
			   }
                         );


## Finally add the relationships (all the gem tables will be metadata_id relation)

my @metadata_relation_parameters = ('metadata_id', 
                                     "CXGN::Metadata::Schema::MdMetadata", 
                                     { 'foreign.metadata_id' => 'self.metadata_id' } );

my @dbxref_relation_parameters = ('dbxref_id', 
                                     "Bio::Chado::Schema::General::Dbxref", 
                                     { 'foreign.dbxref_id' => 'self.dbxref_id' } );


foreach my $gem_class (@gem_classes) { 
    
  __PACKAGE__->source($gem_class)
 	     ->add_relationship( @metadata_relation_parameters );

  if ($gem_class =~ m/Dbxref^/i) {
      __PACKAGE__->source($gem_class)
 	     ->add_relationship( @dbxref_relation_parameters );
  }

}


__PACKAGE__->source('GePlatformPub')
           ->add_relationship('pub_id', "Bio::Chado::Schema::Pub::Pub", { 'foreign.pub_id' => 'self.pub_id' } );

__PACKAGE__->source('GePlatformDesign')
           ->add_relationship('sample_id', "CXGN::Biosource::Schema::BsSample", { 'foreign.sample_id' => 'self.sample_id' } );

__PACKAGE__->source('GeTemplateDbiref')
           ->add_relationship('dbiref_id', "CXGN::Metadata::Schema::MdDbiref", { 'foreign.dbiref_id' => 'self.dbiref_id' } );

__PACKAGE__->source('GeProbe')
           ->add_relationship('sequence_file_id', "CXGN::Metadata::Schema::MdFiles", { 'foreign.file_id' => 'self.sequence_file_id' } );

__PACKAGE__->source('GeExperimentalDesignPub')
           ->add_relationship('pub_id', "Bio::Chado::Schema::Pub::Pub", { 'foreign.pub_id' => 'self.pub_id' } );

__PACKAGE__->source('GeTargetElement')
           ->add_relationship('sample_id', "CXGN::Biosource::Schema::BsSample", { 'foreign.sample_id' => 'self.sample_id' } );

__PACKAGE__->source('GeTargetElement')
           ->add_relationship('protocol_id', "CXGN::Biosource::Schema::BsProtocol", { 'foreign.protocol_id' => 'self.protocol_id' } );

__PACKAGE__->source('GeHybridization')
           ->add_relationship('protocol_id', "CXGN::Biosource::Schema::BsProtocol", { 'foreign.protocol_id' => 'self.protocol_id' } );

__PACKAGE__->source('GeFluorescanning')
           ->add_relationship('protocol_id', "CXGN::Biosource::Schema::BsProtocol", { 'foreign.protocol_id' => 'self.protocol_id' } );

__PACKAGE__->source('GeFluorescanning')
           ->add_relationship('dbxref_id', "Bio::Chado::Schema::General::Dbxref", { 'foreign.dbxref_id' => 'self.dbxref_id' } );

__PACKAGE__->source('GeFluorescanning')
           ->add_relationship('file_id', "CXGN::Metadata::Schema::MdFiles", { 'foreign.file_id' => 'self.file_id' } );

__PACKAGE__->source('GeProbeExpression')
           ->add_relationship('dataset_id', "CXGN::Biosource::Schema::BsSample", { 'foreign.sample_id' => 'self.dataset_id' } );

__PACKAGE__->source('GeTemplateExpression')
           ->add_relationship('dataset_id', "CXGN::Biosource::Schema::BsSample", { 'foreign.sample_id' => 'self.dataset_id' } );

__PACKAGE__->source('GeExpressionByExperiment')
           ->add_relationship('dataset_id', "CXGN::Biosource::Schema::BsSample", { 'foreign.sample_id' => 'self.dataset_id' } );

__PACKAGE__->source('GeTemplateDiffExpression')
           ->add_relationship('dataset_id', "CXGN::Biosource::Schema::BsSample", { 'foreign.sample_id' => 'self.dataset_id' } );

__PACKAGE__->source('GeCorrelationMember')
           ->add_relationship('dataset_id', "CXGN::Biosource::Schema::BsSample", { 'foreign.sample_id' => 'self.dataset_id' } );

__PACKAGE__->source('GeClusterAnalysis')
           ->add_relationship('protocol_id', "CXGN::Biosource::Schema::BsProtocol", { 'foreign.protocol_id' => 'self.protocol_id' } );

__PACKAGE__->source('GeClusterProfile')
           ->add_relationship('file_id', "CXGN::Metadata::Schema::MdFiles", { 'foreign.file_id' => 'self.file_id' } );


## The following functions are used by the test scripts

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
	my $table_name = $schema->class($source_name)->table();

	if ( $schema->exists_dbtable($table_name) ) {

	    my ($primary_key_col) = $source->primary_columns();

	    my $primary_key_col_info;
	    my $primary_key_col_info_href = $source->column_info($primary_key_col);
	    if (exists $primary_key_col_info_href->{'default_value'}) {
		$primary_key_col_info = $primary_key_col_info_href->{'default_value'};
	    }
	    elsif (exists $primary_key_col_info_href->{'sequence'}) {
		$primary_key_col_info = $primary_key_col_info_href->{'sequence'};
	    }
	    
	    my $last_value = $schema->resultset($source_name)
                                    ->get_column($primary_key_col)
                                    ->max();
	    my $seq_name;

	    if (defined $primary_key_col_info) {
		if (exists $primary_key_col_info_href->{'default_value'}) {
		    if ($primary_key_col_info =~ m/\'(.*?_seq)\'/) {
			$seq_name = $1;
		    }
		}
		elsif (exists $primary_key_col_info_href->{'sequence'}) {
		    if ($primary_key_col_info =~ m/(.*?_seq)/) {
			$seq_name = $1;
		    }
		}
	    } 
	    else {
		print STDERR "The source:$source_name ($source) with primary_key_col:$primary_key_col hasn't any primary_key_col_info.\n";
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

    my @schema_list;
    unless (defined $schemaname) {
	my ($search_path) = $schema->storage()
	                           ->dbh()
				   ->selectrow_array('SHOW search_path');
	$search_path =~ s/\s+//g;
	@schema_list = split(/,/, $search_path);
    }
    else {
	@schema_list = ($schemaname);
    }

    my $dbtrue = 0;
    foreach my $schema_name (@schema_list) {
	my ($count) = $schema->storage()
	                     ->dbh()
                             ->selectrow_array("SELECT COUNT(*) FROM pg_tables WHERE schemaname = ? AND tablename = ?", 
				   	       undef, 
					       ($schema_name, $tablename) );
	if ($count == 1) {
	    $dbtrue = $count;
	}
    }
    return $dbtrue;
}


####
1;##
####
