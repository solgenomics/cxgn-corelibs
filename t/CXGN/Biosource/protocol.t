#!/usr/bin/perl

=head1 NAME

  protocol.t
  A piece of code to test the CXGN::Biosource::Protocol module

=cut

=head1 SYNOPSIS

 perl protocol.t

 Note: To run the complete test the database connection should be done as 
       postgres user 
 (web_usr have not privileges to insert new data into the sed tables)  

 prove protocol.t

 this test needs some environment variables:
    export GEMTEST_METALOADER= 'metaloader user'
    export GEMTEST_DBUSER= 'database user with insert permissions'
    export GEMTEST_DBPASS= 'database password'

 also is recommendable set the reset dbseq after run the script
    export RESET_DBSEQ=1

 if it is not set, after one run all the test that depends of a primary id
 (as metadata_id) will fail because it is calculated based in the last
 primary id and not in the current sequence for this primary id

=head1 DESCRIPTION

 This script check 133 variables to test the right operation of the 
 CXGN::Biosource::Protocol module:

 Test 1 to 4     - Use Modules.
 Test 5 to 8     - BASIC SET/GET FUNCTION for protocol data.
 Test 9 to 16    - TESTING DIE ERRORS for basic set protocol data functions. 
 Test 17 to 19   - TESTING STORE_PROTOCOL FUNCTION.
 Test 20 to 24   - TESTING GET_METADATA FUNCTION and DIE ERROR for protocol 
                   functions.
 Test 25 to 32   - TESTING PROTOCOL_OBSOLETE FUNCTIONS and DIE ERRORS.
 Test 33 to 36   - TESTING STORE_PROTOCOL for modifications
 Test 37         - TESTING NEW_BY_NAME, checking protocol_type
 Test 38 to 40   - TESTING DIE ERROR for set_bsprotocolstep_row function.
 Test 41 to 50   - TESTING ADD/GET/EDIT_PROTOCOL_STEPS and DIE ERROR.
 Test 51 to 57   - TESTING STORE_PROTOCOL_STEP and DIE ERRORS.
 Test 58 and 60  - TESTING GET_PROTOCOL_STEP_METADBDATA.
 Test 61 and 62  - TESTING STORE_PROTOCOL_STEPS for modification
 Test 63 to 65   - TESTING IS_PROTOCOL_STEP_OBSOLETE functions.
 Test 66 to 68   - TESTING DIE ERROR for set_bsprotocolpub_rows() function
 Test 69 to 71   - TESTING ADD_PUBLICATION and GET_PUBLICATION_LIST
 Test 72 to 74   - TESTING STORE PUB ASSOCIATIONS and DIE ERRORS 
 Test 75 to 77   - TESTING GET_PROTOCOL_PUB_METADATA AND IS_TOOL_PUB_OBSOLETE
 Test 78         - TESTING OBSOLETE PUB ASSOCIATIONS
 Test 79 to 82   - TESTING DIE ERROR for obsolete functions
 Test 83 to 91   - TESTING DIE ERROR for set_bsstepdbxref_rows() 
                   and add_dbxref_to_protocol_step() functions
 Test 92 to 96   - TESTING ADD/GET_DBXREF_TO_PROTOCOL_STEP.
 Test 97 to 105  - TESTING STORE_STEP_DBXREF_ASSOCIATION and DIE ERRORS.
 Test 106 to 114 - TESTING GET_STEP_DBXREF_METADBDATA and DIE ERRORS
 Test 115 to 127 -  TESTING  STEP_DBXREF_OBSOLETE FUNCTIONS.
 Test 128 to 133 -  TESTING GENERAL STORE FUNCTION

=cut

=head1 AUTHORS

 Aureliano Bombarely Gomez
 (ab782@cornell.edu)

=cut


use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 133; # qw | no_plan |; # while developing the test
use Test::Exception;

use CXGN::DB::Connection;
use CXGN::DB::DBICFactory;

BEGIN {
    use_ok('CXGN::Biosource::Schema');               ## TEST1
    use_ok('CXGN::Biosource::Protocol');             ## TEST2
    use_ok('CXGN::Biosource::ProtocolTool');         ## TEST3
    use_ok('CXGN::Metadata::Metadbdata');            ## TEST4
}

## Check the environment variables
my @env_variables = ('GEMTEST_METALOADER', 'GEMTEST_DBUSER', 'GEMTEST_DBPASS', 'RESET_DBSEQ');
foreach my $env (@env_variables) {
    unless ($ENV{$env} =~ m/^\w+/) {
	print STDERR "ENVIRONMENT VARIABLE WARNING: Environment variable $env was not set for this test. Use perldoc for more info.\n";
    }
}

#if we cannot load the CXGN::Metadata::Schema module, no point in continuing
CXGN::Biosource::Schema->can('connect')
    or BAIL_OUT('could not load the CXGN::Biosource::Schema module');
CXGN::Metadata::Schema->can('connect')
    or BAIL_OUT('could not load the CXGN::Metadata::Schema module');

## Prespecified variable

my $metadata_creation_user = $ENV{GEMTEST_METALOADER};

## The biosource schema contain all the metadata classes so don't need to create another Metadata schema


## The triggers need to set the search path to tsearch2 in the version of psql 8.1
my $psqlv = `psql --version`;
chomp($psqlv);

my @schema_list = ('biosource', 'metadata', 'public');
if ($psqlv =~ /8\.1/) {
    push @schema_list, 'tsearch2';
}

my $schema = CXGN::DB::DBICFactory->open_schema( 'CXGN::Biosource::Schema', 
                                                 search_path => \@schema_list, 
                                                 dbconn_args => 
                                                                { 
                                                                    dbuser => $ENV{GEMTEST_DBUSER},
                                                                    dbpass => $ENV{GEMTEST_DBPASS},
                                                                }
                                               );

$schema->txn_begin();


## Get the last values
my $all_last_ids_href = $schema->get_all_last_ids($schema);
my %last_ids = %{$all_last_ids_href};
my $last_metadata_id = $last_ids{'metadata.md_metadata_metadata_id_seq'};
my $last_protocol_id = $last_ids{'biosource.bs_protocol_protocol_id_seq'};

## Create a empty metadata object to use in the database store functions
my $metadbdata = CXGN::Metadata::Metadbdata->new($schema, $metadata_creation_user);
my $creation_date = $metadbdata->get_object_creation_date();
my $creation_user_id = $metadbdata->get_object_creation_user_by_id();


#######################################
## FIRST TEST BLOCK: Basic functions ##
#######################################


## (TEST FROM 5 TO 8)
## This is the first group of tests, to check if an empty object can store and after can return the data
## Create a new empty object; 

my $protocol = CXGN::Biosource::Protocol->new($schema, undef); 

## Load of the eight different parameters for an empty object using a hash with keys=root name for tha function and
 ## values=value to test

my %test_values_for_empty_object=( protocol_id    => $last_protocol_id+1,
				   protocol_name  => 'protocol test',
				   protocol_type  => 'test',
				   description    => 'this is a test',
                                  );

## Load the data in the empty object
my @function_keys = sort keys %test_values_for_empty_object;
foreach my $rootfunction (@function_keys) {
    my $setfunction = 'set_' . $rootfunction;
    if ($rootfunction eq 'protocol_id') {
	$setfunction = 'force_set_' . $rootfunction;
    } 
    $protocol->$setfunction($test_values_for_empty_object{$rootfunction});
}
## Get the data from the object and store in two hashes. The first %getdata with keys=root_function_name and 
 ## value=value_get_from_object and the second, %testname with keys=root_function_name and values=name for the test.

my (%getdata, %testnames);
foreach my $rootfunction (@function_keys) {
    my $getfunction = 'get_'.$rootfunction;
    my $data = $protocol->$getfunction();
    $getdata{$rootfunction} = $data;
    my $testname = 'BASIC SET/GET FUNCTION for ' . $rootfunction.' test';
    $testnames{$rootfunction} = $testname;
}

## And now run the test for each function and value

foreach my $rootfunction (@function_keys) {
    is($getdata{$rootfunction}, $test_values_for_empty_object{$rootfunction}, $testnames{$rootfunction}) 
	or diag "Looks like this failed.";
}

## Testing the die results (TEST 9 to 16)

throws_ok { CXGN::Biosource::Protocol->new() } qr/PARAMETER ERROR: None schema/, 
    'TESTING DIE ERROR when none schema is supplied to new() function';

throws_ok { CXGN::Biosource::Protocol->new($schema, 'no integer')} qr/DATA TYPE ERROR/, 
    'TESTING DIE ERROR when a non integer is used to create a protocol object with new() function';

throws_ok { CXGN::Biosource::Protocol->new($schema)->set_bsprotocol_row() } qr/PARAMETER ERROR: None bsprotocol_row/, 
    'TESTING DIE ERROR when none schema is supplied to set_bsprotocol_row() function';

throws_ok { CXGN::Biosource::Protocol->new($schema)->set_bsprotocol_row($schema) } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_bsprotocol_row() is not a CXGN::Biosource::Schema::BsProtocol row object';

throws_ok { CXGN::Biosource::Protocol->new($schema)->force_set_protocol_id() } qr/PARAMETER ERROR: None protocol_id/, 
    'TESTING DIE ERROR when none protocol_id is supplied to set_force_protocol_id() function';

throws_ok { CXGN::Biosource::Protocol->new($schema)->force_set_protocol_id('non integer') } qr/DATA TYPE ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_force_protocol_id() is not an integer';

throws_ok { CXGN::Biosource::Protocol->new($schema)->set_protocol_name() } qr/PARAMETER ERROR: None data/, 
    'TESTING DIE ERROR when none data is supplied to set_protocol_name() function';

throws_ok { CXGN::Biosource::Protocol->new($schema)->set_protocol_type() } qr/PARAMETER ERROR: None data/, 
    'TESTING DIE ERROR when none data is supplied to set_protocol_type() function';



###############################################################
### SECOND TEST BLOCK: Protocol Store and Obsolete Functions ##
###############################################################

### Use of store functions.

eval {

    my $protocol2 = CXGN::Biosource::Protocol->new($schema);
    $protocol2->set_protocol_name('protocol_test');
    $protocol2->set_protocol_type('test');
    $protocol2->set_description('This is a descrip test');

    $protocol2->store_protocol($metadbdata);

    ## Testing the protocol_id and protocol_name for the new object stored (TEST 17 to 19)

    is($protocol2->get_protocol_id(), $last_protocol_id+1, "TESTING STORE_PROTOCOL FUNCTION, checking the protocol_id")
	or diag "Looks like this failed";
    is($protocol2->get_protocol_name(), 'protocol_test', "TESTING STORE_PROTOCOL FUNCTION, checking the protocol_name")
	or diag "Looks like this failed";
    is($protocol2->get_description(), 'This is a descrip test', "TESTING STORE_PROTOCOL FUNCTION, checking description")
	or diag "Looks like this failed";

    ## Testing the get_medatata function (TEST 20 to 22)

    my $obj_metadbdata = $protocol2->get_protocol_metadbdata();
    is($obj_metadbdata->get_metadata_id(), $last_metadata_id+1, "TESTING GET_METADATA FUNCTION, checking the metadata_id")
	or diag "Looks like this failed";
    is($obj_metadbdata->get_create_date(), $creation_date, "TESTING GET_METADATA FUNCTION, checking create_date")
	or diag "Looks like this failed";
    is($obj_metadbdata->get_create_person_id_by_username, $metadata_creation_user, 
       "TESING GET_METADATA FUNCTION, checking create_person by username")
	or diag "Looks like this failed";
    
    ## Testing die for store function (TEST 23 and 24)

    throws_ok { $protocol2->store_protocol() } qr/STORE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to store_protocol() function';

    throws_ok { $protocol2->store_protocol($schema) } qr/STORE ERROR: Metadbdata supplied/, 
    'TESTING DIE ERROR when argument supplied to store_protocol() is not a CXGN::Metadata::Metadbdata object';

    ## Testing if it is obsolete (TEST 25)

    is($protocol2->is_protocol_obsolete(), 0, "TESTING IS_PROTOCOL_OBSOLETE FUNCTION, checking boolean")
	or diag "Looks like this failed";

    ## Testing obsolete (TEST 26 to 29) 

    $protocol2->obsolete_protocol($metadbdata, 'testing obsolete');
    
    is($protocol2->is_protocol_obsolete(), 1, "TESTING PROTOCOL_OBSOLETE FUNCTION, checking boolean after obsolete the protocol")
	or diag "Looks like this failed";

    is($protocol2->get_protocol_metadbdata()->get_metadata_id, $last_metadata_id+2, "TESTING PROTOCOL_OBSOLETE, checking metadata_id")
	or diag "Looks like this failed";

    $protocol2->obsolete_protocol($metadbdata, 'testing obsolete', 'REVERT');
    
    is($protocol2->is_protocol_obsolete(), 0, "TESTING REVERT PROTOCOL_OBSOLETE FUNCTION, checking boolean after revert obsolete")
	or diag "Looks like this failed";

    is($protocol2->get_protocol_metadbdata()->get_metadata_id, $last_metadata_id+3, "TESTING REVERT PROTOCOL_OBSOLETE, for metadata_id")
	or diag "Looks like this failed";

    ## Testing die for obsolete function (TEST 30 to 32)

    throws_ok { $protocol2->obsolete_protocol() } qr/OBSOLETE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_protocol() function';

    throws_ok { $protocol2->obsolete_protocol($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
    'TESTING DIE ERROR when argument supplied to obsolete_protocol() is not a CXGN::Metadata::Metadbdata object';

    throws_ok { $protocol2->obsolete_protocol($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
    'TESTING DIE ERROR when none obsolete note is supplied to obsolete_protocol() function';
    
    ## Testing store for modifications (TEST 33 to 36)

    $protocol2->set_description('This is another test');
    $protocol2->store_protocol($metadbdata);

    is($protocol2->get_protocol_id(), $last_protocol_id+1, "TESTING STORE_PROTOCOL for modifications, checking the protocol_id")
	or diag "Looks like this failed";
    is($protocol2->get_protocol_name(), 'protocol_test', "TESTING STORE_PROTOCOL for modifications, checking the protocol_name")
	or diag "Looks like this failed";
    is($protocol2->get_description(), 'This is another test', "TESTING STORE_PROTOCOL for modifications, checking description")
	or diag "Looks like this failed";

    my $obj_metadbdata2 = $protocol2->get_protocol_metadbdata();
    is($obj_metadbdata2->get_metadata_id(), $last_metadata_id+4, "TESTING STORE_PROTOCOL for modifications, checking new metadata_id")
	or diag "Looks like this failed";
    

    ## Testing new by name (TEST 37)

    my $protocol3 = CXGN::Biosource::Protocol->new_by_name($schema, 'protocol_test');
    is($protocol3->get_protocol_type(), 'test', "TESTING NEW_BY_NAME, checking protocol_type")
	or diag "Looks like this failed";



    ###########################################
    ## THIRD BLOCK: Protocol_Steps functions ##
    ###########################################

    ## Testing die functions for set_bsprotocolstep_rows (TEST 38 to 40)

    throws_ok { $protocol2->set_bsprotocolstep_rows() } qr/FUNCTION PARAMETER ERROR: None bsprotocolstep_row hash ref/, 
    'TESTING DIE ERROR when none bsprotocolstep_row hash ref is supplied to set_bsprotocolstep_rows() function';

    throws_ok { $protocol2->set_bsprotocolstep_rows('test') } qr/SET ARGUMENT ERROR: hash ref./, 
    'TESTING DIE ERROR when bsprotocolstep_row supplied to set_bsprotocolstep_rows() function is not a hash reference';

    throws_ok { $protocol2->set_bsprotocolstep_rows({ 1 => 'test'}) } qr/SET ARGUMENT ERROR: row obj/, 
    'TESTING DIE ERROR when bsprotocolstep_row hash ref supplied to set_bsprotocolstep_rows() have not BsProtocolStep row obj. as values';

    ## Before test the steps functions we need to add a new tool.

    my $tool = CXGN::Biosource::ProtocolTool->new($schema);
    $tool->set_tool_data( 
	                  { 
                            tool_name        => 'testingtool', 
                            tool_type        => 'test', 
                            tool_description => 'this is a test',
                          } 
                        );
    $tool->store($metadbdata);
    my $tool_id = $tool->get_tool_id();

    $protocol3->add_protocol_step(
                                   { 
                                     step       => '1',
				     action     => 'test',
				     execution  => 'prove test.t',
				     tool_name  => 'testingtool',
				     begin_date => '2009-10-03 12:00:00',
				     end_date   => '2009-10-03 12:05:00',
				     location   => 'Ithaca, NY, USA',
                                   }
	                         );

    $protocol3->add_protocol_step(
                                   { 
                                     step       => '2',
				     action     => 'test',
				     execution  => 'perl test.t',
				     tool_name  => 'testingtool',
				     begin_date => '2009-10-03 12:05:00',
				     end_date   => '2009-10-03 12:10:00',
				     location   => 'Ithaca, NY, USA',
                                   }
	                         );

    my %protocol_steps = $protocol3->get_protocol_steps();

    ## TEST 41 to 43

    is(scalar(keys %protocol_steps), 2, "TESTING ADD/GET_PROTOCOL_STEPS, checking the protocol steps number")
	or diag "Looks like this failed";

    is($protocol_steps{1}->{execution}, 'prove test.t', "TESTING ADD/GET_PROTOCOL_STEPS, checking the protocol steps execution")
	or diag "Looks like this failed";
    is($protocol_steps{2}->{tool_id}, $tool_id, "TESTING ADD/GET_PROTOCOL_STEPS, checking the protocol_steps, tool_id ")
	or diag "Looks like this failed";

    ## testing die for add_protocol_steps (TEST 44 and 45)

    throws_ok { $protocol3->add_protocol_step() } qr/FUNCTION PARAMETER ERROR: None data/, 
    'TESTING DIE ERROR when none data is supplied to add_protocol_step() function';

    throws_ok { $protocol3->add_protocol_step('test') } qr/DATA TYPE ERROR: The parameter hash ref/, 
    'TESTING DIE ERROR when data type supplied to add_protocol_step() function is not a hash reference';

    ## testing the edit function (edit_protocol_step) (TEST 46)

    $protocol3->edit_protocol_step( 1, {execution => 'perl -w test.t'});
    
    my %protocol_steps2 = $protocol3->get_protocol_steps();
    is($protocol_steps2{1}->{execution}, 'perl -w test.t', "TESTING EDIT_PROTOCOL_STEP, checking the protocol step execution")
	or diag "Looks like this failed";

    ## testing die for add_protocol_steps (TEST 47 to 50)

    throws_ok { $protocol3->edit_protocol_step() } qr/FUNCTION PARAMETER ERROR: None data/, 
    'TESTING DIE ERROR when none data is supplied to edit_protocol_step() function';

    throws_ok { $protocol3->edit_protocol_step('this is not an integer') } qr/DATA TYPE ERROR: The step argument/, 
    'TESTING DIE ERROR when data type supplied to edit_protocol_step() function is not an integer';

    throws_ok { $protocol3->edit_protocol_step(1) } qr/FUNCTION PARAMETER ERROR: None parameter hash/, 
    'TESTING DIE ERROR when none parameter hash reference is supplied to edit_protocol_step() function';
  
    throws_ok { $protocol3->edit_protocol_step(1, ["this isn't a hash","it's an array ref"]) } qr/DATA TYPE ERROR: The parameter hash/, 
    'TESTING DIE ERROR when parameter hash reference supplied to edit_protocol_step() function is not an hash reference';

    ## Store function for protocol_steps (TEST 51 and 52)

    $protocol3->store_protocol_steps($metadbdata);
    
    my %protocol_steps3 = $protocol3->get_protocol_steps();
    is($protocol_steps3{1}->{metadata_id}, $last_metadata_id+1, "TESTING STORE_PROTOCOL_STEP, checking the metadata_id (for step 1)")
	or diag "Looks like this failed";
    is($protocol_steps3{2}->{metadata_id}, $last_metadata_id+1, "TESTING STORE_PROTOCOL_STEP, checking the metadata_id (for step 2)")
	or diag "Looks like this failed";
    
    ## Checkig getting a new object

    my $protocol4 = CXGN::Biosource::Protocol->new($schema, $protocol3->get_protocol_id() );
    
    ## This protocol should have the data associated to the protocol_steps in protocol3 (TEST 53 and 54)

    my %protocol_steps4 = $protocol4->get_protocol_steps();
    
    is($protocol_steps4{1}->{execution}, 'perl -w test.t', "TESTING STORE_PROTOCOL_STEPS, checking the protocol steps execution")
	or diag "Looks like this failed";
    is($protocol_steps4{2}->{tool_id}, $tool_id, "TESTING STORE_PROTOCOL_STEPS, checking the protocol_steps, tool_id ")
	or diag "Looks like this failed";
    
    ## Testing the die for the store_protocol_step function, to do it i will create an empty object
    ## without any protocol_id (TEST 55 to 57)
    
    my $protocol5 = CXGN::Biosource::Protocol->new($schema);
    $protocol5->set_protocol_name('protocol_test_for_exceptions');
    $protocol5->set_protocol_type('another test');
    $protocol5->add_protocol_step({ step => 1, action => 'test', execution => 'prove test.t' });

    throws_ok { $protocol5->store_protocol_steps() } qr/STORE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to store_protocol_step() function';

    throws_ok { $protocol5->store_protocol_steps($schema) } qr/STORE ERROR: Metadbdata supplied/, 
    'TESTING DIE ERROR when metadbdata object supplied to store_protocol_step() function is not a CXGN::Metadata::Metadbdata object';

    throws_ok { $protocol5->store_protocol_steps($metadbdata) } qr/STORE ERROR: Don't exist protocol_id/, 
    'TESTING DIE ERROR when do not exists protocol_id associated to the protocol_step data';
    
    ## Testing the function get_protocol_step_metadata (TEST 58 and 59)

    my %protocol_step_metadata = $protocol4->get_protocol_step_metadbdata($metadbdata);
    is ($protocol_step_metadata{1}->get_metadata_id(), $last_metadata_id+1, "TESTING GET_PROTOCOL_STEP_METADBDATA, checking metadata_id")
	or diag "Looks like this failed";
    is ($protocol_step_metadata{2}->get_create_date(), $creation_date, "TESTING GET_PROTOCOL_STEP_METADBDATA, checking creation_date")
	or diag "Looks like this failed";

    ## Testing error form get_protocol_step_metadata (TEST 60)

     throws_ok { $protocol5->get_protocol_step_metadbdata($metadbdata) } qr/OBJECT MANIPULATION ERROR: The object/, 
    'TESTING DIE ERROR when do not exists protocol_id associated to the protocol_step data and try to get metadbdata object';

    ## Testing edit function and store as modification of the data (TEST 61 and 62)

    $protocol3->edit_protocol_step( 1, {execution => 'prove test.t'});
    $protocol3->store_protocol_steps($metadbdata);

    my $protocol6 = CXGN::Biosource::Protocol->new($schema, $protocol3->get_protocol_id() );
    my %protocol_steps6 = $protocol6->get_protocol_steps();

    is($protocol_steps6{1}->{execution}, 'prove test.t', "TESTING STORE_PROTOCOL_STEPS for modification, checking execution")
	or diag "Looks like this failed";
    
    is($protocol_steps6{1}->{metadata_id}, $last_metadata_id+5, "TESTING STORE_PROTOCOL_STEPS for modification, checking metadata_id")
	or diag "Looks like this failed";

    ## Testing obsolete functions (TEST 63 and 65)

    is($protocol6->is_protocol_step_obsolete(2), 0, "TESTING IS_PROTOCOL_STEP_OBSOLETE, checking boolean")
	or diag "Looks like this failed";
    
    $protocol6->obsolete_protocol_step($metadbdata, 'obsolete_test', 2);

    is($protocol6->is_protocol_step_obsolete(2), 1, "TESTING OBSOLETE_PROTOCOL_STEP, checking boolean for new obsolete")
	or diag "Looks like this failed";

    $protocol6->obsolete_protocol_step($metadbdata, 'obsolete_test', 2, 'REVERT');

    is($protocol6->is_protocol_step_obsolete(2), 0, "TESTING OBSOLETE_PROTOCOL_STEP REVERT, checking boolean for new obsolete")
	or diag "Looks like this failed";




    #########################################
    ## FORTH BLOCK: Protocol_Pub functions ##
    #########################################

    ## Testing of the publication

    ## Testing the die when the wrong for the row accessions get/set_bsprotocolpub_rows (TEST 66 to 68)
    
    throws_ok { $protocol3->set_bsprotocolpub_rows() } qr/FUNCTION PARAMETER ERROR: None bsprotocolpub_row/, 
    'TESTING DIE ERROR when none data is supplied to set_bsprotocolpub_rows() function';

    throws_ok { $protocol3->set_bsprotocolpub_rows('this is not an integer') } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when data type supplied to set_bsprotocolpub_rows() function is not an array reference';

    throws_ok { $protocol3->set_bsprotocolpub_rows([$schema, $schema]) } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when the elements of the  array reference supplied to set_bsprotocolpub_rows() function are not row objects';


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

    my $new_dbxref_id = $schema->resultset('General::Dbxref')
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

     my $new_cvterm_id = $schema->resultset('Cv::Cvterm')
                                ->new( 
                                   { 
                                      cv_id      => $new_cv_id,
                                      name       => 'testingcvterm',
                                      definition => 'this is a test for add tool-pub relation',
                                      dbxref_id  => $new_dbxref_id,
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
                                         type_id        => $new_cvterm_id,
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
                                        type_id        => $new_cvterm_id,
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
                                        type_id        => $new_cvterm_id,
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
                                        dbxref_id => $new_dbxref_id,   
                                      }
                                    )
                               ->insert();

    ## TEST 69 AND 70

    $protocol3->add_publication($new_pub_id1);
    $protocol3->add_publication({ title => 'testingtitle2' });
    $protocol3->add_publication({ dbxref_accession => 'TESTDBACC01' });

    my @pub_id_list = $protocol3->get_publication_list();
    my $expected_pub_id_list = join(',', sort {$a <=> $b} @pub_list);
    my $obtained_pub_id_list = join(',', sort {$a <=> $b} @pub_id_list);

    is($obtained_pub_id_list, $expected_pub_id_list, 'TESTING ADD_PUBLICATION and GET_PUBLICATION_LIST, checking pub_id list')
         or diag "Looks like this failed";

    my @pub_title_list = $protocol3->get_publication_list('title');
    my $expected_pub_title_list = 'testingtitle1,testingtitle2,testingtitle3';
    my $obtained_pub_title_list = join(',', sort @pub_title_list);
    
    is($obtained_pub_title_list, $expected_pub_title_list, 'TESTING GET_PUBLICATION_LIST TITLE, checking pub_title list')
         or diag "Looks like this failed";


    ## Only the third pub has associated a dbxref_id (the rest will be undef) (TEST 71)
    my @pub_accession_list = $protocol3->get_publication_list('accession');
    my $expected_pub_accession_list = 'TESTDBACC01';
    my $obtained_pub_accession_list = $pub_accession_list[2];   
     
    is($obtained_pub_accession_list, $expected_pub_accession_list, 'TESTING GET_PUBLICATION_LIST ACCESSION, checking pub_accession list')
	or diag "Looks like this failed";


    ## Store functions (TEST 72)

    $protocol3->store_pub_associations($metadbdata);
     
    my $protocol7 = CXGN::Biosource::Protocol->new($schema, $protocol3->get_protocol_id() );
     
    my @pub_id_list2 = $protocol7->get_publication_list();
    my $expected_pub_id_list2 = join(',', sort {$a <=> $b} @pub_list);
    my $obtained_pub_id_list2 = join(',', sort {$a <=> $b} @pub_id_list2);
    
    is($obtained_pub_id_list2, $expected_pub_id_list2, 'TESTING STORE PUB ASSOCIATIONS, checking pub_id list')
         or diag "Looks like this failed";
    
    ## Testing die for store function (TEST 73 AND 74)
    
    throws_ok { $protocol3->store_pub_associations() } qr/STORE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to store_pub_associations() function';
    
    throws_ok { $protocol3->store_pub_associations($schema) } qr/STORE ERROR: Metadbdata supplied/, 
    'TESTING DIE ERROR when argument supplied to store_pub_associations() is not a CXGN::Metadata::Metadbdata object';

    ## Testing obsolete functions (TEST 75 TO 77)
     
    my $n = 0;
    foreach my $pub_assoc (@pub_id_list2) {
         $n++;
         is($protocol7->is_protocol_pub_obsolete($pub_assoc), 0, 
	    "TESTING GET_PROTOCOL_PUB_METADATA AND IS_PROTOCOL_PUB_OBSOLETE, checking boolean ($n)")
             or diag "Looks like this failed";
    }

    ## TEST 78

    $protocol7->obsolete_pub_association($metadbdata, 'obsolete test', $pub_id_list[1]);
    is($protocol7->is_protocol_pub_obsolete($pub_id_list[1]), 1, "TESTING OBSOLETE PUB ASSOCIATIONS, checking boolean") 
         or diag "Looks like this failed";

    ## Checking the errors for obsolete_pub_asociation (TEST 79 TO 82)
    
    throws_ok { $protocol7->obsolete_pub_association() } qr/OBSOLETE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_pub_association() function';

    throws_ok { $protocol7->obsolete_pub_association($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
    'TESTING DIE ERROR when argument supplied to obsolete_pub_association() is not a CXGN::Metadata::Metadbdata object';
    
    throws_ok { $protocol7->obsolete_pub_association($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
    'TESTING DIE ERROR when none obsolete note is supplied to obsolete_pub_association() function';
    
    throws_ok { $protocol7->obsolete_pub_association($metadbdata, 'test note') } qr/OBSOLETE ERROR: None pub_id/, 
    'TESTING DIE ERROR when none pub_id is supplied to obsolete_pub_association() function';

    

    
    #################################################
    ## FIFTH BLOCK: Protocol_Step_Dbxref functions ##
    #################################################

    ## Check if the set_bsstepdbxref_rows die correctly (TEST 83 TO 86)

    throws_ok { $protocol3->set_bsstepdbxref_rows() } qr/FUNCTION PARAMETER ERROR: None bsstepdbxref_row/, 
    'TESTING DIE ERROR when none data is supplied to set_bsstepdbxref_rows() function';

    throws_ok { $protocol3->set_bsstepdbxref_rows('this is not an integer') } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when data type supplied to set_bsstepdbxref_rows() function is not an hash reference';

    throws_ok { $protocol3->set_bsstepdbxref_rows({ 1 => $schema}) } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when the elements of the hash reference supplied to set_bsstepdbxref_rows() function are not array references';

    throws_ok { $protocol3->set_bsstepdbxref_rows({ 1 => [$schema] }) } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when the elements of the array reference supplied to set_bsstepdbxref_rows() function are not an row object';
    
    ## Check if add_dbxref_to_protocol_step die correctly (TEST 87 TO 91)
    
    throws_ok { $protocol3->add_dbxref_to_protocol_step() } qr/FUNCTION PARAMETER ERROR: None data/, 
    'TESTING DIE ERROR when none data is supplied to add_dbxref_to_protocol_step() function';

    throws_ok { $protocol3->add_dbxref_to_protocol_step('this is not an integer') } qr/DATA TYPE ERROR: The step parameter/, 
    'TESTING DIE ERROR when step supplied to add_dbxref_to_protocol_step() function is not an integer';

    throws_ok { $protocol3->add_dbxref_to_protocol_step(1) } qr/FUNCTION PARAMETER ERROR: None dbxref_id/, 
    'TESTING DIE ERROR when none dbxref_id is supplied to add_dbxref_to_protocol_step() function';

    throws_ok { $protocol3->add_dbxref_to_protocol_step(1, 'this is not an integer') } qr/DATA TYPE ERROR: The dbxref_id parameter/, 
    'TESTING DIE ERROR when dbxref_id supplied to add_dbxref_to_protocol_step() function is not an integer';

    throws_ok { $protocol3->add_dbxref_to_protocol_step(1, $new_dbxref_id+1) } qr/DATABASE COHERENCE ERROR: The dbxref_id/, 
    'TESTING DIE ERROR when dbxref_id supplied to add_dbxref_to_protocol_step() do not exists into the database';
    
    ## Adding dbxref_id to protocol steps (we will create to different dbxref_id to do it)
    ## It will add two dbxref to the first step (TESTDBACC01 and TEST_DBXREFSTEP01) and one to the second (TEST_DBXREFSTEP02)

    my $test_dbxref_id1 = $schema->resultset('General::Dbxref')
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

    my $test_dbxref_id2 = $schema->resultset('General::Dbxref')
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
    # TEST 92 TO 96

    $protocol3->add_dbxref_to_protocol_step(1, $new_dbxref_id);
    $protocol3->add_dbxref_to_protocol_step(1, $test_dbxref_id1);
    $protocol3->add_dbxref_to_protocol_step(2, $test_dbxref_id2);

    my %protocolstepdbxref = $protocol3->get_dbxref_from_protocol_steps();
    is(scalar(@{$protocolstepdbxref{1}}), 2, "TESTING ADD/GET_DBXREF_TO_PROTOCOL_STEP, checking dbxref number for step 1")
	or diag "Looks like this failed";
    is(scalar(@{$protocolstepdbxref{2}}), 1, "TESTING ADD/GET_DBXREF_TO_PROTOCOL_STEP, checking dbxref number for step 2")
	or diag "Looks like this failed";
    is($protocolstepdbxref{1}->[0], $new_dbxref_id, "TESTING ADD/GET_DBXREF_TO_PROTOCOL_STEP, checking first dbxref_id for step1")
	or diag "Looks like this failed";
    is($protocolstepdbxref{1}->[1], $test_dbxref_id1, "TESTING ADD/GET_DBXREF_TO_PROTOCOL_STEP, checking second dbxref_id for step1")
	or diag "Looks like this failed";
    is($protocolstepdbxref{2}->[0], $test_dbxref_id2, "TESTING ADD/GET_DBXREF_TO_PROTOCOL_STEP, checking first dbxref_id for step2")
	or diag "Looks like this failed";

    ## Check the store functions for the step dbxref associations:

    ## First, check that the process die correctly (TEST 97 AND 98)

    throws_ok { $protocol3->store_step_dbxref_associations() } qr/STORE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to store_step_dbxref_associations() function';
    
    throws_ok { $protocol3->store_step_dbxref_associations($schema) } qr/STORE ERROR: Metadbdata supplied/, 
    'TESTING DIE ERROR when argument supplied to store_step_dbxref_associations() is not a CXGN::Metadata::Metadbdata object';

    ## TEST 99 TO 103

    $protocol3->store_step_dbxref_associations($metadbdata);

    my $protocol8 = CXGN::Biosource::Protocol->new($schema, $protocol3->get_protocol_id() );
    my %protocolstepdbxref8 = $protocol8->get_dbxref_from_protocol_steps();
    is(scalar(@{$protocolstepdbxref8{1}}), 2, "TESTING STORE_STEP_DBXREF_ASSOCIATION, checking dbxref number for step 1")
	or diag "Looks like this failed";
    is(scalar(@{$protocolstepdbxref8{2}}), 1, "TESTING STORE_STEP_DBXREF_ASSOCIATION, checking dbxref number for step 2")
	or diag "Looks like this failed";
    is($protocolstepdbxref8{1}->[0], $new_dbxref_id, "TESTING STORE_STEP_DBXREF_ASSOCIATION, checking first dbxref_id for step1")
	or diag "Looks like this failed";
    is($protocolstepdbxref8{1}->[1], $test_dbxref_id1, "TESTING STORE_STEP_DBXREF_ASSOCIATION, checking second dbxref_id for step1")
	or diag "Looks like this failed";
    is($protocolstepdbxref8{2}->[0], $test_dbxref_id2, "TESTING STORE_STEP_DBXREF_ASSOCIATION, checking first dbxref_id for step2")
	or diag "Looks like this failed";

    ## Testing when another dbxref_id is added (TEST 104 AND 105)

    $protocol8->add_dbxref_to_protocol_step(1, $test_dbxref_id2);
    $protocol8->store_step_dbxref_associations($metadbdata);
    my $protocol9 = CXGN::Biosource::Protocol->new($schema, $protocol3->get_protocol_id() );
    my %protocolstepdbxref9 = $protocol9->get_dbxref_from_protocol_steps();
    is(scalar(@{$protocolstepdbxref9{1}}), 3, "TESTING STORE_STEP_DBXREF_ASSOCIATION adding new dbxref, checking dbxref number (step 1)")
	or diag "Looks like this failed";
    is(scalar(@{$protocolstepdbxref9{2}}), 1, "TESTING STORE_STEP_DBXREF_ASSOCIATION adding new dbxref, checking dbxref number (step 2)")
	or diag "Looks like this failed";

    ## Testing metadbdata methods

    ## First, check if it die correctly (TEST 106)

    my $protocol10 = CXGN::Biosource::Protocol->new($schema);
    $protocol10->set_protocol_name('protocol_test_for_exceptions');
    $protocol10->set_protocol_type('another test');
    $protocol10->add_protocol_step({ step => 1, action => 'test', execution => 'prove test.t' });
    $protocol10->add_dbxref_to_protocol_step(1, $test_dbxref_id2);

    throws_ok { $protocol10->get_step_dbxref_metadbdata() } qr/OBJECT MANIPULATION ERROR: It haven't/, 
    'TESTING DIE ERROR when tried to get metadbdata using get_step_dbxref_metadbdata from object where step_dbxref has not been stored';

    ## Second test the metadata for the data stored (TEST 107 TO 115)

    my %stepdbxref_metadbdata = $protocol9->get_step_dbxref_metadbdata();
    my $metadbdata_step1dbxref1 = $stepdbxref_metadbdata{1}->{$new_dbxref_id};
    my $metadbdata_step1dbxref2 = $stepdbxref_metadbdata{1}->{$test_dbxref_id1};
    my $metadbdata_step1dbxref3 = $stepdbxref_metadbdata{1}->{$test_dbxref_id2};
    my $metadbdata_step2dbxref1 = $stepdbxref_metadbdata{2}->{$test_dbxref_id2};

    is($metadbdata_step1dbxref1->get_metadata_id(), $last_metadata_id+1, "TESTING GET_STEP_DBXREF_METADBDATA, checking metadata_id (1-1)")
	or diag "Looks like this failed";
    is($metadbdata_step1dbxref2->get_metadata_id(), $last_metadata_id+1, "TESTING GET_STEP_DBXREF_METADBDATA, checking metadata_id (1-2)")
	or diag "Looks like this failed";
    is($metadbdata_step1dbxref3->get_metadata_id(), $last_metadata_id+1, "TESTING GET_STEP_DBXREF_METADBDATA, checking metadata_id (1-3)")
	or diag "Looks like this failed";
    is($metadbdata_step2dbxref1->get_metadata_id(), $last_metadata_id+1, "TESTING GET_STEP_DBXREF_METADBDATA, checking metadata_id (2-1)")
	or diag "Looks like this failed";
    is($metadbdata_step1dbxref1->get_create_date(), $creation_date, "TESTING GET_STEP_DBXREF_METADBDATA, checking creation date (1-1)")
	or diag "Looks like this failed";
    is($metadbdata_step1dbxref2->get_create_date(), $creation_date, "TESTING GET_STEP_DBXREF_METADBDATA, checking creation date (1-2)")
	or diag "Looks like this failed";
    is($metadbdata_step1dbxref3->get_create_date(), $creation_date, "TESTING GET_STEP_DBXREF_METADBDATA, checking creation date (1-3)")
	or diag "Looks like this failed";
    is($metadbdata_step2dbxref1->get_create_date(), $creation_date, "TESTING GET_STEP_DBXREF_METADBDATA, checking creation date (2-1)")
	or diag "Looks like this failed";

    is($protocol9->is_step_dbxref_obsolete(1, $test_dbxref_id2), 0, "TESTING IS_STEP_DBXREF_OBSOLETE, checking boolean")
	or diag "Looks like this failed";
    

    ## Testing obsolete methods (TEST 116 TO 123)

    throws_ok { $protocol7->obsolete_step_dbxref_association() } qr/OBSOLETE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_step_dbxref_association() function';

    throws_ok { $protocol7->obsolete_step_dbxref_association($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
    'TESTING DIE ERROR when argument supplied to obsolete_step_dbxref_association() is not a CXGN::Metadata::Metadbdata object';
    
    throws_ok { $protocol7->obsolete_step_dbxref_association($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
    'TESTING DIE ERROR when none obsolete note is supplied to obsolete_step_dbxref_association() function';
    
    throws_ok { $protocol7->obsolete_step_dbxref_association($metadbdata, 'test note') } qr/OBSOLETE ERROR: None step/, 
    'TESTING DIE ERROR when none step is supplied to obsolete_step_dbxref_association() function';

    throws_ok { $protocol7->obsolete_step_dbxref_association($metadbdata, 'test note', 1) } qr/OBSOLETE ERROR: None dbxref_id/, 
    'TESTING DIE ERROR when none dbxref_id is supplied to obsolete_step_dbxref_association() function';

    throws_ok { $protocol7->obsolete_step_dbxref_association($metadbdata, 'test note', 3, $test_dbxref_id2+1) } qr/DATA COHERENCE ERROR/, 
    'TESTING DIE ERROR when the step and dbxref_id supplied to obsolete_step_dbxref_association() function do not exists inside obj.';

    throws_ok { $protocol7->obsolete_step_dbxref_association($metadbdata, 'test note', 1, $test_dbxref_id2+1) } qr/DATA COHERENCE ERROR/, 
    'TESTING DIE ERROR when the dbxref_id supplied to obsolete_step_dbxref_association() function do not exists inside obj.';

    throws_ok { $protocol7->obsolete_step_dbxref_association($metadbdata, 'test note', 3, $test_dbxref_id2) } qr/DATA COHERENCE ERROR/, 
    'TESTING DIE ERROR when the step supplied to obsolete_step_dbxref_association() function do not exists inside obj.';

    ## TEST 124 TO 127

    $protocol9->obsolete_step_dbxref_association($metadbdata, 'obsolete test', 1, $test_dbxref_id2);
    
    is($protocol9->is_step_dbxref_obsolete(1, $test_dbxref_id2), 1, "TESTING OBSOLETE_STEP_DBXREF_ASSOCIATION, checking boolean")
	or diag "Looks like this failed";
    
    my %stepdbxref_metadbdata_obs = $protocol9->get_step_dbxref_metadbdata();
    my $metadbdata_obs = $stepdbxref_metadbdata_obs{1}->{$test_dbxref_id2};

    $protocol9->obsolete_step_dbxref_association($metadbdata, 'obsolete test', 1, $test_dbxref_id2, 'REVERT');

    is($metadbdata_obs->get_metadata_id(), $last_metadata_id+8,"TESTING OBSOLETE_STEP_DBXREF_ASSOCIATION, metadata_id")
	or diag "Looks like this failed";

    is($protocol9->is_step_dbxref_obsolete(1, $test_dbxref_id2), 0, "TESTING OBSOLETE_STEP_DBXREF_ASSOCIATION REVERT, checking boolean")
	or diag "Looks like this failed";

    my %stepdbxref_metadbdata_rev = $protocol9->get_step_dbxref_metadbdata();
    my $metadbdata_rev = $stepdbxref_metadbdata_rev{1}->{$test_dbxref_id2};

    is($metadbdata_rev->get_metadata_id(), $last_metadata_id+9,"TESTING OBSOLETE_STEP_DBXREF_ASSOCIATION REVERT, metadata_id")
	or diag "Looks like this failed";

    #########################################
    ## SIXTH BLOCK: General Store function ##
    #########################################

    ## First, check if it die correctly (TEST 128 AND 129)

    throws_ok { $protocol3->store() } qr/STORE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to store() function';
    
    throws_ok { $protocol3->store($schema) } qr/STORE ERROR: Metadbdata supplied/, 
    'TESTING DIE ERROR when argument supplied to store() is not a CXGN::Metadata::Metadbdata object';

    my $protocol11 = CXGN::Biosource::Protocol->new($schema);
    $protocol11->set_protocol_name('protocol_test_for_exceptions');
    $protocol11->set_protocol_type('another test');
    $protocol11->add_protocol_step({ step => 5, action => 'global test', execution => 'prove test.t' });
    $protocol11->add_dbxref_to_protocol_step(5, $test_dbxref_id2);
    $protocol11->add_publication($new_pub_id1);
    $protocol11->store($metadbdata);

    ## TEST 130 TO 133

    is($protocol11->get_protocol_id(), $last_protocol_id+2, "TESTING GENERAL STORE FUNCTION, checking protocol.protocol_id")
	or diag "Look like this failed";
    
    my %protocol_steps11 = $protocol11->get_protocol_steps();
    is($protocol_steps11{5}->{action}, 'global test', "TESTING GENERAL STORE FUNCTION, checking protocol_step.action")
	or diag "Look like this failed";

    my @pub_list11 = $protocol11->get_publication_list();
    is($pub_list11[0], $new_pub_id1, "TESTING GENERAL STORE FUNCTION, checking protocol_pub.pub_id")
	or diag "Look like this failed";

    my %protocol_step_dbxref11 = $protocol11->get_dbxref_from_protocol_steps();
    is($protocol_step_dbxref11{5}->[0], $test_dbxref_id2, "TESTING GENERAL STORE FUNCTION, checking protocol_step_dbxref.dbxref_id")
	or diag "Look like this failed";

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
