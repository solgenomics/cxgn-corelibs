#!/usr/bin/perl

=head1 NAME

  sample.t
  A piece of code to test the CXGN::Biosource::Sample module

=cut

=head1 SYNOPSIS

 perl sample.t

 Note: To run the complete test the database connection should be done as 
       postgres user 
 (web_usr have not privileges to insert new data into the sed tables)  

 prove sample.t

 this test needs some environment variables:

   export BIOSOURCE_TEST_METALOADER= 'metaloader user'
   export BIOSOURCE_TEST_DBDSN= 'database dsn as: dbi:DriverName:database=database_name;host=hostname;port=port'
   export BIOSOURCE_TEST_DBUSER= 'database user with insert permissions'
   export BIOSOURCE_TEST_DBPASS= 'database password'

 also is recommendable set the reset dbseq after run the script
    export RESET_DBSEQ=1

 if it is not set, after one run all the test that depends of a primary id
 (as metadata_id) will fail because it is calculated based in the last
 primary id and not in the current sequence for this primary id


=head1 DESCRIPTION

 This script check 339 variables to test the right operation of the 
 CXGN::Biosource::Sample module:

  - TEST from 1 to 4 - use Modules.
  - TEST from 5 to 10 - BASIC SET/GET FUNCTION for sample object.
  - TEST from 11 to 21 - TESTING DIE ERROR associated to the basic sample functions.
  - TEST from 22 to 26 - TESTING STORE_SAMPLE FUNCTION
  - TEST from 27 to 29 - TESTING GET_SAMPLE_METADATA FUNCTION,
  - TEST 30 and 31 - TESTING DIE ERROR associated to get_metadbdata
  - TEST from 32 to 36 - TESTING SAMPLE OBSOLETE FUNCTIONS.
  - TEST from 37 to 39 - TESTING DIE ERROR associated to the sample obsolete functions.
  - TEST from 40 to 43 - TESTING STORE_SAMPLE for modifications
  - TEST 44 - TESTING NEW_BY_NAME, checking sample_id
  - TEST from 45 to 90 - TESTING all the SAMPLE_ELEMENT functions
  - TEST from 91 to 111 - TESTING all the SAMPLE_PUB functions
  - TEST from 112 to 156 - TESTING all the SAMPLE_ELEMENT_DBXREF functions
  - TEST from 157 to 201 - TESTING all the SAMPLE_ELEMENT_CVTERM functions
  - TEST from 202 to 249 - TESTING all the SAMPLE_ELEMENT_FILE functions
  - TEST from 250 to 326 - TESTING all the SAMPLE_ELELEMNT RELATION functions
  - TEST from 327 to 334 - TESTING all the GENERAL STORE FUNCTION
  - TEST from 335 to 338 - TESTING get_dbxref_related function

=cut

=head1 AUTHORS

 Aureliano Bombarely Gomez
 (ab782@cornell.edu)

=cut

use strict;
use warnings;

use Test::More;
use Test::Exception;

use CXGN::DB::Connection;


## The tests still need search_path

my @schema_list = ('biosource', 'metadata', 'public');
my $schema_list = join(',', @schema_list);
my $set_path = "SET search_path TO $schema_list";

## First check env. variables and connection

BEGIN {

    ## Env. variables have been changed to use biosource specific ones

    my @env_variables = qw/BIOSOURCE_TEST_METALOADER BIOSOURCE_TEST_DBDSN BIOSOURCE_TEST_DBUSER BIOSOURCE_TEST_DBPASS/;

    ## RESET_DBSEQ is an optional env. variable, it doesn't need to check it

    for my $env (@env_variables) {
        unless (defined $ENV{$env}) {
            plan skip_all => "Environment variable $env not set, aborting";
        }
    }

    eval { 
        CXGN::DB::Connection->new( 
                                   $ENV{BIOSOURCE_TEST_DBDSN}, 
                                   $ENV{BIOSOURCE_TEST_DBUSER}, 
                                   $ENV{BIOSOURCE_TEST_DBPASS}, 
                                   {on_connect_do => $set_path}
                                 ); 
    };

    if ($@ =~ m/DBI connect/) {

        plan skip_all => "Could not connect to database";
    }

    plan tests => 339;
}

BEGIN {
    use_ok('CXGN::Biosource::Schema');
    use_ok('CXGN::Biosource::Sample');
    use_ok('CXGN::Biosource::Protocol');
    use_ok('CXGN::Metadata::Metadbdata');
}


#if we cannot load the CXGN::Metadata::Schema module, no point in continuing
CXGN::Biosource::Schema->can('connect')
    or BAIL_OUT('could not load the CXGN::Biosource::Schema module');
CXGN::Metadata::Schema->can('connect')
    or BAIL_OUT('could not load the CXGN::Metadata::Schema module');
Bio::Chado::Schema->can('connect')
    or BAIL_OUT('could not load the Bio::Chado::Schema module');

## Prespecified variable

my $metadata_creation_user = $ENV{GEMTEST_METALOADER};

## The biosource schema contain all the metadata classes so don't need to create another Metadata schema
## CXGN::DB::DBICFactory is obsolete, it has been replaced by CXGN::Biosource::Schema

my $schema = CXGN::Biosource::Schema->connect( $ENV{BIOSOURCE_TEST_DBDSN}, 
                                               $ENV{BIOSOURCE_TEST_DBUSER}, 
                                               $ENV{BIOSOURCE_TEST_DBPASS}, 
                                               {on_connect_do => $set_path});

$schema->txn_begin();

## Get the last values
my $all_last_ids_href = $schema->get_all_last_ids($schema);
my %last_ids = %{$all_last_ids_href};
my $last_metadata_id = $last_ids{'metadata.md_metadata_metadata_id_seq'};
my $last_sample_id = $last_ids{'biosource.bs_sample_sample_id_seq'};

## Create a empty metadata object to use in the database store functions
my $metadbdata = CXGN::Metadata::Metadbdata->new($schema, $metadata_creation_user);
my $creation_date = $metadbdata->get_object_creation_date();
my $creation_user_id = $metadbdata->get_object_creation_user_by_id();

#######################################
## FIRST TEST BLOCK: Basic functions ##
#######################################

## (TEST FROM 5 to 9)
## This is the first group of tests, to check if an empty object can store and after can return the data
## Create a new empty object; 

my $sample = CXGN::Biosource::Sample->new($schema, undef); 

## Load of the eight different parameters for an empty object using a hash with keys=root name for tha function and
 ## values=value to test

my %test_values_for_empty_object=( sample_id    => $last_sample_id+1,
				   sample_name  => 'sample test',
				   sample_type  => 'test',
				   description  => 'this is a test',
				   contact_id   => $creation_user_id,
                                  );

## Load the data in the empty object
my @function_keys = sort keys %test_values_for_empty_object;
foreach my $rootfunction (@function_keys) {
    my $setfunction = 'set_' . $rootfunction;
    if ($rootfunction eq 'sample_id') {
	$setfunction = 'force_set_' . $rootfunction;
    } 
    $sample->$setfunction($test_values_for_empty_object{$rootfunction});
}
## Get the data from the object and store in two hashes. The first %getdata with keys=root_function_name and 
 ## value=value_get_from_object and the second, %testname with keys=root_function_name and values=name for the test.

my (%getdata, %testnames);
foreach my $rootfunction (@function_keys) {
    my $getfunction = 'get_'.$rootfunction;
    my $data = $sample->$getfunction();
    $getdata{$rootfunction} = $data;
    my $testname = 'BASIC SET/GET FUNCTION for ' . $rootfunction.' test';
    $testnames{$rootfunction} = $testname;
}

## And now run the test for each function and value

foreach my $rootfunction (@function_keys) {
    is($getdata{$rootfunction}, $test_values_for_empty_object{$rootfunction}, $testnames{$rootfunction}) 
	or diag "Looks like this failed.";
}

## Test the set_contact_by_username (TEST 10)

$sample->set_contact_by_username($metadata_creation_user);
my $contact = $sample->get_contact_by_username();
is($sample->get_contact_by_username(), $metadata_creation_user, "BASIC SET/GET FUNCTION for contact_by_username, checking username")
    or diag "Looks like this failed";

## Testing the die results (TEST 11 to 21)

throws_ok { CXGN::Biosource::Sample->new() } qr/PARAMETER ERROR: None schema/, 
    'TESTING DIE ERROR when none schema is supplied to new() function';

throws_ok { CXGN::Biosource::Sample->new($schema, 'no integer')} qr/DATA TYPE ERROR/, 
    'TESTING DIE ERROR when a non integer is used to create a protocol object with new() function';

throws_ok { CXGN::Biosource::Sample->new($schema)->set_bssample_row() } qr/PARAMETER ERROR: None bssample_row/, 
    'TESTING DIE ERROR when none schema is supplied to set_bssample_row() function';

throws_ok { CXGN::Biosource::Sample->new($schema)->set_bssample_row($schema) } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_bssample_row() is not a CXGN::Biosource::Schema::BsSample row object';

throws_ok { CXGN::Biosource::Sample->new($schema)->force_set_sample_id() } qr/PARAMETER ERROR: None sample_id/, 
    'TESTING DIE ERROR when none sample_id is supplied to set_force_sample_id() function';

throws_ok { CXGN::Biosource::Sample->new($schema)->force_set_sample_id('non integer') } qr/DATA TYPE ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_force_sample_id() is not an integer';

throws_ok { CXGN::Biosource::Sample->new($schema)->set_sample_name() } qr/PARAMETER ERROR: None data/, 
    'TESTING DIE ERROR when none data is supplied to set_sample_name() function';

throws_ok { CXGN::Biosource::Sample->new($schema)->set_sample_type() } qr/PARAMETER ERROR: None data/, 
    'TESTING DIE ERROR when none data is supplied to set_sample_type() function';

throws_ok { CXGN::Biosource::Sample->new($schema)->set_contact_id('non integer') } qr/DATA TYPE ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_contact_id() is not an integer';

throws_ok { CXGN::Biosource::Sample->new($schema)->set_contact_by_username() } qr/SET ARGUMENT ERROR: None argument/, 
    'TESTING DIE ERROR when none argument is supplied to set_contact_id()';

throws_ok { CXGN::Biosource::Sample->new($schema)->set_contact_by_username('non existing user: None') } qr/DATABASE COHERENCE ERROR:/, 
    'TESTING DIE ERROR when username supplied to set_contact_id() do not exists into the database';


###############################################################
### SECOND TEST BLOCK: Protocol Store and Obsolete Functions ##
###############################################################

### Use of store functions.

 eval {

     my $sample2 = CXGN::Biosource::Sample->new($schema);
     $sample2->set_sample_name('sample_test');
     $sample2->set_sample_type('test');
     $sample2->set_description('This is a description test');
     $sample2->set_contact_by_username($metadata_creation_user);

     $sample2->store_sample($metadbdata);

     my $curr_metadata_id = $metadbdata->get_metadata_id();
     

     ## Testing the protocol_id and protocol_name for the new object stored (TEST 22 to 26)

     is($sample2->get_sample_id(), $last_sample_id+1, "TESTING STORE_SAMPLE FUNCTION, checking the sample_id")
	 or diag "Looks like this failed";
     is($sample2->get_sample_name(), 'sample_test', "TESTING STORE_SAMPLE FUNCTION, checking the sample_name")
	 or diag "Looks like this failed";
     is($sample2->get_sample_type(), 'test', "TESTING STORE_SAMPLE FUNCTION, checking the sample type")
	 or diag "Looks like this failed";
     is($sample2->get_description(), 'This is a description test', "TESTING STORE_SAMPLE FUNCTION, checking description")
	 or diag "Looks like this failed";
     is($sample2->get_contact_by_username(), $metadata_creation_user, "TESTING STORE_SAMPLE FUNCTION, checking contact by username")
	 or diag "Looks like this failed";

     ## Testing the get_medatata function (TEST 27 to 29)

     my $obj_metadbdata = $sample2->get_sample_metadbdata();
     is($obj_metadbdata->get_metadata_id(), $last_metadata_id+1, "TESTING GET_METADATA FUNCTION, checking the metadata_id")
 	or diag "Looks like this failed";
     is($obj_metadbdata->get_create_date(), $creation_date, "TESTING GET_METADATA FUNCTION, checking create_date")
 	or diag "Looks like this failed";
     is($obj_metadbdata->get_create_person_id_by_username, $metadata_creation_user, 
	"TESING GET_METADATA FUNCTION, checking create_person by username")
 	or diag "Looks like this failed";
    
     ## Testing die for store function (TEST 30 and 31)

     throws_ok { $sample2->store_sample() } qr/STORE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to store_sample() function';

     throws_ok { $sample2->store_sample($schema) } qr/STORE ERROR: Metadbdata supplied/, 
     'TESTING DIE ERROR when argument supplied to store_sample() is not a CXGN::Metadata::Metadbdata object';

     ## Testing if it is obsolete (TEST 32)

     is($sample2->is_sample_obsolete(), 0, "TESTING IS_PROTOCOL_SAMPLE FUNCTION, checking boolean")
 	or diag "Looks like this failed";

     ## Testing obsolete (TEST 33 to 36) 

     $sample2->obsolete_sample($metadbdata, 'testing obsolete');
    
     is($sample2->is_sample_obsolete(), 1, "TESTING SAMPLE_OBSOLETE FUNCTION, checking boolean after obsolete the sample")
 	or diag "Looks like this failed";

     is($sample2->get_sample_metadbdata()->get_metadata_id, $last_metadata_id+2, "TESTING SAMPLE_OBSOLETE, checking metadata_id")
 	or diag "Looks like this failed";

     $sample2->obsolete_sample($metadbdata, 'testing obsolete', 'REVERT');
    
     is($sample2->is_sample_obsolete(), 0, "TESTING REVERT SAMPLE_OBSOLETE FUNCTION, checking boolean after revert obsolete")
 	or diag "Looks like this failed";

     is($sample2->get_sample_metadbdata()->get_metadata_id, $last_metadata_id+3, "TESTING REVERT SAMPLE_OBSOLETE, for metadata_id")
 	or diag "Looks like this failed";

     ## Testing die for obsolete function (TEST 37 to 39)

     throws_ok { $sample2->obsolete_sample() } qr/OBSOLETE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_sample() function';

     throws_ok { $sample2->obsolete_sample($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
     'TESTING DIE ERROR when argument supplied to obsolete_sample() is not a CXGN::Metadata::Metadbdata object';

     throws_ok { $sample2->obsolete_sample($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
     'TESTING DIE ERROR when none obsolete note is supplied to obsolete_sample() function';
    
     ## Testing store for modifications (TEST 40 to 43)

     $sample2->set_description('This is another test');
     $sample2->store_sample($metadbdata);

     is($sample2->get_sample_id(), $last_sample_id+1, "TESTING STORE_SAMPLE for modifications, checking the sample_id")
 	or diag "Looks like this failed";
     is($sample2->get_sample_name(), 'sample_test', "TESTING STORE_SAMPLE for modifications, checking the sample_name")
 	or diag "Looks like this failed";
     is($sample2->get_description(), 'This is another test', "TESTING STORE_SAMPLE for modifications, checking description")
 	or diag "Looks like this failed";

     my $obj_metadbdata2 = $sample2->get_sample_metadbdata();
     is($obj_metadbdata2->get_metadata_id(), $last_metadata_id+4, "TESTING STORE_SAMPLE for modifications, checking new metadata_id")
 	or diag "Looks like this failed";
    

     ## Testing new by name (TEST 44)

     my $sample3 = CXGN::Biosource::Sample->new_by_name($schema, 'sample_test');
     is($sample3->get_sample_id(), $last_sample_id+1, "TESTING NEW_BY_NAME, checking sample_id")
 	or diag "Looks like this failed";



     ############################################
     ## THIRD BLOCK: Sample_Elements functions ##
     ############################################

     ## Testing die functions for set_bsprotocolstep_rows (TEST 45 to 47)

     throws_ok { $sample2->set_bssampleelement_rows() } qr/FUNCTION PARAMETER ERROR: None bs_sample_element_row hash ref/, 
     'TESTING DIE ERROR when none bssampleelement_row hash ref is supplied to set_bssampleelement_rows() function';

     throws_ok { $sample2->set_bssampleelement_rows('test') } qr/SET ARGUMENT ERROR: hash ref./, 
     'TESTING DIE ERROR when bssampleelement_row supplied to set_bssampleelement_rows() function is not a hash reference';

     throws_ok { $sample2->set_bssampleelement_rows({ 'test' => 'test'}) } qr/SET ARGUMENT ERROR: row obj/, 
     'TESTING DIE ERROR when bssampleelement_row hashref supplied to set_bssampleelement_rows() have not BsSampleElement row obj.';

     ## Before test for add_sample_element functions we need to add a new organism in the organis chado table.

     my $organism_row = $schema->resultset('Organism::Organism')
	                       ->new(
	                              {
					  abbreviation => 'G.species',
					  genus        => 'Genus',
					  species      => 'Genus species',
					  common_name  => 'Organism test',
					  comment      => 'testing species',
                                      }
			            )
			       ->insert()
			       ->discard_changes();
     
     my $organism_id = $organism_row->get_column('organism_id');

     ## And a protocol in the protocol table

     my $protocol = CXGN::Biosource::Protocol->new($schema);
     $protocol->set_protocol_name('protocol test');
     $protocol->set_protocol_type('test');
     $protocol->set_description('This is a test too');
     $protocol->store($metadbdata);

     my $protocol_id = $protocol->get_protocol_id();

     ## It will add two sample elements

     $sample3->add_sample_element(    
                                   { 
				       sample_element_name => 'sample element 1',
				       alternative_name    => 'another sample element 1',
				       description         => 'This is a sample element test',
				       organism_id         => $organism_id, 
				       protocol_id         => $protocol_id,
                                   }
 	                         );

     $sample3->add_sample_element(    
                                   { 
				       sample_element_name => 'sample element 2',
				       alternative_name    => 'another sample element 2',
				       description         => 'This is a sample element test',
				       organism_name       => 'Genus species', 
				       protocol_name       => 'protocol test',
                                   }
 	                         );



     my %sample_elements = $sample3->get_sample_elements();

     ## TEST 48 to 56

     is(scalar(keys %sample_elements), 2, "TESTING ADD/GET_SAMPLE_ELEMENTS, checking the sample elements number")
 	or diag "Looks like this failed";

     my $sample_element_name1 = $sample_elements{'sample element 1'}->{sample_element_name};
     my $sample_element_name2 = $sample_elements{'sample element 2'}->{sample_element_name};
     my $alternative_name1 = $sample_elements{'sample element 1'}->{alternative_name};
     my $description2 = $sample_elements{'sample element 2'}->{description};
     my $organism_name1 = $sample_elements{'sample element 1'}->{organism_name};
     my $organism_id2 = $sample_elements{'sample element 2'}->{organism_id};
     my $protocol_name1 = $sample_elements{'sample element 1'}->{protocol_name};
     my $protocol_id2 = $sample_elements{'sample element 2'}->{protocol_id};

     is($sample_element_name1, 'sample element 1', "TESTING ADD/GET_SAMPLE_ELEMENTS, checking sample_element_name for element 1")
	 or diag "Looks like this failed";
     is($sample_element_name2, 'sample element 2', "TESTING ADD/GET_SAMPLE_ELEMENTS, checking sample_element_name for element 2")
	 or diag "Looks like this failed";
     is($alternative_name1, 'another sample element 1', "TESTING ADD/GET_SAMPLE_ELEMENTS, checking alternative_name for element 1")
	  or diag "Looks like this failed";
     is($description2, 'This is a sample element test', "TESTING ADD/GET_SAMPLE_ELEMENTS, checking description for element 2")
	  or diag "Looks like this failed";
     is($organism_name1, 'Genus species', "TESTING ADD/GET_SAMPLE_ELEMENTS, checking organism_name for element 1")
	  or diag "Looks like this failed";
     is($organism_id2, $organism_id, "TESTING ADD/GET_SAMPLE_ELEMENTS, checking organism_id for element 2")
	  or diag "Looks like this failed";
     is($protocol_name1, 'protocol test', "TESTING ADD/GET_SAMPLE_ELEMENTS, checking protocol_name for element 1")
	  or diag "Looks like this failed";
     is($protocol_id2, $protocol_id, "TESTING ADD/GET_SAMPLE_ELEMENTS, checking protocol_id for element 2")
	 or diag "Looks like this failed";
     

     ## testing die for add_sample_element (TEST 57 and 58)

     throws_ok { $sample3->add_sample_element() } qr/FUNCTION PARAMETER ERROR: None data/, 
     'TESTING DIE ERROR when none data is supplied to add_sample_element() function';

     throws_ok { $sample3->add_sample_element('test') } qr/DATA TYPE ERROR: The parameter hash ref/, 
     'TESTING DIE ERROR when data type supplied to add_sample_element() function is not a hash reference';

     ## testing the edit function (edit_sample_element) (TEST 59)

     $sample3->edit_sample_element( $sample_element_name1, { alternative_name => 'other sample element for 1' } );
    
     my %sample_elements3 = $sample3->get_sample_elements();
     my $edited_alternative_name = $sample_elements3{$sample_element_name1}->{alternative_name};
     is($edited_alternative_name, 'other sample element for 1', "TESTING EDIT_SAMPLE_ELEMENT, checking sample_element alternative name")
 	or diag "Looks like this failed";

     ## testing die for edit_sample_elements (TEST 60 to 62)

     throws_ok { $sample3->edit_sample_element() } qr/FUNCTION PARAMETER ERROR: None data/, 
     'TESTING DIE ERROR when none data is supplied to edit_sample_element() function';

     throws_ok { $sample3->edit_sample_element($sample_element_name1) } qr/FUNCTION PARAMETER ERROR: None parameter hash/, 
     'TESTING DIE ERROR when none parameter hash reference is supplied to edit_sample_element() function';
  
     throws_ok { $sample3->edit_sample_element($sample_element_name1, ["not hash","not aref"]) } qr/DATA TYPE ERROR: The parameter hash/, 
     'TESTING DIE ERROR when parameter hash reference supplied to edit_sample_element() function is not an hash reference';

     ## Store function for sample_elements (TEST 63 and 64)

     $sample3->store_sample_elements($metadbdata);
    
     my %sample_elements3_as = $sample3->get_sample_elements();
     my $sample_element_metadata_id1 = $sample_elements3_as{$sample_element_name1}->{metadata_id};
     my $sample_element_metadata_id2 = $sample_elements3_as{$sample_element_name2}->{metadata_id};
     
     is($sample_element_metadata_id1, $last_metadata_id+1, "TESTING STORE_SAMPLE_ELEMENT, checking the metadata_id (for element 1)")
 	or diag "Looks like this failed";
     is($sample_element_metadata_id2, $last_metadata_id+1, "TESTING STORE_SAMPLE_ELEMENT, checking the metadata_id (for element 2)")
 	or diag "Looks like this failed";
    
     ## Checkig getting a new object using new_by_elements (TEST 65)

     my $sample4 = CXGN::Biosource::Sample->new_by_elements($schema, [$sample_element_name1, $sample_element_name2] );
    
     is($sample4->get_sample_id(), $sample3->get_sample_id(), "TESTING NEW_BY_ELEMENT and STORE_SAMPLE_ELEMENT, checking sample_id")
	 or diag "Looks like this failed";


     ## This sample object should have the data associated to the sample_element in sample3 (TEST 66 and 69)

     my %sample_elements4 = $sample4->get_sample_elements();
     
     ## To get the elements names
     my @elements = keys %sample_elements4;

     my $alt_name4_for1 = $sample_elements4{$elements[0]}->{alternative_name};
     my $alt_name4_for2 = $sample_elements4{$elements[1]}->{alternative_name};
     my $organism4_for1 = $sample_elements4{$elements[0]}->{organism_name};
     my $protocol4_for2 = $sample_elements4{$elements[1]}->{protocol_name};
      
     is($alt_name4_for1, 'other sample element for 1', "TESTING STORE_SAMPLE_ELEMENT, checking the sample_element alt_name for element 1")
 	or diag "Looks like this failed";
     is($alt_name4_for2, 'another sample element 2', "TESTING STORE_SAMPLE_ELEMENT, checking the sample_element alt_name for element 2")
 	or diag "Looks like this failed";
     is($organism4_for1, 'Genus species', "TESTING STORE_SAMPLE_ELEMENT, checking the sample_element organism for element 1")
 	or diag "Looks like this failed";
     is($protocol4_for2, 'protocol test', "TESTING STORE_SAMPLE_ELEMENT, checking the sample_element protocol for element 2")
 	or diag "Looks like this failed";
    
    ## Testing the die for the store_sample_element function, to do it i will create an empty object
    ## without any sample_id (TEST 70 to 72)
    
     my $sample5 = CXGN::Biosource::Sample->new($schema);
     $sample5->set_sample_name('sample_test_for_exceptions');
     $sample5->set_sample_type('another test');
     $sample5->add_sample_element(
                                   { 
				       sample_element_name => 'sample element 3',
				       alternative_name    => 'another sample element 3',
				       description         => 'This is a sample element test',
				       organism_name       => 'Genus species', 
				       protocol_name       => 'protocol test', 
                                   }
                                  );

     throws_ok { $sample5->store_sample_elements() } qr/STORE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to store_sample_element() function';

     throws_ok { $sample5->store_sample_elements($schema) } qr/STORE ERROR: Metadbdata supplied/, 
     'TESTING DIE ERROR when metadbdata object supplied to store_sample_element() function is not a CXGN::Metadata::Metadbdata object';

     throws_ok { $sample5->store_sample_elements($metadbdata) } qr/STORE ERROR: Don't exist sample_id/, 
     'TESTING DIE ERROR when do not exists sample_id associated to the sample_element data';
    
     ## Testing the function get_sample_element_metadata (TEST 73 to 76)

     my %element_metadata = $sample4->get_sample_element_metadbdata($metadbdata);
     my $element_metadata_id1 = $element_metadata{$sample_element_name1}->get_metadata_id();
     my $element_metadata_id2 = $element_metadata{$sample_element_name2}->get_metadata_id();
     my $element_creation_date1 = $element_metadata{$sample_element_name1}->get_create_date();
     my $element_creation_date2 = $element_metadata{$sample_element_name2}->get_create_date();

     is ($element_metadata_id1, $last_metadata_id+1, "TESTING GET_SAMPLE_ELEMENT_METADBDATA, checking metadata_id for element 1")
 	or diag "Looks like this failed";
     is ($element_metadata_id2, $last_metadata_id+1, "TESTING GET_SAMPLE_ELEMENT_METADBDATA, checking metadata_id for element 2")
 	or diag "Looks like this failed";
     is ($element_creation_date1, $creation_date, "TESTING GET_SAMPLE_ELEMENT_METADBDATA, checking creation_date for element 1")
 	or diag "Looks like this failed";
     is ($element_creation_date2, $creation_date, "TESTING GET_SAMPLE_ELEMENT_METADBDATA, checking creation_date for element 2")
 	or diag "Looks like this failed";

     ## Testing error for get_sample_element_metadbdata (TEST 77)

      throws_ok { $sample5->get_sample_element_metadbdata($metadbdata) } qr/OBJECT MANIPULATION ERROR: The object/, 
     'TESTING DIE ERROR when do not exists sample_id associated to the sample_element data and try to get metadbdata object';

     ## Testing edit function and store as modification of the data (TEST 78 and 81)

     $sample4->edit_sample_element( $sample_element_name1, { alternative_name => 'another change test' } );
     $sample4->store_sample_elements($metadbdata);

     my $sample6 = CXGN::Biosource::Sample->new($schema, $sample4->get_sample_id() );
     my %sample_elements6 = $sample6->get_sample_elements();
     
     my $element6_metadata_id1 = $sample_elements6{$sample_element_name1}->{metadata_id};
     my $element6_metadata_id2 = $sample_elements6{$sample_element_name2}->{metadata_id};
     my $element6_alt_name1 = $sample_elements6{$sample_element_name1}->{alternative_name};
     my $element6_alt_name2 = $sample_elements6{$sample_element_name2}->{alternative_name};
      
     is($element6_metadata_id1, $last_metadata_id+5, "TESTING STORE_SAMPLE_ELEMENT for modification, checking metadata_id for element 1")
 	or diag "Looks like this failed";
     is($element6_metadata_id2, $last_metadata_id+1, "TESTING STORE_SAMPLE_ELEMENT for modification, checking metadata_id for element 2")
 	or diag "Looks like this failed";
     is($element6_alt_name1, 'another change test', "TESTING STORE_SAMPLE_ELEMENT for modification, checking alt_name for element 1")
 	or diag "Looks like this failed";
     is($element6_alt_name2, 'another sample element 2', "TESTING STORE_SAMPLE_ELEMENT for modification, checking alt_name for element 2")
 	or diag "Looks like this failed";
  

     ## Testing obsolete functions (TEST 82 to 86)

     is($sample6->is_sample_element_obsolete($sample_element_name2), 0, "TESTING IS_SAMPLE_ELEMENT_OBSOLETE, checking boolean")
 	or diag "Looks like this failed";
    
     $sample6->obsolete_sample_element($metadbdata, 'obsolete_test', $sample_element_name2);

     my %sample_elements6_ob1 = $sample6->get_sample_elements();
     
     my $element6_metadata_id2_ob1 = $sample_elements6_ob1{$sample_element_name2}->{metadata_id};

     is($sample6->is_sample_element_obsolete($sample_element_name2), 1, "TESTING OBSOLETE_SAMPLE_ELEMENT, checking boolean")
 	or diag "Looks like this failed";

     is($element6_metadata_id2_ob1, $last_metadata_id+6, "TESTING OBSOLETE_SAMPLE_ELEMENT, checking new metadata_id")
	 or diag "Looks like this failed";

     $sample6->obsolete_sample_element($metadbdata, 'obsolete_test', $sample_element_name2, 'REVERT');

     my %sample_elements6_ob2 = $sample6->get_sample_elements();
     
     my $element6_metadata_id2_ob2 = $sample_elements6_ob2{$sample_element_name2}->{metadata_id};

     is($sample6->is_sample_element_obsolete($sample_element_name2), 0, "TESTING OBSOLETE_SAMPLE_ELEMENT REVERT, checking boolean")
 	or diag "Looks like this failed";

     is($element6_metadata_id2_ob2, $last_metadata_id+7, "TESTING OBSOLETE_SAMPLE_ELEMENT, checking new metadata_id")
	 or diag "Looks like this failed";

     ## Testing Die conditions for obsolete functions (TEST 87 to 90)

     throws_ok { $sample6->obsolete_sample_element() } qr/OBSOLETE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_sample_element() function';

     throws_ok { $sample6->obsolete_sample_element($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
     'TESTING DIE ERROR when argument supplied to obsolete_sample_element() is not a CXGN::Metadata::Metadbdata object';

     throws_ok { $sample6->obsolete_sample_element($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
     'TESTING DIE ERROR when none obsolete note is supplied to obsolete_sample_element() function';

     throws_ok { $sample6->obsolete_sample_element($metadbdata, 'obsolete note') } qr/OBSOLETE ERROR: None sample_element_name/, 
     'TESTING DIE ERROR when none sample_element_name is supplied to obsolete_sample_element() function';


     #######################################
     ## FORTH BLOCK: Sample_Pub functions ##
     #######################################

     ## Testing of the publication

     ## Testing the die when the wrong for the row accessions get/set_bssamplepub_rows (TEST 91 to 93)
    
     throws_ok { $sample5->set_bssamplepub_rows() } qr/FUNCTION PARAMETER ERROR: None bssamplepub_row/, 
     'TESTING DIE ERROR when none data is supplied to set_bssamplepub_rows() function';

     throws_ok { $sample5->set_bssamplepub_rows('this is not an integer') } qr/SET ARGUMENT ERROR:/, 
     'TESTING DIE ERROR when data type supplied to set_bssamplepub_rows() function is not an array reference';

     throws_ok { $sample5->set_bssamplepub_rows([$schema, $schema]) } qr/SET ARGUMENT ERROR:/, 
     'TESTING DIE ERROR when the elements of the array reference supplied to set_bssamplepub_rows() function are not row objects';


     ## First, it need to add all the rows that the chado schema use for a publication
 
     my $new_db_id = $schema->resultset('General::Db')
                             ->new( 
                                    { 
                                      name        => 'dbtesting',
                                      description => 'this is a test for add a tool-pub relation',
                                      urlprefix   => 'http//.',
                                      url         => 'www.testingdb.com'
                                    }
                                  )
                              ->insert()
                              ->discard_changes()
                              ->get_column('db_id');

     my $new_dbxref_id1 = $schema->resultset('General::Dbxref')
                                 ->new( 
                                         { 
                                           db_id       => $new_db_id,
                                           accession   => 'TESTDBACC01',
                                           version     => '1',
                                           description => 'this is a test for add a tool-pub relation',
                                         }
                                       )
                                  ->insert()
                                  ->discard_changes()
                                  ->get_column('dbxref_id');

     my $new_dbxref_id2 = $schema->resultset('General::Dbxref')
                                 ->new( 
                                         { 
                                           db_id       => $new_db_id,
                                           accession   => 'TESTDBACC02',
                                           version     => '1',
                                           description => 'this is a test for add a tool-pub relation',
                                         }
                                       )
                                  ->insert()
                                  ->discard_changes()
                                  ->get_column('dbxref_id');

     my $new_cv_id = $schema->resultset('Cv::Cv')
                             ->new( 
                                    { 
                                       name       => 'testingcv', 
                                       definition => 'this is a test for add a tool-pub relation',
                                    }
                                  )
                             ->insert()
                             ->discard_changes()
                             ->get_column('cv_id');

      my $new_cvterm_id1 = $schema->resultset('Cv::Cvterm')
                                 ->new( 
                                    { 
                                       cv_id      => $new_cv_id,
                                       name       => 'testingcvterm1',
                                       definition => 'this is a test for add tool-pub relation',
                                       dbxref_id  => $new_dbxref_id1,
                                    }
                                  )
                             ->insert()
                             ->discard_changes()
                             ->get_column('cvterm_id');

     my $new_cvterm_id2 = $schema->resultset('Cv::Cvterm')
                                 ->new( 
                                    { 
                                       cv_id      => $new_cv_id,
                                       name       => 'testingcvterm2',
                                       definition => 'this is a test for add tool-pub relation',
                                       dbxref_id  => $new_dbxref_id2,
                                    }
                                  )
                             ->insert()
                             ->discard_changes()
                             ->get_column('cvterm_id');

      my $new_pub_id1 = $schema->resultset('Pub::Pub')
                               ->new( 
                                     { 
                                          title          => 'testingtitle1',
                                          uniquename     => '00000:testingtitle1',   
                                          type_id        => $new_cvterm_id1,
                                      }
                                    )
                               ->insert()
                               ->discard_changes()
                               ->get_column('pub_id');

     my $new_pub_id2 = $schema->resultset('Pub::Pub')
                               ->new( 
                                       { 
                                         title          => 'testingtitle2',
                                         uniquename     => '00000:testingtitle2',   
                                         type_id        => $new_cvterm_id1,
                                       }
                                     )
                               ->insert()
                               ->discard_changes()
                               ->get_column('pub_id');

      my $new_pub_id3 = $schema->resultset('Pub::Pub')
                                ->new( 
                                       { 
                                         title          => 'testingtitle3',
                                         uniquename     => '00000:testingtitle3',   
                                         type_id        => $new_cvterm_id1,
                                       }
                                     )
                                ->insert()
                                ->discard_changes()
                                ->get_column('pub_id');

      my @pub_list = ($new_pub_id1, $new_pub_id2, $new_pub_id3);
 
      my $new_pub_dbxref = $schema->resultset('Pub::PubDbxref')
                                  ->new( 
                                          { 
                                            pub_id    => $new_pub_id3,
                                            dbxref_id => $new_dbxref_id1,   
                                          }
                                        )
                                  ->insert();

     ## TEST 94 AND 95

     $sample6->add_publication($new_pub_id1);
     $sample6->add_publication({ title => 'testingtitle2' });
     $sample6->add_publication({ dbxref_accession => 'TESTDBACC01' });

     my @pub_id_list = $sample6->get_publication_list();
     my $expected_pub_id_list = join(',', sort {$a <=> $b} @pub_list);
     my $obtained_pub_id_list = join(',', sort {$a <=> $b} @pub_id_list);

     is($obtained_pub_id_list, $expected_pub_id_list, 'TESTING ADD_PUBLICATION and GET_PUBLICATION_LIST, checking pub_id list')
          or diag "Looks like this failed";

     my @pub_title_list = $sample6->get_publication_list('title');
     my $expected_pub_title_list = 'testingtitle1,testingtitle2,testingtitle3';
     my $obtained_pub_title_list = join(',', sort @pub_title_list);
    
     is($obtained_pub_title_list, $expected_pub_title_list, 'TESTING GET_PUBLICATION_LIST TITLE, checking pub_title list')
          or diag "Looks like this failed";


     ## Only the third pub has associated a dbxref_id (the rest will be undef) (TEST 96)
     my @pub_accession_list = $sample6->get_publication_list('accession');
     my $expected_pub_accession_list = 'TESTDBACC01';
     my $obtained_pub_accession_list = $pub_accession_list[2];   
    
     is($obtained_pub_accession_list, $expected_pub_accession_list, 'TESTING GET_PUBLICATION_LIST ACCESSION, checking pub_accession list')
 	or diag "Looks like this failed";


     ## Store functions (TEST 97)

     $sample6->store_pub_associations($metadbdata);
     
     my $sample7 = CXGN::Biosource::Sample->new($schema, $sample6->get_sample_id() );
     
     my @pub_id_list2 = $sample7->get_publication_list();
     my $expected_pub_id_list2 = join(',', sort {$a <=> $b} @pub_list);
     my $obtained_pub_id_list2 = join(',', sort {$a <=> $b} @pub_id_list2);
    
     is($obtained_pub_id_list2, $expected_pub_id_list2, 'TESTING STORE PUB ASSOCIATIONS, checking pub_id list')
	 or diag "Looks like this failed";
    
     ## Testing die for store function (TEST 98 AND 99)
    
     throws_ok { $sample6->store_pub_associations() } qr/STORE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to store_pub_associations() function';
    
     throws_ok { $sample6->store_pub_associations($schema) } qr/STORE ERROR: Metadbdata supplied/, 
     'TESTING DIE ERROR when argument supplied to store_pub_associations() is not a CXGN::Metadata::Metadbdata object';

     ## Testing obsolete functions (TEST 100 to 103)
     
     my $n = 0;
     foreach my $pub_assoc (@pub_id_list2) {
          $n++;
          is($sample7->is_sample_pub_obsolete($pub_assoc), 0, 
 	    "TESTING GET_SAMPLE_PUB_METADATA AND IS_SAMPLE_PUB_OBSOLETE, checking boolean ($n)")
              or diag "Looks like this failed";
     }

     my %samplepub_md1 = $sample7->get_sample_pub_metadbdata();
     is($samplepub_md1{$pub_id_list[1]}->get_metadata_id, $last_metadata_id+1, "TESTING GET_SAMPLE_PUB_METADATA, checking metadata_id")
	 or diag "Looks like this failed";

     ## TEST 104 TO 107

     $sample7->obsolete_pub_association($metadbdata, 'obsolete test', $pub_id_list[1]);
     is($sample7->is_sample_pub_obsolete($pub_id_list[1]), 1, "TESTING OBSOLETE PUB ASSOCIATIONS, checking boolean") 
          or diag "Looks like this failed";

     my %samplepub_md2 = $sample7->get_sample_pub_metadbdata();
     is($samplepub_md2{$pub_id_list[1]}->get_metadata_id, $last_metadata_id+8, "TESTING OBSOLETE PUB FUNCTION, checking new metadata_id")
	 or diag "Looks like this failed";

     $sample7->obsolete_pub_association($metadbdata, 'obsolete test', $pub_id_list[1], 'REVERT');
     is($sample7->is_sample_pub_obsolete($pub_id_list[1]), 0, "TESTING OBSOLETE PUB ASSOCIATIONS REVERT, checking boolean") 
          or diag "Looks like this failed";

     my %samplepub_md2o = $sample7->get_sample_pub_metadbdata();
     my $samplepub_metadata_id2 = $samplepub_md2o{$pub_id_list[1]}->get_metadata_id();
     is($samplepub_metadata_id2, $last_metadata_id+9, "TESTING OBSOLETE PUB FUNCTION REVERT, checking new metadata_id")
	 or diag "Looks like this failed";

     ## Checking the errors for obsolete_pub_asociation (TEST 108 TO 111)
    
     throws_ok { $sample7->obsolete_pub_association() } qr/OBSOLETE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_pub_association() function';

     throws_ok { $sample7->obsolete_pub_association($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
     'TESTING DIE ERROR when argument supplied to obsolete_pub_association() is not a CXGN::Metadata::Metadbdata object';
    
     throws_ok { $sample7->obsolete_pub_association($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
     'TESTING DIE ERROR when none obsolete note is supplied to obsolete_pub_association() function';
    
     throws_ok { $sample7->obsolete_pub_association($metadbdata, 'test note') } qr/OBSOLETE ERROR: None pub_id/, 
     'TESTING DIE ERROR when none pub_id is supplied to obsolete_pub_association() function';

    

    
     ##################################################
     ## FIFTH BLOCK: Sample_Element_Dbxref functions ##
     ##################################################

     ## Check if the set_bssampleelementdbxref_rows die correctly (TEST 112 TO 115)

     throws_ok { $sample7->set_bssampleelementdbxref_rows() } qr/FUNCTION PARAMETER ERROR: None bssampleelementdbxref_row/, 
     'TESTING DIE ERROR when none data is supplied to set_bssampleelementdbxref_rows() function';

     throws_ok { $sample7->set_bssampleelementdbxref_rows('this is not an integer') } qr/SET ARGUMENT ERROR:/, 
     'TESTING DIE ERROR when data type supplied to set_bssampleelementdbxref_rows() function is not an hash reference';

     throws_ok { $sample7->set_bssampleelementdbxref_rows({ 1 => $schema}) } qr/SET ARGUMENT ERROR:/, 
     'TESTING DIE ERROR when the elements of the hash reference supplied to set_bssampleelementdbxref_rows() function are not array ref.';

     throws_ok { $sample7->set_bssampleelementdbxref_rows({ 1 => [$schema] }) } qr/SET ARGUMENT ERROR:/, 
     "TESTING DIE ERROR when the elements of the array reference supplied to set_bssampleelementdbxref_rows() function aren't a row obj.";
    
     ## Check if add_dbxref_to_sample_element die correctly (TEST 116 TO 120)
    
     my $a = $sample_element_name1;
     my $b = $sample_element_name2;

     throws_ok { $sample7->add_dbxref_to_sample_element() } qr/FUNCTION PARAMETER ERROR: None data/, 
     'TESTING DIE ERROR when none data is supplied to add_dbxref_to_sample_element() function';

     throws_ok { $sample7->add_dbxref_to_sample_element($a) } qr/FUNCTION PARAMETER ERROR: None dbxref_id/, 
     'TESTING DIE ERROR when none dbxref_id is supplied to add_dbxref_to_sample_element() function';

     throws_ok { $sample7->add_dbxref_to_sample_element($a, 'this is not an integer') } qr/DATA TYPE ERROR: Dbxref_id parameter/, 
     'TESTING DIE ERROR when dbxref_id supplied to add_dbxref_to_sample_element() function is not an integer';

     throws_ok { $sample7->add_dbxref_to_sample_element($a, $new_dbxref_id2+1) } qr/DATABASE COHERENCE ERROR: Dbxref_id/, 
     'TESTING DIE ERROR when dbxref_id supplied to add_dbxref_to_sample_element() do not exists into the database';

     throws_ok { $sample7->add_dbxref_to_sample_element('none', $new_dbxref_id2) } qr/DATA OBJECT COHERENCE ERROR: Element_sample_name/, 
     'TESTING DIE ERROR when element_sample_name supplied to add_dbxref_to_sample_element() do not exists into the object';
     
    
     ## Adding dbxref_id to protocol steps (we will create to different dbxref_id to do it)
     ## It will add two dbxref to the first step (TESTDBACC01 and TEST_DBXREFSTEP01) and one to the second (TEST_DBXREFSTEP02)

     my $t_dbxref_id1 = $schema->resultset('General::Dbxref')
                               ->new( 
                                      { 
                                        db_id       => $new_db_id,
                                        accession   => 'TEST_DBXREFSTEP01',
                                        version     => '1',
                                        description => 'this is a test for add a step dbxref relation',
                                      }
                                     )
                               ->insert()
                               ->discard_changes()
                               ->get_column('dbxref_id');

     my $t_dbxref_id2 = $schema->resultset('General::Dbxref')
                               ->new( 
                                      { 
                                        db_id       => $new_db_id,
                                        accession   => 'TEST_DBXREFSTEP02',
                                        version     => '1',
                                        description => 'this is a test for add a step dbxref relation',
                                      } 
                                    )
			       ->insert()
			       ->discard_changes()
			       ->get_column('dbxref_id');
     
     # TEST 121 TO 125

     $sample7->add_dbxref_to_sample_element($sample_element_name1, $new_dbxref_id1);
     $sample7->add_dbxref_to_sample_element($sample_element_name1, $t_dbxref_id1);
     $sample7->add_dbxref_to_sample_element($sample_element_name2, $t_dbxref_id2);

     my %bs_el_dbxref = $sample7->get_dbxref_from_sample_elements();
     is(scalar(@{$bs_el_dbxref{$sample_element_name1}}), 2, "TESTING ADD/GET_DBXREF_TO_SAMPLE_ELEMENT, checking dbxref count (1)")
 	or diag "Looks like this failed";
     is(scalar(@{$bs_el_dbxref{$sample_element_name2}}), 1, "TESTING ADD/GET_DBXREF_TO_SAMPLE_ELEMENT, checking dbxref count (2)")
 	or diag "Looks like this failed";
     is($bs_el_dbxref{$sample_element_name1}->[0],$new_dbxref_id1, "TESTING ADD/GET_DBXREF_TO_SAMPLE_ELEMENT, checking 1st dbxref_id (1)")
 	or diag "Looks like this failed";
     is($bs_el_dbxref{$sample_element_name1}->[1], $t_dbxref_id1, "TESTING ADD/GET_DBXREF_TO_SAMPLE_ELEMENT, checking 2nd dbxref_id (1)")
 	or diag "Looks like this failed";
     is($bs_el_dbxref{$sample_element_name2}->[0], $t_dbxref_id2, "TESTING ADD/GET_DBXREF_TO_SAMPLE_ELEMENT, checking 1st dbxref_id (2)")
 	or diag "Looks like this failed";

     ## Check the store functions for the step dbxref associations:

     ## First, check that the process die correctly (TEST 126 AND 127)

     throws_ok { $sample7->store_element_dbxref_associations() } qr/STORE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to store_element_dbxref_associations() function';
    
     throws_ok { $sample7->store_element_dbxref_associations($schema) } qr/STORE ERROR: Metadbdata supplied/, 
     'TESTING DIE ERROR when argument supplied to store_element_dbxref_associations() is not a CXGN::Metadata::Metadbdata object';

     ## TEST 128 TO 132

     $sample7->store_element_dbxref_associations($metadbdata);

     my $sample8 = CXGN::Biosource::Sample->new($schema, $sample7->get_sample_id() );
     my %se_dbxref8 = $sample8->get_dbxref_from_sample_elements();
     is(scalar(@{$se_dbxref8{$sample_element_name1}}), 2, "TESTING STORE_ELEMENT_DBXREF_ASSOCIATION, checking dbxref count (1)")
	 or diag "Looks like this failed";
     is(scalar(@{$se_dbxref8{$sample_element_name2}}), 1, "TESTING STORE_ELEMENT_DBXREF_ASSOCIATION, checking dbxref count (2)")
	 or diag "Looks like this failed";
     is($se_dbxref8{$sample_element_name1}->[0], $new_dbxref_id1, "TESTING STORE_ELEMENT_DBXREF_ASSOCIATION, checking 1st dbxref_id (1)")
	 or diag "Looks like this failed";
     is($se_dbxref8{$sample_element_name1}->[1], $t_dbxref_id1, "TESTING STORE_ELEMENT_DBXREF_ASSOCIATION, checking 2nd dbxref_id (1)")
	 or diag "Looks like this failed";
     is($se_dbxref8{$sample_element_name2}->[0], $t_dbxref_id2, "TESTING STORE_ELEMENT_DBXREF_ASSOCIATION, checking 1st dbxref_id (2)")
	 or diag "Looks like this failed";

     ## Testing when another dbxref_id is added (TEST 133 AND 134)

     $sample8->add_dbxref_to_sample_element($sample_element_name1, $new_dbxref_id2);
     $sample8->store_element_dbxref_associations($metadbdata);

     my $sample9 = CXGN::Biosource::Sample->new($schema, $sample8->get_sample_id() );
     my %se_dbxref9 = $sample9->get_dbxref_from_sample_elements();
     is(scalar(@{$se_dbxref9{$sample_element_name1}}), 3, "TESTING STORE_ELEMENT_DBXREF_ASSOCIATION dbxref, checking dbxref count (1)")
 	or diag "Looks like this failed";
     is(scalar(@{$se_dbxref9{$sample_element_name2}}), 1, "TESTING STORE_ELEMENT_DBXREF_ASSOCIATION dbxref, checking dbxref count (2)")
 	or diag "Looks like this failed";

     ## Testing metadbdata methods

     ## First, check if it die correctly (TEST 135)

     my $sample10 = CXGN::Biosource::Sample->new($schema);
     $sample10->set_sample_name('sample_test_for_exceptions');
     $sample10->set_sample_type('test');
     $sample10->add_sample_element({ sample_element_name => 'element_test', organism_name => 'Genus species'});
     $sample10->add_dbxref_to_sample_element('element_test', $t_dbxref_id2);

     throws_ok { $sample10->get_element_dbxref_metadbdata() } qr/OBJECT MANIPULATION ERROR:It haven't/, 
     'TESTING DIE ERROR when try to get metadata using get_element_dbxref_metadbdata from obj. where element_dbxref has not been stored';

     ## Second test the metadata for the data stored (TEST 136 TO 144)

     my %dbxref_metadbdata = $sample9->get_element_dbxref_metadbdata();
     my $metadbdata_se1dbxref1 = $dbxref_metadbdata{$sample_element_name1}->{$new_dbxref_id1};
     my $metadbdata_se1dbxref2 = $dbxref_metadbdata{$sample_element_name1}->{$t_dbxref_id1};
     my $metadbdata_se1dbxref3 = $dbxref_metadbdata{$sample_element_name1}->{$new_dbxref_id2};
     my $metadbdata_se2dbxref1 = $dbxref_metadbdata{$sample_element_name2}->{$t_dbxref_id2};

     is($metadbdata_se1dbxref1->get_metadata_id(), $last_metadata_id+1, "TESTING GET_STEP_DBXREF_METADBDATA, checking metadata_id (1-1)")
 	or diag "Looks like this failed";
     is($metadbdata_se1dbxref2->get_metadata_id(), $last_metadata_id+1, "TESTING GET_STEP_DBXREF_METADBDATA, checking metadata_id (1-2)")
 	or diag "Looks like this failed";
     is($metadbdata_se1dbxref3->get_metadata_id(), $last_metadata_id+1, "TESTING GET_STEP_DBXREF_METADBDATA, checking metadata_id (1-3)")
 	or diag "Looks like this failed";
     is($metadbdata_se2dbxref1->get_metadata_id(), $last_metadata_id+1, "TESTING GET_STEP_DBXREF_METADBDATA, checking metadata_id (2-1)")
 	or diag "Looks like this failed";
     is($metadbdata_se1dbxref1->get_create_date(), $creation_date, "TESTING GET_STEP_DBXREF_METADBDATA, checking creation date (1-1)")
 	or diag "Looks like this failed";
     is($metadbdata_se1dbxref2->get_create_date(), $creation_date, "TESTING GET_STEP_DBXREF_METADBDATA, checking creation date (1-2)")
 	or diag "Looks like this failed";
     is($metadbdata_se1dbxref3->get_create_date(), $creation_date, "TESTING GET_STEP_DBXREF_METADBDATA, checking creation date (1-3)")
 	or diag "Looks like this failed";
     is($metadbdata_se2dbxref1->get_create_date(), $creation_date, "TESTING GET_STEP_DBXREF_METADBDATA, checking creation date (2-1)")
 	or diag "Looks like this failed";

     is($sample9->is_element_dbxref_obsolete($sample_element_name2, $t_dbxref_id2),0,"TESTING IS_ELEMENT_DBXREF_OBSOLETE, check boolean")
 	or diag "Looks like this failed";
    

     ## Testing obsolete methods (TEST 145 TO 152)

     throws_ok { $sample9->obsolete_element_dbxref_association() } qr/OBSOLETE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_element_dbxref_association() function';

     throws_ok { $sample9->obsolete_element_dbxref_association($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
     'TESTING DIE ERROR when argument supplied to obsolete_element_dbxref_association() is not a CXGN::Metadata::Metadbdata object';
   
     throws_ok { $sample9->obsolete_element_dbxref_association($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
     'TESTING DIE ERROR when none obsolete note is supplied to obsolete_element_dbxref_association() function';
    
     throws_ok { $sample9->obsolete_element_dbxref_association($metadbdata,'note') } qr/OBSOLETE ERROR: None element_name/, 
     'TESTING DIE ERROR when none step is supplied to obsolete_element_dbxref_association() function';
     
     throws_ok { $sample9->obsolete_element_dbxref_association($metadbdata,'note',$sample_element_name1)} qr/OBSOLETE ERROR: None dbxr/, 
     'TESTING DIE ERROR when none dbxref_id is supplied to obsolete_element_dbxref_association() function';
     
     throws_ok { $sample9->obsolete_element_dbxref_association($metadbdata,'note','none',$t_dbxref_id2+1) } qr/DATA COHERENCE ERROR/, 
     'TESTING DIE ERROR when the sample_element and dbxref_id supplied to obsolete_element_dbxref_association() do not exist inside obj.';

     throws_ok { $sample9->obsolete_element_dbxref_association($metadbdata,'note',$sample_element_name1,$t_dbxref_id2+1) } qr/DATA COHE/, 
     'TESTING DIE ERROR when the dbxref_id supplied to obsolete_element_dbxref_association() function do not exist inside obj.';

     throws_ok { $sample9->obsolete_element_dbxref_association($metadbdata,'note','none',$t_dbxref_id2) } qr/DATA COHERENCE ERROR/, 
     'TESTING DIE ERROR when the sample_element supplied to obsolete_element_dbxref_association() function do not exist inside obj.';

     ## TEST 153 TO 156

     $sample9->obsolete_element_dbxref_association($metadbdata, 'obsolete test', $sample_element_name1, $new_dbxref_id2);
    
     is($sample9->is_element_dbxref_obsolete($sample_element_name1, $new_dbxref_id2), 1, 
	"TESTING OBSOLETE_STEP_DBXREF_ASSOCIATION, checking boolean")
 	or diag "Looks like this failed";
    
     my %se_dbxref_metadbdata_obs = $sample9->get_element_dbxref_metadbdata();
     my $metadbdata_obs = $se_dbxref_metadbdata_obs{$sample_element_name1}->{$new_dbxref_id2};

     $sample9->obsolete_element_dbxref_association($metadbdata, 'obsolete test', $sample_element_name1, $new_dbxref_id2, 'REVERT');

     is($metadbdata_obs->get_metadata_id(), $last_metadata_id+8,"TESTING OBSOLETE_ELEMENT_DBXREF_ASSOCIATION, metadata_id")
 	or diag "Looks like this failed";

     is($sample9->is_element_dbxref_obsolete($sample_element_name1, $new_dbxref_id2), 0, 
	"TESTING OBSOLETE_ELEMENT_DBXREF_ASSOCIATION REVERT, checking boolean")
 	or diag "Looks like this failed";

     my %se_dbxref_metadbdata_rev = $sample9->get_element_dbxref_metadbdata();
     my $metadbdata_rev = $se_dbxref_metadbdata_rev{$sample_element_name1}->{$new_dbxref_id2};

     is($metadbdata_rev->get_metadata_id(), $last_metadata_id+9,"TESTING OBSOLETE_ELEMENT_DBXREF_ASSOCIATION REVERT, metadata_id")
 	or diag "Looks like this failed";

    
     ##################################################
     ## SIXTH BLOCK: Sample_Element_Cvterm functions ##
     ##################################################

     ## Check if the set_bssampleelementcvterm_rows die correctly (TEST 157 TO 160)

     throws_ok { $sample7->set_bssampleelementcvterm_rows() } qr/FUNCTION PARAMETER ERROR: None bssampleelementcvterm_row/, 
     'TESTING DIE ERROR when none data is supplied to set_bssampleelementcvterm_rows() function';

     throws_ok { $sample7->set_bssampleelementcvterm_rows('this is not an integer') } qr/SET ARGUMENT ERROR:/, 
     'TESTING DIE ERROR when data type supplied to set_bssampleelementcvterm_rows() function is not an hash reference';

     throws_ok { $sample7->set_bssampleelementcvterm_rows({ $sample_element_name1 => $schema}) } qr/SET ARGUMENT ERROR:/, 
     'TESTING DIE ERROR when the elements of the hash reference supplied to set_bssampleelementcvterm_rows() function are not array ref.';

     throws_ok { $sample7->set_bssampleelementcvterm_rows({ $sample_element_name1 => [$schema] }) } qr/SET ARGUMENT ERROR:/, 
     "TESTING DIE ERROR when the elements of the array reference supplied to set_bssampleelementcvterm_rows() function aren't a row obj.";
    
     ## Check if add_dbxref_to_sample_element die correctly (TEST 161 TO 165)
    
     throws_ok { $sample7->add_cvterm_to_sample_element() } qr/FUNCTION PARAMETER ERROR: None data/, 
     'TESTING DIE ERROR when none data is supplied to add_cvterm_to_sample_element() function';

     throws_ok { $sample7->add_cvterm_to_sample_element($a) } qr/FUNCTION PARAMETER ERROR: None cvterm_id/, 
     'TESTING DIE ERROR when none cvterm_id is supplied to add_cvterm_to_sample_element() function';

     throws_ok { $sample7->add_cvterm_to_sample_element($a, 'this is not an integer') } qr/DATA TYPE ERROR: Cvterm_id parameter/, 
     'TESTING DIE ERROR when cvterm_id supplied to add_cvterm_to_sample_element() function is not an integer';

     throws_ok { $sample7->add_cvterm_to_sample_element($a, $new_cvterm_id2+1) } qr/DATABASE COHERENCE ERROR: Cvterm_id/, 
     'TESTING DIE ERROR when cvterm_id supplied to add_cvterm_to_sample_element() do not exists into the database';

     throws_ok { $sample7->add_cvterm_to_sample_element('none', $new_cvterm_id2) } qr/DATA OBJECT COHERENCE ERROR: Element_sample_name/, 
     'TESTING DIE ERROR when element_sample_name supplied to add_cvterm_to_sample_element() do not exists into the object';
     
    
     ## Adding dbxref_id to protocol steps (we will create to different dbxref_id to do it)
     ## It will add two dbxref to the first step (testingcvterm1 and testingcvterm3) and one to the second (testingcvterm4)

     my $t_cvterm_id1 = $schema->resultset('Cv::Cvterm')
                               ->new( 
                                      { 
                                        cv_id      => $new_cv_id,
                                        name       => 'testingcvterm3',
                                        definition => 'this is a test for add tool-pub relation',
                                        dbxref_id  => $t_dbxref_id1,
                                      }
                                    )
			       ->insert()
			       ->discard_changes()
			       ->get_column('cvterm_id');

     my $t_cvterm_id2 = $schema->resultset('Cv::Cvterm')
                                 ->new( 
                                        { 
                                          cv_id      => $new_cv_id,
                                          name       => 'testingcvterm4',
                                          definition => 'this is a test for add tool-pub relation',
                                          dbxref_id  => $t_dbxref_id2,
                                        }
                                      )
				 ->insert()
				 ->discard_changes()
				 ->get_column('cvterm_id');

     # TEST 166 TO 170

     $sample7->add_cvterm_to_sample_element($sample_element_name1, $new_cvterm_id1);
     $sample7->add_cvterm_to_sample_element($sample_element_name1, $t_cvterm_id1);
     $sample7->add_cvterm_to_sample_element($sample_element_name2, $t_cvterm_id2);

     my %bs_el_cvterm = $sample7->get_cvterm_from_sample_elements();
     is(scalar(@{$bs_el_cvterm{$sample_element_name1}}), 2, "TESTING ADD/GET_CVTERM_TO_SAMPLE_ELEMENT, checking cvterm count (1)")
 	or diag "Looks like this failed";
     is(scalar(@{$bs_el_cvterm{$sample_element_name2}}), 1, "TESTING ADD/GET_CVTERM_TO_SAMPLE_ELEMENT, checking cvterm count (2)")
 	or diag "Looks like this failed";
     is($bs_el_cvterm{$sample_element_name1}->[0],$new_cvterm_id1, "TESTING ADD/GET_CVTERM_TO_SAMPLE_ELEMENT, checking 1st cvterm_id (1)")
 	or diag "Looks like this failed";
     is($bs_el_cvterm{$sample_element_name1}->[1], $t_cvterm_id1, "TESTING ADD/GET_CVTERM_TO_SAMPLE_ELEMENT, checking 2nd cvterm_id (1)")
 	or diag "Looks like this failed";
     is($bs_el_cvterm{$sample_element_name2}->[0], $t_cvterm_id2, "TESTING ADD/GET_CVTERM_TO_SAMPLE_ELEMENT, checking 1st cvterm_id (2)")
 	or diag "Looks like this failed";

     ## Check the store functions for the step cvterm associations:

     ## First, check that the process die correctly (TEST 171 AND 172)

     throws_ok { $sample7->store_element_cvterm_associations() } qr/STORE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to store_element_cvterm_associations() function';
    
     throws_ok { $sample7->store_element_cvterm_associations($schema) } qr/STORE ERROR: Metadbdata supplied/, 
     'TESTING DIE ERROR when argument supplied to store_element_cvterm_associations() is not a CXGN::Metadata::Metadbdata object';

     ## TEST 173 TO 177

     $sample7->store_element_cvterm_associations($metadbdata);

     my $sample11 = CXGN::Biosource::Sample->new($schema, $sample7->get_sample_id() );
     my %se_cvterm11 = $sample11->get_cvterm_from_sample_elements();
     is(scalar(@{$se_cvterm11{$sample_element_name1}}), 2, "TESTING STORE_ELEMENT_CVTERM_ASSOCIATION, checking cvterm count (1)")
	 or diag "Looks like this failed";
     is(scalar(@{$se_cvterm11{$sample_element_name2}}), 1, "TESTING STORE_ELEMENT_CVTERM_ASSOCIATION, checking cvterm count (2)")
	 or diag "Looks like this failed";
     is($se_cvterm11{$sample_element_name1}->[0], $new_cvterm_id1, "TESTING STORE_ELEMENT_CVTERM_ASSOCIATION, checking 1st cvterm_id (1)")
	 or diag "Looks like this failed";
     is($se_cvterm11{$sample_element_name1}->[1], $t_cvterm_id1, "TESTING STORE_ELEMENT_CVTERM_ASSOCIATION, checking 2nd cvterm_id (1)")
	 or diag "Looks like this failed";
     is($se_cvterm11{$sample_element_name2}->[0], $t_cvterm_id2, "TESTING STORE_ELEMENT_CVTERM_ASSOCIATION, checking 1st cvterm_id (2)")
	 or diag "Looks like this failed";

     ## Testing when another dbxref_id is added (TEST 178 AND 179)

     $sample11->add_cvterm_to_sample_element($sample_element_name1, $new_cvterm_id2);
     $sample11->store_element_cvterm_associations($metadbdata);

     my $sample12 = CXGN::Biosource::Sample->new($schema, $sample8->get_sample_id() );
     my %se_cvterm12 = $sample12->get_cvterm_from_sample_elements();
     is(scalar(@{$se_cvterm12{$sample_element_name1}}), 3, "TESTING STORE_ELEMENT_CVTERM_ASSOCIATION cvterm, checking cvterm count (1)")
 	or diag "Looks like this failed";
     is(scalar(@{$se_cvterm12{$sample_element_name2}}), 1, "TESTING STORE_ELEMENT_CVTERM_ASSOCIATION cvterm, checking cvterm count (2)")
 	or diag "Looks like this failed";

     ## Testing metadbdata methods

     ## First, check if it die correctly (TEST 180)

     my $sample13 = CXGN::Biosource::Sample->new($schema);
     $sample13->set_sample_name('sample_test_for_exceptions');
     $sample13->set_sample_type('test');
     $sample13->add_sample_element({ sample_element_name => 'element_test', organism_name => 'Genus species'});
     $sample13->add_cvterm_to_sample_element('element_test', $t_cvterm_id2);

     throws_ok { $sample13->get_element_cvterm_metadbdata() } qr/OBJECT MANIPULATION ERROR:It haven't/, 
     'TESTING DIE ERROR when try to get metadata using get_element_cvterm_metadbdata from obj. where element_dbxref has not been stored';

     ## Second test the metadata for the data stored (TEST 181 TO 189)

     my %cvterm_metadbdata = $sample12->get_element_cvterm_metadbdata();
     my $metadbdata_se1cvterm1 = $cvterm_metadbdata{$sample_element_name1}->{$new_cvterm_id1};
     my $metadbdata_se1cvterm2 = $cvterm_metadbdata{$sample_element_name1}->{$t_cvterm_id1};
     my $metadbdata_se1cvterm3 = $cvterm_metadbdata{$sample_element_name1}->{$new_cvterm_id2};
     my $metadbdata_se2cvterm1 = $cvterm_metadbdata{$sample_element_name2}->{$t_cvterm_id2};

     is($metadbdata_se1cvterm1->get_metadata_id(), $last_metadata_id+1, "TESTING GET_STEP_CVTERM_METADBDATA, checking metadata_id (1-1)")
 	or diag "Looks like this failed";
     is($metadbdata_se1cvterm2->get_metadata_id(), $last_metadata_id+1, "TESTING GET_STEP_CVTERM_METADBDATA, checking metadata_id (1-2)")
 	or diag "Looks like this failed";
     is($metadbdata_se1cvterm3->get_metadata_id(), $last_metadata_id+1, "TESTING GET_STEP_CVTERM_METADBDATA, checking metadata_id (1-3)")
 	or diag "Looks like this failed";
     is($metadbdata_se2cvterm1->get_metadata_id(), $last_metadata_id+1, "TESTING GET_STEP_CVTERM_METADBDATA, checking metadata_id (2-1)")
 	or diag "Looks like this failed";
     is($metadbdata_se1cvterm1->get_create_date(), $creation_date, "TESTING GET_STEP_CVTERM_METADBDATA, checking creation date (1-1)")
 	or diag "Looks like this failed";
     is($metadbdata_se1cvterm2->get_create_date(), $creation_date, "TESTING GET_STEP_CVTERM_METADBDATA, checking creation date (1-2)")
 	or diag "Looks like this failed";
     is($metadbdata_se1cvterm3->get_create_date(), $creation_date, "TESTING GET_STEP_CVTERM_METADBDATA, checking creation date (1-3)")
 	or diag "Looks like this failed";
     is($metadbdata_se2cvterm1->get_create_date(), $creation_date, "TESTING GET_STEP_CVTERM_METADBDATA, checking creation date (2-1)")
 	or diag "Looks like this failed";

     is($sample12->is_element_cvterm_obsolete($sample_element_name2, $t_cvterm_id2),0,"TESTING IS_ELEMENT_CVTERM_OBSOLETE, check boolean")
 	or diag "Looks like this failed";
    

     ## Testing obsolete methods (TEST 190 TO 197)

     throws_ok { $sample12->obsolete_element_cvterm_association() } qr/OBSOLETE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_element_cvterm_association() function';

     throws_ok { $sample12->obsolete_element_cvterm_association($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
     'TESTING DIE ERROR when argument supplied to obsolete_element_cvterm_association() is not a CXGN::Metadata::Metadbdata object';
   
     throws_ok { $sample12->obsolete_element_cvterm_association($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
     'TESTING DIE ERROR when none obsolete note is supplied to obsolete_element_cvterm_association() function';
    
     throws_ok { $sample12->obsolete_element_cvterm_association($metadbdata,'note') } qr/OBSOLETE ERROR: None element_name/, 
     'TESTING DIE ERROR when none step is supplied to obsolete_element_cvterm_association() function';
     
     throws_ok { $sample12->obsolete_element_cvterm_association($metadbdata,'note',$sample_element_name1)} qr/OBSOLETE ERROR: None cvte/, 
     'TESTING DIE ERROR when none cvterm_id is supplied to obsolete_element_cvterm_association() function';
     
     throws_ok { $sample12->obsolete_element_cvterm_association($metadbdata,'note','none',$t_cvterm_id2+1) } qr/DATA COHERENCE ERROR/, 
     'TESTING DIE ERROR when the sample_element and cvterm_id supplied to obsolete_element_cvterm_association() do not exist inside obj.';

     throws_ok { $sample12->obsolete_element_cvterm_association($metadbdata,'note',$sample_element_name1,$t_cvterm_id2+1) } qr/DATA COH/, 
     'TESTING DIE ERROR when the cvterm_id supplied to obsolete_element_cvterm_association() function do not exist inside obj.';

     throws_ok { $sample12->obsolete_element_cvterm_association($metadbdata,'note','none',$t_cvterm_id2) } qr/DATA COHERENCE ERROR/, 
     'TESTING DIE ERROR when the sample_element supplied to obsolete_element_cvterm_association() function do not exist inside obj.';

     ## TEST 198 TO 201

     $sample12->obsolete_element_cvterm_association($metadbdata, 'obsolete cvterm association', $sample_element_name1, $new_cvterm_id2);
    
     is($sample12->is_element_cvterm_obsolete($sample_element_name1, $new_cvterm_id2), 1, 
	"TESTING OBSOLETE_STEP_CVTERM_ASSOCIATION, checking boolean")
 	or diag "Looks like this failed";
    
     my %se_cvterm_metadbdata_obs = $sample12->get_element_cvterm_metadbdata();
     my $metadbdata_obs_c = $se_cvterm_metadbdata_obs{$sample_element_name1}->{$new_cvterm_id2};

     $sample12->obsolete_element_cvterm_association($metadbdata, 'revert obsolete', $sample_element_name1, $new_cvterm_id2, 'REVERT');

     is($metadbdata_obs_c->get_metadata_id(), $last_metadata_id+10,"TESTING OBSOLETE_ELEMENT_CVTERM_ASSOCIATION, metadata_id")
 	or diag "Looks like this failed";

     is($sample12->is_element_cvterm_obsolete($sample_element_name1, $new_cvterm_id2), 0, 
	"TESTING OBSOLETE_ELEMENT_CVTERM_ASSOCIATION REVERT, checking boolean")
 	or diag "Looks like this failed";

     my %se_cvterm_metadbdata_rev = $sample12->get_element_cvterm_metadbdata();
     my $metadbdata_rev_c = $se_cvterm_metadbdata_rev{$sample_element_name1}->{$new_cvterm_id2};

     is($metadbdata_rev_c->get_metadata_id(), $last_metadata_id+11,"TESTING OBSOLETE_ELEMENT_CVTERM_ASSOCIATION REVERT, metadata_id")
 	or diag "Looks like this failed";


     #############################################
     ## SEVENTH BLOCK: Associated File Function ##
     #############################################

     ## Check if the set_bssampleelementfile_rows die correctly (TEST 202 TO 205)

     throws_ok { $sample7->set_bssampleelementfile_rows() } qr/FUNCTION PARAMETER ERROR: None bssampleelementfile_row/, 
     'TESTING DIE ERROR when none data is supplied to set_bssampleelementfile_rows() function';

     throws_ok { $sample7->set_bssampleelementfile_rows('this is not an integer') } qr/SET ARGUMENT ERROR:/, 
     'TESTING DIE ERROR when data type supplied to set_bssampleelementfile_rows() function is not an hash reference';

     throws_ok { $sample7->set_bssampleelementfile_rows({ $sample_element_name1 => $schema}) } qr/SET ARGUMENT ERROR:/, 
     'TESTING DIE ERROR when the elements of the hash reference supplied to set_bssampleelementfile_rows() function are not array ref.';

     throws_ok { $sample7->set_bssampleelementfile_rows({ $sample_element_name1 => [$schema] }) } qr/SET ARGUMENT ERROR:/, 
     "TESTING DIE ERROR when the elements of the array reference supplied to set_bssampleelementfile_rows() function aren't a row obj.";

     ## It will add three different files into the metadata.md_files tables before continue testing

     my %fileids = ();
     my @file_names = ('test1.txt', 'test2.txt', 'test3.txt');
     
     foreach my $filename (@file_names) {

	 my $file_row = $schema->resultset('MdFiles')->new( 
	                                                    { 
                                                              basename    => $filename, 
                                                              dirname     => '/dir/test/', 
                                                              filetype    => 'text', 
                                                              metadata_id => $curr_metadata_id
                                                            }
	                                                  );
	 my $file_id = $file_row->insert()
	                        ->discard_changes()
			        ->get_column('file_id');
	
	 $fileids{$filename} = $file_id;
     }
     
     ## Check if add_file_to_sample_element die correctly (TEST 206 TO 213)
    
     throws_ok { $sample7->add_file_to_sample_element() } qr/FUNCTION PARAMETER ERROR: None data/, 
     'TESTING DIE ERROR when none data is supplied to add_file_to_sample_element() function';

     throws_ok { $sample7->add_file_to_sample_element($a) } qr/FUNCTION PARAMETER ERROR: None file_id/, 
     'TESTING DIE ERROR when none file_id is supplied to add_file_to_sample_element() function';

     throws_ok { $sample7->add_file_to_sample_element($a, 'this is not an integer') } qr/DATA TYPE ERROR: File_id parameter/, 
     'TESTING DIE ERROR when file_id supplied to add_file_to_sample_element() function is not an integer';

     throws_ok { $sample7->add_file_to_sample_element($a, $fileids{$file_names[2]}+10) } qr/DATABASE COHERENCE ERROR: File_id/, 
     'TESTING DIE ERROR when file_id supplied to add_file_to_sample_element() do not exists into the database';

     throws_ok { $sample7->add_file_to_sample_element('none', $fileids{$file_names[0]}) } qr/DATA OBJECT COHERENCE ERROR: Element_sam/, 
     'TESTING DIE ERROR when element_sample_name supplied to add_file_to_sample_element() do not exists into the object';

     throws_ok { $sample7->add_file_to_sample_element($a, {basename => 'test'}) } qr/DATABASE COHERENCE ERROR: Doesnt exist any fi/,
     'TESTING DIE ERROR when file search parameter supplied to add_file_to_sample_element() do not exists in the database';
     
     throws_ok { $sample7->add_file_to_sample_element($a, {filetype => 'text'}) } qr/INPUT PARAMETER ERROR: Parameter supplied/,
     'TESTING DIE ERROR when file search parameter supplied to add_file_to_sample_element() return more than one row';

     throws_ok { $sample7->add_file_to_sample_element($a, ['text']) } qr/TYPE PARAMETER ERROR: Parameter supplied/,
     'TESTING DIE ERROR when file search parameter supplied to add_file_to_sample_element() is not an integer or a hash reference';

     ## Testing add_file_to_sample_element function (TEST 214 TO 218)

     $sample7->add_file_to_sample_element($sample_element_name1, $fileids{$file_names[0]});
     $sample7->add_file_to_sample_element($sample_element_name1, { basename => $file_names[1], dirname => '/dir/test/'});
     $sample7->add_file_to_sample_element($sample_element_name2, { basename => $file_names[2]});

     my %bs_el_file = $sample7->get_file_from_sample_elements();
     is(scalar(@{$bs_el_file{$sample_element_name1}}), 2, "TESTING ADD/GET_FILE_TO_SAMPLE_ELEMENT, checking file count (1)")
 	or diag "Looks like this failed";
     is(scalar(@{$bs_el_file{$sample_element_name2}}), 1, "TESTING ADD/GET_FILE_TO_SAMPLE_ELEMENT, checking file count (2)")
 	or diag "Looks like this failed";
     is($bs_el_file{$sample_element_name1}->[0], $fileids{$file_names[0]}, 
	"TESTING ADD/GET_FILE_TO_SAMPLE_ELEMENT, checking 1st file_id (1)")
 	or diag "Looks like this failed";
     is($bs_el_file{$sample_element_name1}->[1], $fileids{$file_names[1]}, 
	"TESTING ADD/GET_FILE_TO_SAMPLE_ELEMENT, checking 2nd file_id (1)")
 	or diag "Looks like this failed";
     is($bs_el_file{$sample_element_name2}->[0], $fileids{$file_names[2]}, 
	"TESTING ADD/GET_FILE_TO_SAMPLE_ELEMENT, checking 1st file_id (2)")
 	or diag "Looks like this failed";

     ## Check the store functions for the element associations:

     ## First, check that the process die correctly (TEST 219 AND 220)

     throws_ok { $sample7->store_element_file_associations() } qr/STORE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to store_element_file_associations() function';
    
     throws_ok { $sample7->store_element_file_associations($schema) } qr/STORE ERROR: Metadbdata supplied/, 
     'TESTING DIE ERROR when argument supplied to store_element_file_associations() is not a CXGN::Metadata::Metadbdata object';

     ## TEST 221 TO 225

     $sample7->store_element_file_associations($metadbdata);

     my $sample14 = CXGN::Biosource::Sample->new($schema, $sample7->get_sample_id() );
     my %se_file14 = $sample14->get_file_from_sample_elements();
     is(scalar(@{$se_file14{$sample_element_name1}}), 2, "TESTING STORE_ELEMENT_FILE_ASSOCIATION, checking file count (1)")
	 or diag "Looks like this failed";
     is(scalar(@{$se_file14{$sample_element_name2}}), 1, "TESTING STORE_ELEMENT_FILE_ASSOCIATION, checking file count (2)")
	 or diag "Looks like this failed";
     is($se_file14{$sample_element_name1}->[0], $fileids{$file_names[0]} , 
	"TESTING STORE_ELEMENT_FILE_ASSOCIATION, checking 1st file_id (1)")
	 or diag "Looks like this failed";
     is($se_file14{$sample_element_name1}->[1], $fileids{$file_names[1]}, 
	"TESTING STORE_ELEMENT_FILE_ASSOCIATION, checking 2nd file_id (1)")
	 or diag "Looks like this failed";
     is($se_file14{$sample_element_name2}->[0], $fileids{$file_names[2]}, 
	"TESTING STORE_ELEMENT_FILE_ASSOCIATION, checking 1st file_id (2)")
	 or diag "Looks like this failed";

     ## Testing when another dbxref_id is added (TEST 226 AND 227)

     $sample14->add_file_to_sample_element($sample_element_name1, $fileids{$file_names[2]} );
     $sample14->store_element_file_associations($metadbdata);

     my $sample15 = CXGN::Biosource::Sample->new($schema, $sample8->get_sample_id() );
     my %se_file15 = $sample15->get_file_from_sample_elements();
     is(scalar(@{$se_file15{$sample_element_name1}}), 3, "TESTING STORE_ELEMENT_FILE_ASSOCIATION file, checking file count (1)")
 	or diag "Looks like this failed";
     is(scalar(@{$se_file15{$sample_element_name2}}), 1, "TESTING STORE_ELEMENT_FILE_ASSOCIATION file, checking file count (2)")
 	or diag "Looks like this failed";

     ## Testing metadbdata methods

     ## First, check if it die correctly (TEST 228)

     my $sample16 = CXGN::Biosource::Sample->new($schema);
     $sample16->set_sample_name('sample_test_for_exceptions');
     $sample16->set_sample_type('test');
     $sample16->add_sample_element({ sample_element_name => 'element_test', organism_name => 'Genus species'});
     $sample16->add_file_to_sample_element('element_test', $fileids{$file_names[2]});

     throws_ok { $sample16->get_element_file_metadbdata() } qr/OBJECT MANIPULATION ERROR:It haven't/, 
     'TESTING DIE ERROR when try to get metadata using get_element_file_metadbdata from obj. where element_file has not been stored';

     ## Second test the metadata for the data stored (TEST 229 TO 237)

     my %file_metadbdata = $sample15->get_element_file_metadbdata();
     my $metadbdata_se1file1 = $file_metadbdata{$sample_element_name1}->{$fileids{$file_names[0]}};
     my $metadbdata_se1file2 = $file_metadbdata{$sample_element_name1}->{$fileids{$file_names[1]}};
     my $metadbdata_se1file3 = $file_metadbdata{$sample_element_name1}->{$fileids{$file_names[2]}};
     my $metadbdata_se2file1 = $file_metadbdata{$sample_element_name2}->{$fileids{$file_names[2]}};

     is($metadbdata_se1file1->get_metadata_id(), $last_metadata_id+1, "TESTING GET_ELEMENT_FILE_METADBDATA, checking metadata_id (1-1)")
 	or diag "Looks like this failed";
     is($metadbdata_se1file2->get_metadata_id(), $last_metadata_id+1, "TESTING GET_ELEMENT_FILE_METADBDATA, checking metadata_id (1-2)")
 	or diag "Looks like this failed";
     is($metadbdata_se1file3->get_metadata_id(), $last_metadata_id+1, "TESTING GET_ELEMENT_FILE_METADBDATA, checking metadata_id (1-3)")
 	or diag "Looks like this failed";
     is($metadbdata_se2file1->get_metadata_id(), $last_metadata_id+1, "TESTING GET_ELEMENT_FILE_METADBDATA, checking metadata_id (2-1)")
 	or diag "Looks like this failed";
     is($metadbdata_se1file1->get_create_date(), $creation_date, "TESTING GET_ELEMENT_FILE_METADBDATA, checking creation date (1-1)")
 	or diag "Looks like this failed";
     is($metadbdata_se1file2->get_create_date(), $creation_date, "TESTING GET_ELEMENT_FILE_METADBDATA, checking creation date (1-2)")
 	or diag "Looks like this failed";
     is($metadbdata_se1file3->get_create_date(), $creation_date, "TESTING GET_ELEMENT_FILE_METADBDATA, checking creation date (1-3)")
 	or diag "Looks like this failed";
     is($metadbdata_se2file1->get_create_date(), $creation_date, "TESTING GET_ELEMENT_FILE_METADBDATA, checking creation date (2-1)")
 	or diag "Looks like this failed";

     is($sample15->is_element_file_obsolete($sample_element_name2, $fileids{$file_names[0]}), 0,
	"TESTING IS_ELEMENT_FILE_OBSOLETE, check boolean")
 	or diag "Looks like this failed";
    

     ## Testing obsolete methods (TEST 238 TO 245)

     throws_ok { $sample15->obsolete_element_file_association() } qr/OBSOLETE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_element_file_association() function';

     throws_ok { $sample15->obsolete_element_file_association($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
     'TESTING DIE ERROR when argument supplied to obsolete_element_file_association() is not a CXGN::Metadata::Metadbdata object';
   
     throws_ok { $sample15->obsolete_element_file_association($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
     'TESTING DIE ERROR when none obsolete note is supplied to obsolete_element_file_association() function';
    
     throws_ok { $sample15->obsolete_element_file_association($metadbdata,'note') } qr/OBSOLETE ERROR: None element_name/, 
     'TESTING DIE ERROR when none step is supplied to obsolete_element_file_association() function';
     
     throws_ok { $sample15->obsolete_element_file_association($metadbdata,'note',$sample_element_name1)} qr/OBSOLETE ERROR: None file/, 
     'TESTING DIE ERROR when none file_id is supplied to obsolete_element_file_association() function';
     
     throws_ok { $sample15->obsolete_element_file_association($metadbdata, 'note' , 'none' , $fileids{$file_names[2]}+1) } 
     qr/DATA COHERENCE ERROR/, 
     'TESTING DIE ERROR when the sample_element and file_id supplied to obsolete_file_file_association() do not exist inside obj.';

     throws_ok { $sample15->obsolete_element_file_association($metadbdata, 'note' , $sample_element_name1, $fileids{$file_names[2]}+1) } 
     qr/DATA COH/, 
     'TESTING DIE ERROR when the cvterm_id supplied to obsolete_element_file_association() function do not exist inside obj.';

     throws_ok { $sample15->obsolete_element_file_association($metadbdata, 'note', 'none', $fileids{$file_names[2]} ) } 
     qr/DATA COHERENCE ERROR/, 
     'TESTING DIE ERROR when the sample_element supplied to obsolete_element_file_association() function do not exist inside obj.';

     ## TEST 246 TO 249

     $sample15->obsolete_element_file_association($metadbdata, 'obsolete file association' , $sample_element_name1,
						  $fileids{$file_names[2]});
    
     is($sample15->is_element_file_obsolete($sample_element_name1, $fileids{$file_names[2]}), 1, 
	"TESTING OBSOLETE_ELEMENT_FILE_ASSOCIATION, checking boolean")
 	or diag "Looks like this failed";
    
     my %se_file_metadbdata_obs = $sample15->get_element_file_metadbdata();
     my $metadbdata_obs_cf = $se_file_metadbdata_obs{$sample_element_name1}->{$fileids{$file_names[2]}};

     $sample15->obsolete_element_file_association($metadbdata, 'revert obsolete', $sample_element_name1, $fileids{$file_names[2]}, 
						  'REVERT');

     is($metadbdata_obs_cf->get_metadata_id(), $last_metadata_id+12,"TESTING OBSOLETE_ELEMENT_FILE_ASSOCIATION, metadata_id")
 	or diag "Looks like this failed";

     is($sample15->is_element_file_obsolete($sample_element_name1, $fileids{$file_names[2]}), 0, 
	"TESTING OBSOLETE_ELEMENT_file_ASSOCIATION REVERT, checking boolean")
 	or diag "Looks like this failed";

     my %se_file_metadbdata_rev = $sample15->get_element_file_metadbdata();
     my $metadbdata_rev_cf = $se_file_metadbdata_rev{$sample_element_name1}->{$fileids{$file_names[2]}};

     is($metadbdata_rev_cf->get_metadata_id(), $last_metadata_id+13,"TESTING OBSOLETE_ELEMENT_FILE_ASSOCIATION REVERT, metadata_id")
 	or diag "Looks like this failed";


     ###########################################
     ## EIGTHTH BLOCK: General Store function ##
     ###########################################

     ## Check if the set_bssampleelementcvterm_rows die correctly (TEST 250 TO 257)

     throws_ok { $sample7->set_bssampleelementrelation_source_rows() } 
     qr/FUNCTION PARAMETER ERROR: None bssampleelementrelation_source_row/, 
     'TESTING DIE ERROR when none data is supplied to set_bssampleelementrelation_source_rows() function';

     throws_ok { $sample7->set_bssampleelementrelation_source_rows('this is not an integer') } qr/SET ARGUMENT ERROR:/, 
     'TESTING DIE ERROR when data type supplied to set_bssampleelementrelation_source_rows() function is not an hash reference';

     throws_ok { $sample7->set_bssampleelementrelation_source_rows({ $sample_element_name1 => $schema}) } qr/SET ARGUMENT ERROR:/, 
     'TESTING DIE ERROR when elements of the hash ref. supplied to set_bssampleelementrelation_source_rows() function are not array ref.';

     throws_ok { $sample7->set_bssampleelementrelation_source_rows({ $sample_element_name1 => [$schema] }) } qr/SET ARGUMENT ERROR:/, 
     "TESTING DIE ERROR when elements of the array ref. supplied to set_bssampleelementrelation_source_rows() function aren't a row obj.";

     throws_ok { $sample7->set_bssampleelementrelation_result_rows() } 
     qr/FUNCTION PARAMETER ERROR: None bssampleelementrelation_result_row/, 
     'TESTING DIE ERROR when none data is supplied to set_bssampleelementrelation_result_rows() function';

     throws_ok { $sample7->set_bssampleelementrelation_result_rows('this is not an integer') } qr/SET ARGUMENT ERROR:/, 
     'TESTING DIE ERROR when data type supplied to set_bssampleelementrelation_result_rows() function is not an hash reference';

     throws_ok { $sample7->set_bssampleelementrelation_result_rows({ $sample_element_name1 => $schema}) } qr/SET ARGUMENT ERROR:/, 
     'TESTING DIE ERROR when elements of the hash ref. supplied to set_bssampleelementrelation_result_rows() function are not array ref.';

     throws_ok { $sample7->set_bssampleelementrelation_result_rows({ $sample_element_name1 => [$schema] }) } qr/SET ARGUMENT ERROR:/, 
     "TESTING DIE ERROR when elements of the array ref. supplied to set_bssampleelementrelation_result_rows() function aren't a row obj.";

     ## Testing die for add_source_relation_to_sample_element and add_result_relation_to_sample_element (TEST 258 to 263)

      throws_ok { $sample7->add_source_relation_to_sample_element() } qr/FUNCTION PARAMETER ERROR: None data/, 
     'TESTING DIE ERROR when none data is supplied to add_source_relation_to_sample_element() function';

     throws_ok { $sample7->add_source_relation_to_sample_element($a) } qr/FUNCTION PARAMETER ERROR: None element_name_B/, 
     'TESTING DIE ERROR when none sample_element_name_B is supplied to add_source_relation_to_sample_element() function';

     throws_ok { $sample7->add_source_relation_to_sample_element($a, $b) } qr/FUNCTION PARAMETER ERROR: None relation_type/, 
     'TESTING DIE ERROR when none relation_type is supplied to add_source_relation_to_sample_element() function';
     
     throws_ok { $sample7->add_source_relation_to_sample_element('none', $b, 'test') } qr/DATA OBJECT COHERENCE ERROR: Element_sam/, 
     'TESTING DIE ERROR when element_sample_name supplied to add_source_relation_to_sample_element() do not exists into the object';


     $sample13->add_sample_element(    
                                    { 
				       sample_element_name => 'sample element 1',
				       alternative_name    => 'another sample element 1',
				       description         => 'This is a sample element test',
				       organism_id         => $organism_id, 
				       protocol_id         => $protocol_id,
                                    }
 	                          );

     throws_ok { $sample13->add_source_relation_to_sample_element($a, $b, 'test') } qr/OBJECT MANIPULATION ERROR:/, 
     'TESTING DIE ERROR when try to add_source_relation_to_sample_element where sample_element has not been stored';
     
     throws_ok { $sample7->add_source_relation_to_sample_element($a, 'none', 'test') } qr/DATABASE COHERENCE ERROR: Sample_el/, 
     'TESTING DIE ERROR when sample_element_name_B supplied to add_source_relation_to_sample_element() function do not exist in db';


     ## Before add relations to sample elements it will create a new sample with new elements

     my $sample_new = CXGN::Biosource::Sample->new($schema);
     $sample_new->set_sample_name('sample_test_for_elements');
     $sample_new->set_sample_type('test');
     $sample_new->add_sample_element({ sample_element_name => 'element t', organism_name => 'Genus species'});
     $sample_new->add_sample_element({ sample_element_name => 'element v', organism_name => 'Genus species'});
     $sample_new->add_sample_element({ sample_element_name => 'element w', organism_name => 'Genus species'});
     $sample_new->add_sample_element({ sample_element_name => 'element x', organism_name => 'Genus species'});
     $sample_new->add_sample_element({ sample_element_name => 'element y', organism_name => 'Genus species'});
     $sample_new->add_sample_element({ sample_element_name => 'element z', organism_name => 'Genus species'});
     $sample_new->store_sample($metadbdata);
     $sample_new->store_sample_elements($metadbdata);
 
     my %new_sample_elements = $sample_new->get_sample_elements();
     my ($t, $v, $w, $x, $y, $z) = sort keys %new_sample_elements;

     ## Testing add_source_relation_to_sample_element function (TEST 264 to 272)
     
     $sample15->add_source_relation_to_sample_element($a, $t, 'source relation test 1-t');
     $sample15->add_source_relation_to_sample_element($a, $v, 'source relation test 1-v');
     $sample15->add_source_relation_to_sample_element($b, $w, 'source relation test 2-w');
     $sample15->add_result_relation_to_sample_element($a, $x, 'result relation test 1-x');

     my ($source_relations_href, $result_relations_href) = $sample15->get_relations_from_sample_elements();

     is(scalar(keys %{$source_relations_href}), 2, 
	"TESTING SOURCE RELATION TO SAMPLE ELEMENTS, checking number of source sample element names")
	 or diag "Looks like this failed";
     is(scalar(keys %{$result_relations_href}), 1, 
	"TESTING RESULT RELATION TO SAMPLE ELEMENTS, checking number of result sample element names")
	 or diag "Looks like this failed";

     is(scalar( @{ $source_relations_href->{$a} } ), 2, 
	"TESTING SOURCE RELATION TO SAMPLE ELEMENTS, checking number of element in the array reference associated to sample element ($a)")
	 or diag "Looks like this failed";
     is(scalar( @{ $result_relations_href->{$a} } ), 1, 
	"TESTING RESULT RELATION TO SAMPLE ELEMENTS, checking number of element in the array reference associated to sample element ($a)")
	 or diag "Looks like this failed";

     is($source_relations_href->{$a}->[0]->{'sample_element_name'}, $t, 
	"TESTING SOURCE RELATION TO SAMPLE ELEMENTS, sample_element_name for 1st element of the array associated to sample_element=$a")
	 or diag "Looks like this failed";
     is($source_relations_href->{$a}->[1]->{'relation_type'}, 'source relation test 1-v' , 
	"TESTING SOURCE RELATION TO SAMPLE ELEMENTS, relation_type for 2nd element of the array associated to sample_element=$a")
	 or diag "Looks like this failed";
     is($source_relations_href->{$b}->[0]->{'sample_element_name'}, $w, 
	"TESTING SOURCE RELATION TO SAMPLE ELEMENTS, sample_element_name for 2nd element of the array associated to sample_element=$b")
	 or diag "Looks like this failed";
     is($source_relations_href->{$b}->[0]->{'relation_type'}, 'source relation test 2-w', 
	"TESTING SOURCE RELATION TO SAMPLE ELEMENTS, relation_type for 2nd element of the array associated to sample_element=$b")
	 or diag "Looks like this failed";
     is($result_relations_href->{$a}->[0]->{'sample_element_name'}, $x, 
	"TESTING RESULT RELATION TO SAMPLE ELEMENTS, sample_element_name for 1st element of the array associated to sample_element=$a")
	 or diag "Looks like this failed";


     ## Testing store function

     ## First, check that the process die correctly (TEST 273 AND 274)

     throws_ok { $sample7->store_element_relations() } qr/STORE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to store_element_relations() function';
    
     throws_ok { $sample7->store_element_relations($schema) } qr/STORE ERROR: Metadbdata supplied/, 
     'TESTING DIE ERROR when argument supplied to store_element_relations() is not a CXGN::Metadata::Metadbdata object';

     ## TEST 275 TO 283

     $sample15->store_element_relations($metadbdata);

     my $sample17 = CXGN::Biosource::Sample->new($schema, $sample7->get_sample_id() );
     my ($source_relations17_href, $result_relations17_href) = $sample17->get_relations_from_sample_elements();

     ## It will use the same functions used to check the relations but over the hash references obteined after use store
 
     is(scalar(keys %{$source_relations17_href}), 2, 
	"TESTING STORE ELEMENT RELATIONS, checking number of source sample element names")
	 or diag "Looks like this failed";
     is(scalar(keys %{$result_relations17_href}), 1, 
	"TESTING STORE ELEMENT RELATIONS, checking number of result sample element names")
	 or diag "Looks like this failed";

     is(scalar( @{ $source_relations17_href->{$a} } ), 2, 
	"TESTING STORE ELEMENT RELATIONS, checking number of element in the array reference associated to sample element ($a)")
	 or diag "Looks like this failed";
     is(scalar( @{ $result_relations17_href->{$a} } ), 1, 
	"TESTING STORE ELEMENT RELATIONS, checking number of element in the array reference associated to sample element ($a)")
	 or diag "Looks like this failed";

     is($source_relations17_href->{$a}->[0]->{'sample_element_name'}, $t, 
	"TESTING STORE ELEMENT RELATIONS, sample_element_name for 1st element of the array associated to sample_element=$a")
	 or diag "Looks like this failed";
     is($source_relations17_href->{$a}->[1]->{'relation_type'}, 'source relation test 1-v' , 
	"TESTING STORE ELEMENT RELATIONS, relation_type for 2nd element of the array associated to sample_element=$a")
	 or diag "Looks like this failed";
     is($source_relations17_href->{$b}->[0]->{'sample_element_name'}, $w, 
	"TESTING STORE ELEMENT RELATIONS, sample_element_name for 2nd element of the array associated to sample_element=$b")
	 or diag "Looks like this failed";
     is($source_relations17_href->{$b}->[0]->{'relation_type'}, 'source relation test 2-w', 
	"TESTING STORE ELEMENT RELATIONS, relation_type for 2nd element of the array associated to sample_element=$b")
	 or diag "Looks like this failed";
     is($result_relations17_href->{$a}->[0]->{'sample_element_name'}, $x, 
	"TESTING STORE ELEMENT RELATIONS, sample_element_name for 1st element of the array associated to sample_element=$a")
	 or diag "Looks like this failed";

     ## Testing when the same relation is added (TEST 284 to 288)

     $sample17->add_source_relation_to_sample_element($a, $v, 'source relation test 1-v');
     $sample17->store_element_relations($metadbdata);

     my $sample18 = CXGN::Biosource::Sample->new($schema, $sample8->get_sample_id() );
     my ($source_relations18_href, $result_relations18_href) = $sample18->get_relations_from_sample_elements();

     ## It will use the same functions used to check the relations but over the hash references obteined after use store
 
     is(scalar(keys %{$source_relations18_href}), 2, 
	"TESTING STORE ELEMENT RELATIONS (adding same relation), checking number of source sample element names")
	 or diag "Looks like this failed";
     is(scalar(keys %{$result_relations18_href}), 1, 
	"TESTING STORE ELEMENT RELATIONS (addins same relation), checking number of result sample element names")
	 or diag "Looks like this failed";

     is(scalar( @{ $source_relations18_href->{$a} } ), 2, 
	"TESTING STORE ELEMENT RELATIONS (adding same relation), checking N of element in array ref. associated to sample element ($a)")
	 or diag "Looks like this failed";
     is(scalar( @{ $result_relations18_href->{$a} } ), 1, 
	"TESTING STORE ELEMENT RELATIONS (adding same relation), checking N of element in array ref. associated to sample element ($a)")
	 or diag "Looks like this failed";
     is($source_relations18_href->{$a}->[1]->{'relation_type'}, 'source relation test 1-v' , 
	"TESTING STORE ELEMENT RELATIONS (adding same relation), relation_type for 2nd element of array associated to sample_element=$a")
	 or diag "Looks like this failed";

     ## check use of get metadata object (TEST 289 and 290)

     my ($metadbdata_source_href, $metadbdata_result_href) = $sample17->get_element_relation_metadbdata($metadbdata);
     

     is($metadbdata_source_href->{$a}->{$v}->get_metadata_id(), $last_metadata_id+1, 
	"TESTING GET_ELEMENT_SOURCE_RELATION_METADBDATA, checking metadata_id")
	or diag "Looks like this failed";
     is($metadbdata_result_href->{$a}->{$x}->get_metadata_id(), $last_metadata_id+1, 
	"TESTING GET_ELEMENT_SOURCE_RELATION_METADBDATA, checking metadata_id")
	or diag "Looks like this failed";
     
     
     ## Use of add_function to edit a relation_type (TEST 291 to 296)

     $sample17->add_source_relation_to_sample_element($a, $v, 'source relation test 1-v modified');
     $sample17->store_element_relations($metadbdata);

     my $sample19 = CXGN::Biosource::Sample->new($schema, $sample8->get_sample_id() );
     my ($source_relations19_href, $result_relations19_href) = $sample19->get_relations_from_sample_elements();
     my %metadbdata_source_mod = $sample19->get_element_relation_metadbdata($metadbdata, 'source');

     ## It will use the same functions used to check the relations but over the hash references obteined after use store
 
     is(scalar(keys %{$source_relations19_href}), 2, 
	"TESTING STORE ELEMENT RELATIONS (editing a relation), checking number of source sample element names")
	 or diag "Looks like this failed";
     is(scalar(keys %{$result_relations19_href}), 1, 
	"TESTING STORE ELEMENT RELATIONS (editing a relation), checking number of result sample element names")
	 or diag "Looks like this failed";

     is(scalar( @{ $source_relations19_href->{$a} } ), 2, 
	"TESTING STORE ELEMENT RELATIONS (editing a relation), checking N of element in array ref. associated to sample element ($a)")
	 or diag "Looks like this failed";
     is(scalar( @{ $result_relations19_href->{$a} } ), 1, 
	"TESTING STORE ELEMENT RELATIONS (editing a relation), checking N of element in array ref. associated to sample element ($a)")
	 or diag "Looks like this failed";
     is($source_relations19_href->{$a}->[1]->{'relation_type'}, 'source relation test 1-v modified' , 
	"TESTING STORE ELEMENT RELATIONS (editing a relation), relation_type for 2nd element of array associated to sample_element=$a")
	 or diag "Looks like this failed";

     is($metadbdata_source_mod{$a}->{$v}->get_metadata_id(), $last_metadata_id+14, 
	"TESTING STORE ELEMENT RELATIONS (editing a relation), checking the metadata_id for the relation modified")
	 or diag "Looks like this failed";

     ## Testing when another relation is added (TEST 297 AND 300)

     $sample17->add_source_relation_to_sample_element($a, $y, 'source relation test 1-y');
     $sample17->store_element_relations($metadbdata);

     my $sample20 = CXGN::Biosource::Sample->new($schema, $sample8->get_sample_id() );
     my ($source_relations20_href, $result_relations20_href) = $sample20->get_relations_from_sample_elements();

     ## It will use the same functions used to check the relations but over the hash references obtained after use store
 
     is(scalar(keys %{$source_relations20_href}), 2, 
	"TESTING STORE ELEMENT RELATIONS, checking number of source sample element names")
	 or diag "Looks like this failed";
     is(scalar(keys %{$result_relations20_href}), 1, 
	"TESTING STORE ELEMENT RELATIONS, checking number of result sample element names")
	 or diag "Looks like this failed";

     is(scalar( @{ $source_relations20_href->{$a} } ), 3, 
	"TESTING STORE ELEMENT RELATIONS, checking number of element in the array reference associated to sample element ($a)")
	 or diag "Looks like this failed";
     is(scalar( @{ $result_relations20_href->{$a} } ), 1, 
	"TESTING STORE ELEMENT RELATIONS, checking number of element in the array reference associated to sample element ($a)")
	 or diag "Looks like this failed";
     
     ## Testing the metadata functions and obsolete funtion (TEST 301 and 302)

     is($sample20->is_element_relation_obsolete($a, $v), 0, "TESTING IS_ELEMENT_RELATION_OBSOLETE for a source, checking boolean")
	 or diag "Looks like this failed";

     is($sample20->is_element_relation_obsolete($a, $x), 0, "TESTING IS_ELEMENT_RELATION_OBSOLETE for a result, checking boolean")
	 or diag "Looks like this failed";


     ## Testing die for obsolete function (TEST 303 TO 310)

     throws_ok { $sample20->obsolete_element_relation() } qr/OBSOLETE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_element_relation() function';

     throws_ok { $sample20->obsolete_element_relation($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
     'TESTING DIE ERROR when argument supplied to obsolete_element_relation() is not a CXGN::Metadata::Metadbdata object';
   
     throws_ok { $sample20->obsolete_element_relation($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
     'TESTING DIE ERROR when none obsolete note is supplied to obsolete_element_relation() function';
    
     throws_ok { $sample20->obsolete_element_relation($metadbdata, 'note') } qr/OBSOLETE ERROR: None element_name/, 
     'TESTING DIE ERROR when none element_name is supplied to obsolete_element_relation() function';
     
     throws_ok { $sample20->obsolete_element_relation($metadbdata, 'note', $a)} qr/OBSOLETE ERROR: None related/, 
     'TESTING DIE ERROR when none related_sample_element is supplied to obsolete_element_relation() function';
     
     throws_ok { $sample20->obsolete_element_relation($metadbdata, 'note' , 'none' , 'none') } 
     qr/OBSOLETE PARAMETER ERROR/, 
     'TESTING DIE ERROR when the sample_element and related_name supplied to obsolete_file_file_association() do not exist inside obj.';

     throws_ok { $sample20->obsolete_element_relation($metadbdata, 'note' , $a, 'none') } 
     qr/OBSOLETE PARAMETER ERROR/, 
     'TESTING DIE ERROR when the related_sample_element supplied to obsolete_element_file_association() function donot exist inside obj.';

     throws_ok { $sample20->obsolete_element_relation($metadbdata, 'note', 'none', $v) } 
     qr/DATA COHERENCE ERROR/, 
     'TESTING DIE ERROR when the sample_element supplied to obsolete_element_file_association() function do not exist inside obj.';


     ## Test for obsolete_element_relation function (TEST 311 to 326)

     $sample20->obsolete_element_relation($metadbdata, 'test obsolete source relation', $a, $v);

     is($sample20->is_element_relation_obsolete($a, $v), 1, 
	"TESTING OBSOLETE_ELEMENT_RELATION for a source modified, checking boolean (1)")
	 or diag "Looks like this failed";

     my ($metadbdata_source20_href, $metadbdata_result20_href) = $sample20->get_element_relation_metadbdata($metadbdata);

     is($metadbdata_source20_href->{$a}->{$v}->get_metadata_id(), $last_metadata_id+15, 
	"TESTING OBSOLETE_ELEMENT_RELATION, checking the metadata_id for the relation modified")
	 or diag "Looks like this failed";

     is($sample20->is_element_relation_obsolete($a, $x), 0, 
	"TESTING OBSOLETE_ELEMENT_RELATION for a result unmodified, checking boolean (0)")
	 or diag "Looks like this failed";

     is($metadbdata_result20_href->{$a}->{$x}->get_metadata_id(), $last_metadata_id+1, 
	"TESTING OBSOLETE_ELEMENT_RELATION, checking the metadata_id for the relation unmodified")
	 or diag "Looks like this failed";


     $sample20->obsolete_element_relation($metadbdata, 'test obsolete result relation', $a, $x);

     is($sample20->is_element_relation_obsolete($a, $v), 1, 
	 "TESTING OBSOLETE_ELEMENT_RELATION for a source unmodified, checking boolean (1)")
	 or diag "Looks like this failed";

     my ($metadbdata_source21_href, $metadbdata_result21_href) = $sample20->get_element_relation_metadbdata($metadbdata);

     is($metadbdata_source21_href->{$a}->{$v}->get_metadata_id(), $last_metadata_id+15, 
	"TESTING OBSOLETE_ELEMENT_RELATION, checking the metadata_id for the relation unmodified")
	 or diag "Looks like this failed";

     is($sample20->is_element_relation_obsolete($a, $x), 1, 
	"TESTING OBSOLETE_ELEMENT_RELATION for a modified result, checking boolean (1)")
	 or diag "Looks like this failed";

     is($metadbdata_result21_href->{$a}->{$x}->get_metadata_id(), $last_metadata_id+16, 
	"TESTING OBSOLETE_ELEMENT_RELATION, checking the metadata_id for the relation modified")
	 or diag "Looks like this failed";

     $sample20->obsolete_element_relation($metadbdata, 'test revert obsolete source relation', $a, $v, 'REVERT');

     is($sample20->is_element_relation_obsolete($a, $v), 0, 
	 "TESTING OBSOLETE_ELEMENT_RELATION REVERT for a source modified, checking boolean (0)")
	 or diag "Looks like this failed";

     my ($metadbdata_source22_href, $metadbdata_result22_href) = $sample20->get_element_relation_metadbdata($metadbdata);

     is($metadbdata_source22_href->{$a}->{$v}->get_metadata_id(), $last_metadata_id+17, 
	"TESTING OBSOLETE_ELEMENT_RELATION REVERT, checking the metadata_id for the relation modified")
	 or diag "Looks like this failed";

     is($sample20->is_element_relation_obsolete($a, $x), 1, 
	"TESTING OBSOLETE_ELEMENT_RELATION for a unmodified result during revert, checking boolean (1)")
	 or diag "Looks like this failed";

     is($metadbdata_result22_href->{$a}->{$x}->get_metadata_id(), $last_metadata_id+16, 
	"TESTING OBSOLETE_ELEMENT_RELATION , checking the metadata_id for the relation unmodified during revert obsolete")
	 or diag "Looks like this failed";

      $sample20->obsolete_element_relation($metadbdata, 'test revert obsolete source relation', $a, $x, 'REVERT');

     is($sample20->is_element_relation_obsolete($a, $v), 0, 
	 "TESTING OBSOLETE_ELEMENT_RELATION REVERT for a source unmodified, checking boolean (0)")
	 or diag "Looks like this failed";

     my ($metadbdata_source23_href, $metadbdata_result23_href) = $sample20->get_element_relation_metadbdata($metadbdata);

     is($metadbdata_source23_href->{$a}->{$v}->get_metadata_id(), $last_metadata_id+17, 
	"TESTING OBSOLETE_ELEMENT_RELATION REVERT, checking the metadata_id for the relation unmodified")
	 or diag "Looks like this failed";

     is($sample20->is_element_relation_obsolete($a, $x), 0, 
	"TESTING OBSOLETE_ELEMENT_RELATION REVERT for a modified result during revert, checking boolean (1)")
	 or diag "Looks like this failed";

     is($metadbdata_result23_href->{$a}->{$x}->get_metadata_id(), $last_metadata_id+18, 
	"TESTING OBSOLETE_ELEMENT_RELATION REVERT, checking the metadata_id for the relation modified during revert obsolete")
	 or diag "Looks like this failed";



     ###########################################
     ## NINTH BLOCK: General Store function ##
     ###########################################

     ## First, check if it die correctly (TEST 327 AND 328)

     throws_ok { $sample3->store() } qr/STORE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to store() function';
   
     throws_ok { $sample3->store($schema) } qr/STORE ERROR: Metadbdata supplied/, 
     'TESTING DIE ERROR when argument supplied to store() is not a CXGN::Metadata::Metadbdata object';

     my $sample21 = CXGN::Biosource::Sample->new($schema);
     $sample21->set_sample_name('protocol_test_for_exceptions');
     $sample21->set_sample_type('another test');
     $sample21->add_sample_element({ sample_element_name => 'last test', organism_name => 'Genus species' });
     $sample21->add_dbxref_to_sample_element('last test', $t_dbxref_id2);
     $sample21->add_cvterm_to_sample_element('last test', $t_cvterm_id2);
     $sample21->add_publication($new_pub_id1);
     $sample21->add_file_to_sample_element('last test', $fileids{'test3.txt'});
     $sample21->store($metadbdata);

     ## This not store relation because to do it, it needs store before the sample element

     ## TEST 329 TO 334

     is($sample21->get_sample_id(), $last_sample_id+3, "TESTING GENERAL STORE FUNCTION, checking sample_id")
 	or diag "Looks like this failed";
    
     my %elements21 = $sample21->get_sample_elements();
     is($elements21{'last test'}->{'organism_name'}, 'Genus species', "TESTING GENERAL STORE FUNCTION, checking organism_name")
 	or diag "Looks like this failed";

     my @pub_list21 = $sample21->get_publication_list();
     is($pub_list21[0], $new_pub_id1, "TESTING GENERAL STORE FUNCTION, checking pub_id")
 	or diag "Looks like this failed";

     my %element_dbxref21 = $sample21->get_dbxref_from_sample_elements();
     is($element_dbxref21{'last test'}->[0], $t_dbxref_id2, "TESTING GENERAL STORE FUNCTION, checking dbxref_id")
 	or diag "Looks like this failed";

     my %element_cvterm21 = $sample21->get_cvterm_from_sample_elements();
     is($element_cvterm21{'last test'}->[0], $t_cvterm_id2, "TESTING GENERAL STORE FUNCTION, checking cvterm_id")
 	or diag "Looks like this failed";

     my %element_file21 = $sample21->get_file_from_sample_elements();
     is($element_file21{'last test'}->[0], $fileids{'test3.txt'}, "TESTING GENERAL STORE FUNCTION, checking file_id")
	 or diag "Looks like this failed";
     
     ## Testing dbxref_related function (TEST 335 to 339)

     my %dbxref_related = $sample21->get_dbxref_related();

     foreach my $sample_el_namex (keys %dbxref_related) {
	 my @related_data = @{ $dbxref_related{$sample_el_namex} };

	 foreach my $related_el_href (@related_data) {
	     my %related = %{$related_el_href};
	 
	     is($related{'dbxref.dbxref_id'}, $t_dbxref_id2, "TESTING GET_DBXREF_RELATED FUNCTION, checking dbxref_id")
		 or diag "Looks like this failed";

	     is($related{'dbxref.accession'}, 'TEST_DBXREFSTEP02', "TESTING GET_DBXREF_RELATED FUNCTION, checking dbxref_id")
		 or diag "Looks like this failed";

	     is($related{'cvterm.cvterm_id'}, $t_cvterm_id2, "TESTING GET_DBXREF_RELATED FUNCTION, checking dbxref_id")
		 or diag "Looks like this failed";

	     is($related{'cvterm.name'}, 'testingcvterm4', "TESTING GET_DBXREF_RELATED FUNCTION, checking cvterm.name")
		 or diag "Looks like this failed";

	     is($related{'db.name'}, 'dbtesting', "TESTING GET_DBXREF_RELATED FUNCTION, checking dbxref_id")
		 or diag "Looks like this failed";
	 }
     }
	
     
     
    

};  ## End of the eval function

if ($@) {
    print "\nEVAL ERROR:\n\n$@\n";
}



 ## RESTORING THE ORIGINAL STATE IN THE DATABASE
## To restore the original state in the database, rollback (it is in a transaction) and set the table_sequence values. 

$schema->txn_rollback();

## The transaction change the values in the sequence, so if we want set the original value, before the changes
 ## we have two options:
  ##     1) SELECT setval (<sequence_name>, $last_value_before_change, true); that said, ok your last true value was...
   ##    2) SELECT setval (<sequence_name>, $last_value_before_change+1, false); It is false that your last value was ... so the 
    ##      next time take the value before this.
     ##  
      ##   The option 1 leave the seq information in a original state except if there aren't any value in the seq, that it is
       ##   more as the option 2 

if ($ENV{RESET_DBSEQ}) {
    $schema->set_sqlseq_values_to_original_state(\%last_ids);
}
