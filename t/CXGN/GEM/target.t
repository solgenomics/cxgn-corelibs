#!/usr/bin/perl

=head1 NAME

  target.t
  A piece of code to test the CXGN::GEM::Target module

=cut

=head1 SYNOPSIS

 perl target.t

 Note: To run the complete test the database connection should be done as 
       postgres user 
 (web_usr have not privileges to insert new data into the gem tables)  

 prove experiment.t

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

 This script check 106 variables to test the right operation of the 
 CXGN::GEM::Target module:

=cut

=head1 AUTHORS

 Aureliano Bombarely Gomez
 (ab782@cornell.edu)

=cut


use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 106; # qw | no_plan |; # while developing the test
use Test::Exception;
use Test::Warn;

use CXGN::DB::Connection;
use CXGN::DB::DBICFactory;

BEGIN {
    use_ok('CXGN::GEM::Schema');             ## TEST1
    use_ok('CXGN::GEM::ExperimentalDesign'); ## TEST2
    use_ok('CXGN::GEM::Experiment');         ## TEST3
    use_ok('CXGN::GEM::Target');             ## TEST4
    use_ok('CXGN::Biosource::Sample');       ## TEST5
    use_ok('CXGN::Biosource::Protocol');     ## TEST6
    use_ok('CXGN::Metadata::Metadbdata');    ## TEST7
}

## Check the environment variables
my @env_variables = ('GEMTEST_METALOADER', 'GEMTEST_DBUSER', 'GEMTEST_DBPASS', 'RESET_DBSEQ');
foreach my $env (@env_variables) {
    unless ($ENV{$env} =~ m/^\w+/) {
	print STDERR "ENVIRONMENT VARIABLE WARNING: Environment variable $env was not set for this test. Use perldoc for more info.\n";
    }
}

#if we cannot load the Schema modules, no point in continuing
CXGN::Biosource::Schema->can('connect')
    or BAIL_OUT('could not load the CXGN::Biosource::Schema module');
CXGN::Metadata::Schema->can('connect')
    or BAIL_OUT('could not load the CXGN::Metadata::Schema module');
Bio::Chado::Schema->can('connect')
    or BAIL_OUT('could not load the Bio::Chado::Schema module');
CXGN::GEM::Schema->can('connect')
    or BAIL_OUT('could not load the CXGN::GEM::Schema module');

## Variables predefined
my $creation_user_name = $ENV{GEMTEST_METALOADER};

## The GEM schema contain all the metadata, chado and biosource classes so don't need to create another Metadata schema

## The triggers need to set the search path to tsearch2 in the version of psql 8.1
my $psqlv = `psql --version`;
chomp($psqlv);

my @schema_list = ('gem', 'biosource', 'metadata', 'public');
if ($psqlv =~ /8\.1/) {
    push @schema_list, 'tsearch2';
}

my $schema = CXGN::DB::DBICFactory->open_schema( 'CXGN::GEM::Schema', 
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
my $last_metadata_id = $last_ids{'metadata.md_metadata_metadata_id_seq'} || 0;
my $last_expdesign_id = $last_ids{'gem.ge_experimental_design_experimental_design_id_seq'} || 0;
my $last_experiment_id = $last_ids{'gem.ge_experiment_experiment_id_seq'} || 0;
my $last_target_id = $last_ids{'gem.ge_target_target_id_seq'} || 0;
my $last_target_element_id = $last_ids{'gem.ge_target_element_target_element_id_seq'} || 0;
my $last_dbxref_id = $last_ids{'public.dbxref_dbxref_id_seq'} || 0;

## Create a empty metadata object to use in the database store functions
my $metadbdata = CXGN::Metadata::Metadbdata->new($schema, $creation_user_name);
my $creation_date = $metadbdata->get_object_creation_date();
my $creation_user_id = $metadbdata->get_object_creation_user_by_id();


#######################################
## FIRST TEST BLOCK: Basic functions ##
#######################################

## (TEST FROM 8 to 10)
## This is the first group of tests, to check if an empty object can store and after can return the data
## Create a new empty object; 

my $target = CXGN::GEM::Target->new($schema, undef); 

## Load of the eight different parameters for an empty object using a hash with keys=root name for tha function and
 ## values=value to test

my %test_values_for_empty_object=( target_id          => $last_target_id+1,
				   target_name        => 'target test',
				   experiment_id      => $last_experiment_id+1,
                                  );

## Load the data in the empty object
my @function_keys = sort keys %test_values_for_empty_object;
foreach my $rootfunction (@function_keys) {
    my $setfunction = 'set_' . $rootfunction;
    if ($rootfunction eq 'target_id') {
	$setfunction = 'force_set_' . $rootfunction;
    } 
    $target->$setfunction($test_values_for_empty_object{$rootfunction});
}

## Get the data from the object and store in two hashes. The first %getdata with keys=root_function_name and 
 ## value=value_get_from_object and the second, %testname with keys=root_function_name and values=name for the test.

my (%getdata, %testnames);
foreach my $rootfunction (@function_keys) {
    my $getfunction = 'get_'.$rootfunction;
    my $data = $target->$getfunction();
    $getdata{$rootfunction} = $data;
    my $testname = 'BASIC SET/GET FUNCTION for ' . $rootfunction.' test';
    $testnames{$rootfunction} = $testname;
}

## And now run the test for each function and value

foreach my $rootfunction (@function_keys) {
    is($getdata{$rootfunction}, $test_values_for_empty_object{$rootfunction}, $testnames{$rootfunction}) 
	or diag "Looks like this failed.";
}


## Testing the die results (TEST 11 to 19)

throws_ok { CXGN::GEM::Target->new() } qr/PARAMETER ERROR: None schema/, 
    'TESTING DIE ERROR when none schema is supplied to new() function';

throws_ok { CXGN::GEM::Target->new($schema, 'no integer')} qr/DATA TYPE ERROR/, 
    'TESTING DIE ERROR when a non integer is used to create a protocol object with new() function';

throws_ok { CXGN::GEM::Target->new($schema)->set_getarget_row() } qr/PARAMETER ERROR: None getarget_row/, 
    'TESTING DIE ERROR when none schema is supplied to set_getarget_row() function';

throws_ok { CXGN::GEM::Target->new($schema)->set_getarget_row($schema) } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_getarget_row() is not a CXGN::GEM::Schema::GeTarget row object';

throws_ok { CXGN::GEM::Target->new($schema)->force_set_target_id() } qr/PARAMETER ERROR: None/, 
    'TESTING DIE ERROR when none target_id is supplied to set_force_target_id() function';

throws_ok { CXGN::GEM::Target->new($schema)->force_set_target_id('non integer') } qr/DATA TYPE ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_force_target_id() is not an integer';

throws_ok { CXGN::GEM::Target->new($schema)->set_target_name() } qr/PARAMETER ERROR: None data/, 
    'TESTING DIE ERROR when none data is supplied to set_target_name() function';

throws_ok { CXGN::GEM::Target->new($schema)->set_experiment_id() } qr/PARAMETER ERROR: None/, 
    'TESTING DIE ERROR when none experiment_id is supplied to set_experiment_id() function';

throws_ok { CXGN::GEM::Target->new($schema)->set_experiment_id('non integer') } qr/DATA TYPE ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_experiment_id() is not an integer';



################################################################
## SECOND TEST BLOCK: Experiment Store and Obsolete Functions ##
################################################################

## Use of store functions.

eval {

    ## Before work with any store function for Target, it will need create a Experiment and Experimental_Design rows inside 
    ## the database to get a real experiment_id and experimental_design_id

    my $expdesign = CXGN::GEM::ExperimentalDesign->new($schema);
    $expdesign->set_experimental_design_name('experimental_design_test');
    $expdesign->set_design_type('test');
    $expdesign->set_description('This is a description test');
    
    $expdesign->store_experimental_design($metadbdata);
    my $expdesign_id = $expdesign->get_experimental_design_id();

    ## Also it will create two Experiment Object and store all the data
    
    my $exp1 = CXGN::GEM::Experiment->new($schema);
    $exp1->set_experiment_name('exp1_test');
    $exp1->set_experimental_design_id($expdesign_id);
    $exp1->set_replicates_nr(5);
    $exp1->set_colour_nr(2);
    $exp1->set_contact_id($creation_user_id);

    $exp1->store_experiment($metadbdata);
    my $exp_id1 = $exp1->get_experiment_id();

    my $exp2 = CXGN::GEM::Experiment->new($schema);
    $exp2->set_experiment_name('exp2_test');
    $exp2->set_experimental_design_id($expdesign_id);
    $exp2->set_replicates_nr(5);
    $exp2->set_colour_nr(2);
    $exp2->set_contact_id($creation_user_id);

    $exp2->store_experiment($metadbdata);
    my $exp_id2 = $exp2->get_experiment_id();

    ## Now it will create the Target Object.
    
    my $target1 = CXGN::GEM::Target->new($schema);
    $target1->set_target_name('target1');
    $target1->set_experiment_id($exp_id1);

    $target1->store_target($metadbdata);


    ## Testing the experiment data stored (TEST 20 TO 22)

    my $target_id1 = $target1->get_target_id();
    is($target_id1, $last_target_id+1, "TESTING STORE_TARGET FUNCTION, checking target_id")
 	or diag "Looks like this failed";

    my $target2 = CXGN::GEM::Target->new($schema, $target_id1);
    is($target2->get_target_name(), 'target1', "TESTING STORE_TARGET FUNCTION, checking target_name")
	or diag "Looks like this failed";
    is($target2->get_experiment_id(), $exp_id1, "TESTING STORE_TARGET FUNCTION, checking experiment_id")
 	or diag "Looks like this failed";


    ## Testing the get_medatata function (TEST 23 to 25)

    my $obj_metadbdata = $target2->get_target_metadbdata();
    is($obj_metadbdata->get_metadata_id(), $last_metadata_id+1, "TESTING GET_METADATA FUNCTION, checking the metadata_id")
	 or diag "Looks like this failed";
    is($obj_metadbdata->get_create_date(), $creation_date, "TESTING GET_METADATA FUNCTION, checking create_date")
	 or diag "Looks like this failed";
    is($obj_metadbdata->get_create_person_id_by_username, $creation_user_name, 
        "TESING GET_METADATA FUNCTION, checking create_person by username")
	 or diag "Looks like this failed";
    
    ## Testing die for store_experiment function (TEST 26 and 27)

    throws_ok { $target2->store_target() } qr/STORE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to store_target() function';
    
    throws_ok { $target2->store_target($schema) } qr/STORE ERROR: Metadbdata supplied/, 
    'TESTING DIE ERROR when argument supplied to store_target() is not a CXGN::Metadata::Metadbdata object';
    
    ## Testing if it is_obsolete (TEST 28)

    is($target2->is_target_obsolete(), 0, "TESTING IS_TARGET_OBSOLETE FUNCTION, checking boolean")
	 or diag "Looks like this failed";

    ## Testing obsolete functions (TEST 29 to 32) 

    $target2->obsolete_target($metadbdata, 'testing obsolete');
    
    is($target2->is_target_obsolete(), 1, 
       "TESTING TARGET_OBSOLETE FUNCTION, checking boolean after obsolete the target")
 	or diag "Looks like this failed";
    
    is($target2->get_target_metadbdata()->get_metadata_id, $last_metadata_id+2, 
       "TESTING TARGET_OBSOLETE, checking metadata_id")
 	or diag "Looks like this failed";
    
    $target2->obsolete_target($metadbdata, 'testing obsolete', 'REVERT');
    
    is($target2->is_target_obsolete(), 0, 
       "TESTING REVERT TARGET_OBSOLETE FUNCTION, checking boolean after revert obsolete")
 	or diag "Looks like this failed";

    is($target2->get_target_metadbdata()->get_metadata_id, $last_metadata_id+3, 
       "TESTING REVERT TARGET_OBSOLETE, for metadata_id")
	or diag "Looks like this failed";

    ## Testing die for obsolete function (TEST 33 to 35)

    throws_ok { $target2->obsolete_target() } qr/OBSOLETE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_target() function';
    
    throws_ok { $target2->obsolete_target($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
    'TESTING DIE ERROR when argument supplied to obsolete_target() is not a CXGN::Metadata::Metadbdata object';
    
    throws_ok { $target2->obsolete_target($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
    'TESTING DIE ERROR when none obsolete note is supplied to obsolete_target() function';
    
    ## Testing store for modifications (TEST 36 to 39)

    $target2->set_experiment_id($exp_id2);
    $target2->store_target($metadbdata);
      
    is($target2->get_target_id(), $last_target_id+1, 
       "TESTING STORE_TARGET for modifications, checking the target_id")
 	or diag "Looks like this failed";
    is($target2->get_target_name(), 'target1', 
       "TESTING STORE_TARGET for modifications, checking the target_name")
 	or diag "Looks like this failed";
    is($target2->get_experiment_id(), $exp_id2, 
       "TESTING STORE_TARGET for modifications, checking experiment_id")
	or diag "Looks like this failed";
    
    my $obj_metadbdata2 = $target2->get_target_metadbdata();
    is($obj_metadbdata2->get_metadata_id(), $last_metadata_id+4, 
       "TESTING STORE_TARGET for modifications, checking new metadata_id")
 	or diag "Looks like this failed";
    

    ## Testing new by name
    
    ## Die functions (TEST 40)

    throws_ok { CXGN::GEM::Target->new_by_name() } qr/PARAMETER ERROR: None schema/, 
    'TESTING DIE ERROR when none schema is supplied to constructor: new_by_name()';
    
    ## Warning function (TEST 41)
    warning_like { CXGN::GEM::Target->new_by_name($schema, 'fake element') } qr/DATABASE OUTPUT WARNING/, 
    'TESTING WARNING ERROR when the target_elements do not exists into the database';
		   
    ## Constructor (TEST 43)
    
    my $target3 = CXGN::GEM::Target->new_by_name($schema, 'target1');
    is($target3->get_target_id(), $last_target_id+1, "TESTING NEW_BY_NAME, checking target_id")
	or diag "Looks like this failed";
    
    ############################################
    ## FORTH BLOCK: Target_Elements functions ##
    ############################################

    ## It will test all the functions related with add Target Elements

    ## Prerrequisist Sample and Protocol, so it will add them

    my $sample = CXGN::Biosource::Sample->new($schema);
    $sample->set_sample_name('sample_test');
    ### deprecated new CXGN::Biosource::Sample ### $sample->set_sample_type('test');
    $sample->set_description('This is a description test');
    $sample->set_contact_by_username($ENV{GEMTEST_METALOADER});

    $sample->store_sample($metadbdata);
    my $sample_id = $sample->get_sample_id();

    my $protocol = CXGN::Biosource::Protocol->new($schema);
    $protocol->set_protocol_name('protocol_test');
    $protocol->set_protocol_type('test');
    $protocol->set_description('This is a descrip test');

    $protocol->store_protocol($metadbdata);
    my $protocol_id = $protocol->get_protocol_id();

    ## Test the dies for the add_target_element method (TEST 44 to 47)
    
    throws_ok { $target2->add_target_element() } qr/FUNCTION PARAMETER ERROR: None data/, 
    'TESTING DIE ERROR when none argument is supplied to add_target_element()';
    
    throws_ok { $target2->add_target_element('This is not a hash ref.') } qr/DATA TYPE ERROR: The parameter/, 
    'TESTING DIE ERROR when argument supplied to add_target_element() function is not an hash reference';

    my $hashref_fake_sample = { 
	                        target_element_name   => 'element_1', 
                                sample_id             => $sample_id+1,  ## Sample_id+1 should not exists into the database
			        protocol_id           => $protocol_id,
                                dye                   => 'dye test',
                              };

     my $hashref_fake_protocol = { 
	                           target_element_name   => 'element_1', 
                                   sample_id             => $sample_id,
			           protocol_id           => $protocol_id+1,
                                   dye                   => 'dye test',
                                 };

    throws_ok { warning_like { $target2->add_target_element($hashref_fake_sample) }
                qr/DATABASE WARNING/, 
                'TESTING WARNING ERROR FOR CONSTRUCTOR when do not exists sample paremeter into database' 
              } qr/DATABASE COHERENCE ERROR for add_target_element: Sample/, 
              'TESTING DIE ERROR when argument supplied to add_target_element() has sample_id that do not exists in the db';

    throws_ok { warning_like { $target2->add_target_element($hashref_fake_protocol) }
                qr/DATABASE WARNING/, 
                'TESTING WARNING ERROR FOR CONSTRUCTOR when do not exists protocol parameter into database' 
              } qr/DATABASE COHERENCE ERROR for add_target_element: Protocol/, 
              'TESTING DIE ERROR when argument supplied to add_target_element() has protocol_id that do not exists in the db';

    ## Now it will add one element ...

    my $hashref_element1 = { 
	                     target_element_name   => 'element_1', 
                             sample_id             => $sample_id,
		             protocol_id           => $protocol_id,
                             dye                   => 'dye1 test',
                           };
    
    $target2->add_target_element($hashref_element1);

    my %target_elements_1 = $target2->get_target_elements();
    
    ## Now it should have one element (TEST 48)
    
    is( scalar(keys %target_elements_1), 1, 'TESTING ADD_TARGET_ELEMENT, checking element number')
	or diag "Looks like this fail";

    ## Test if it can add the same element and fail (TEST 49)

    throws_ok { $target2->add_target_element($hashref_element1) } qr/FUNCTION ERROR: Target_element_name/, 
                'TESTING DIE ERROR when it is adding the same element to the object';

    my $hashref_element2 = { 
                             target_element_name   => 'element_2', 
                             sample_id             => $sample_id,
     		             protocol_id           => $protocol_id,
                             dye                   => 'dye2 test',
                           };

    $target2->add_target_element($hashref_element2);

    ## Testing store function (TEST 50 to 57)

    $target2->store_target_elements($metadbdata);

    my $target4 = CXGN::GEM::Target->new($schema, $target2->get_target_id() );

    my %target_elements_2 = $target4->get_target_elements();

    is( scalar(keys %target_elements_2), 2, 'TESTING STORE_TARGET_ELEMENT, checking element number')
	or diag "Looks like this fail";
    
    my $i = 1;
    foreach my $target_element_name (keys %target_elements_2) {
	is( $target_elements_2{$target_element_name}->{'target_element_id'}, $last_target_element_id+$i, 
	    "TESTING STORE_TARGET_ELEMENT, checking target_element_id ($i)" )
	    or diag "Looks like this failed";
	is( $target_elements_2{$target_element_name}->{'sample_id'}, $sample_id, 
	    "TESTING STORE_TARGET_ELEMENT, checking sample_id ($i)" )
	    or diag "Looks like this failed";
	is( $target_elements_2{$target_element_name}->{'protocol_id'}, $protocol_id, 
	    "TESTING STORE_TARGET_ELEMENT, checking protocol_id ($i)" )
	    or diag "Looks like this failed";
	is( $target_elements_2{$target_element_name}->{'dye'}, "dye". $i ." test", 
	    "TESTING STORE_TARGET_ELEMENT, checking dye ($i)" )
	    or diag "Looks like this failed";
	$i++;
    }

    ## Testing store for modifications (TEST 58 and 59)

    $target4->edit_target_element('element_2', { dye => 'dye3 test'} );
    
    $target4->store_target_elements($metadbdata);

    my $target5 = CXGN::GEM::Target->new($schema, $target2->get_target_id() );

    my %target_elements_3 = $target5->get_target_elements();
    is( $target_elements_3{'element_1'}->{'dye'}, "dye1 test", 
	"TESTING EDIT_TARGET_ELEMENT and STORE_TARGET_ELEMENT for modifications, checking unmodified dye" )
	or diag "Looks like this failed";
    is( $target_elements_3{'element_2'}->{'dye'}, "dye3 test", 
	"TESTING EDIT_TARGET_ELEMENT and STORE_TARGET_ELEMENT for modifications, checking modified dye" )
	or diag "Looks like this failed";

    ## Testing metadbdata functions

    my %element_metadbdata = $target5->get_target_element_metadbdata();
    
    ## The modified element should have last_metadata_id+6 and the unmodified last_metadata_id (TEST 60 to 62)

    is($element_metadbdata{'element_1'}->get_metadata_id(), $last_metadata_id+1, 
       "TESTING GET_TARGET_METADATA, cheking metadata_id for unmodified element") 
	or diag "Looks like this failed";
    is($element_metadbdata{'element_2'}->get_metadata_id(), $last_metadata_id+5, 
       "TESTING GET_TARGET_METADATA, cheking metadata_id for unmodified element") 
	or diag "Looks like this failed";
    is($element_metadbdata{'element_1'}->get_create_person_id_by_username(), $creation_user_name, 
       "TESTING GET_TARGET_METADATA, cheking creation_username for unmodified element") 
	or diag "Looks like this failed";

    ## Testing die for obsolete function (TEST 63 to 66)

    throws_ok { $target2->obsolete_target_element() } qr/OBSOLETE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_target_element() function';
    
    throws_ok { $target2->obsolete_target_element($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
    'TESTING DIE ERROR when argument supplied to obsolete_target_element() is not a CXGN::Metadata::Metadbdata object';
    
    throws_ok { $target2->obsolete_target_element($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
    'TESTING DIE ERROR when none obsolete note is supplied to obsolete_target_element() function';

    throws_ok { $target2->obsolete_target_element($metadbdata, 'note') } qr/OBSOLETE ERROR: None target/, 
    'TESTING DIE ERROR when none obsolete target_element_name is supplied to obsolete_target_element() function';


    ## Testing obsolete functions (TEST 67 to 71)

     is($target5->is_target_element_obsolete('element_1'), 0, 
       "TESTING TARGET_ELEMENT_OBSOLETE FUNCTION, checking boolean before obsolete the target_element")
	 or diag "Looks like this failed";

    $target5->obsolete_target_element($metadbdata, 'testing obsolete target_element', 'element_1');
    
    is($target5->is_target_element_obsolete('element_1'), 1, 
       "TESTING TARGET_ELEMENT_OBSOLETE FUNCTION, checking boolean after obsolete the target_element")
 	or diag "Looks like this failed";

    my %element_metadbdata2 = $target5->get_target_element_metadbdata();

    is($element_metadbdata2{'element_1'}->get_metadata_id, $last_metadata_id+6, 
       "TESTING TARGET_ELEMENT_OBSOLETE, checking metadata_id")
 	or diag "Looks like this failed";
    
    $target5->obsolete_target_element($metadbdata, 'testing obsolete target_element', 'element_1', 'REVERT');
    
    is($target5->is_target_element_obsolete('element_1'), 0, 
       "TESTING REVERT TARGET_ELEMENT_OBSOLETE FUNCTION, checking boolean after revert obsolete")
 	or diag "Looks like this failed";
    
    my %element_metadbdata3 = $target5->get_target_element_metadbdata();

    is($element_metadbdata3{'element_1'}->get_metadata_id, $last_metadata_id+7, 
       "TESTING REVERT TARGET_ELEMENT_OBSOLETE, for metadata_id")
	or diag "Looks like this failed";

    ## Testing new_by_element

    ## Die functions (TEST 72 and 73)

    throws_ok { CXGN::GEM::Target->new_by_elements() } qr/PARAMETER ERROR: None schema/, 
    'TESTING DIE ERROR when none schema is supplied to constructor: new_by_elements()';

    throws_ok { CXGN::GEM::Target->new_by_elements($schema, 'this is not an array') } qr/PARAMETER ERROR: The element array/, 
    'TESTING DIE ERROR when the element array reference is not an array ref. for constructor: new_by_elements()';

    ## Warning function (TEST 74)

    my @fake_elements = ('fake_element1', 'fake_element2');  
    warning_like { CXGN::GEM::Target->new_by_elements($schema, \@fake_elements) } qr/DATABASE OUTPUT WARNING/, 
    'TESTING WARNING ERROR when the target_elements do not exists into the database';

    ## Constructor (TEST 75)
    my $target_by_elements = CXGN::GEM::Target->new_by_elements($schema, ['element_1', 'element_2']);
    is($target_by_elements->get_target_id(), $target5->get_target_id(), "TESTING CONSTRUCTOR NEW_BY_ELEMENTS, checking target_id")
	or diag "Looks like this failed";

    ##########################################
    ## FIFTH BLOCK: Target_Dbxref functions ##
    ##########################################

    ## Testing of the dbxref

    ## First, it need to add all the rows that the chado schema use for a dbxref
 
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

    
    ## Testing the die when the wrong for the row accessions get/set_geexpdesigndbxref_rows (TEST 76 to 78)
    
    throws_ok { $target5->set_getargetdbxref_rows() } qr/FUNCTION PARAMETER ERROR:None getargetdbxref_row/, 
    'TESTING DIE ERROR when none data is supplied to set_getargetdbxref_rows() function';
   
    throws_ok { $target5->set_getargetdbxref_rows('this is not an integer') } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when data type supplied to set_getargetdbxref_rows() function is not an array reference';
    
    throws_ok { $target5->set_getargetdbxref_rows([$schema, $schema]) } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when the elements of the array reference supplied to set_getargetdbxref_rows() function are not row objects';

    ## Check set/get for dbxref (TEST 79)

    $target5->add_dbxref($new_dbxref_id1);
    $target5->add_dbxref( 
 	                  { 
 		 	    accession => 'TESTDBACC02', 
 		            dbxname   => 'dbtesting',
 		          }
 	                );

    my @dbxref_list = ($new_dbxref_id1, $new_dbxref_id2);
    my @dbxref_id_list = $target5->get_dbxref_list();
    my $expected_dbxref_id_list = join(',', sort {$a <=> $b} @dbxref_list);
    my $obtained_dbxref_id_list = join(',', sort {$a <=> $b} @dbxref_id_list);

    is($obtained_dbxref_id_list, $expected_dbxref_id_list, 'TESTING ADD_DBXREF and GET_DBXREF_LIST, checking dbxref_id list')
 	or diag "Looks like this failed";

    ## Store function (TEST 80)

    $target5->store_dbxref_associations($metadbdata);
    
    my $target6 = CXGN::GEM::Target->new($schema, $target5->get_target_id() );
    
    my @dbxref_id_list2 = $target6->get_dbxref_list();
    my $expected_dbxref_id_list2 = join(',', sort {$a <=> $b} @dbxref_list);
    my $obtained_dbxref_id_list2 = join(',', sort {$a <=> $b} @dbxref_id_list2);
    
    is($obtained_dbxref_id_list2, $expected_dbxref_id_list2, 'TESTING STORE DBXREF ASSOCIATIONS, checking dbxref_id list')
	 or diag "Looks like this failed";

    ## Testing die for store function (TEST 81 AND 82)
    
    throws_ok { $target5->store_dbxref_associations() } qr/STORE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to store_dbxref_associations() function';
    
    throws_ok { $target5->store_dbxref_associations($schema) } qr/STORE ERROR: Metadbdata supplied/, 
    'TESTING DIE ERROR when argument supplied to store_dbxref_associations() is not a CXGN::Metadata::Metadbdata object';

    ## Testing obsolete functions (TEST 83 to 85)
     
    my $m = 0;
    foreach my $dbxref_assoc (@dbxref_id_list2) {
	$m++;
 	is($target6->is_target_dbxref_obsolete($dbxref_assoc), 0, 
 	   "TESTING GET_TARGET_DBXREF_METADATA AND IS_EXPERIMENT_DBXREF_OBSOLETE, checking boolean ($m)")
 	    or diag "Looks like this failed";
     }

    my %expdbxref_md1 = $target6->get_target_dbxref_metadbdata();
    is($expdbxref_md1{$dbxref_id_list[1]}->get_metadata_id, $last_metadata_id+1, 
        "TESTING GET_TARGET_DBXREF_METADATA, checking metadata_id")
	 or diag "Looks like this failed";

    ## TEST 86 TO 89

    $target6->obsolete_dbxref_association($metadbdata, 'obsolete test for dbxref', $dbxref_id_list[1]);
    is($target6->is_target_dbxref_obsolete($dbxref_id_list[1]), 1, 
       "TESTING OBSOLETE TARGET DBXREF ASSOCIATIONS, checking boolean") 
 	or diag "Looks like this failed";

    my %targetdbxref_md2 = $target6->get_target_dbxref_metadbdata();
    is($targetdbxref_md2{$dbxref_id_list[1]}->get_metadata_id, $last_metadata_id+8, 
       "TESTING OBSOLETE TARGET DBXREF FUNCTION, checking new metadata_id")
 	or diag "Looks like this failed";

    $target6->obsolete_dbxref_association($metadbdata, 'revert obsolete test for dbxref', $dbxref_id_list[1], 'REVERT');
    is($target6->is_target_dbxref_obsolete($dbxref_id_list[1]), 0, 
       "TESTING OBSOLETE DBXREF ASSOCIATIONS REVERT, checking boolean") 
 	or diag "Looks like this failed";

    my %targetdbxref_md2o = $target6->get_target_dbxref_metadbdata();
    my $targetdbxref_metadata_id2 = $targetdbxref_md2o{$dbxref_id_list[1]}->get_metadata_id();
    is($targetdbxref_metadata_id2, $last_metadata_id+9, "TESTING OBSOLETE DBXREF FUNCTION REVERT, checking new metadata_id")
 	or diag "Looks like this failed";

    ## Checking the errors for obsolete_dbxref_asociation (TEST 90 TO 93)
    
    throws_ok { $target6->obsolete_dbxref_association() } qr/OBSOLETE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_dbxref_association() function';

    throws_ok { $target6->obsolete_dbxref_association($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
    'TESTING DIE ERROR when argument supplied to obsolete_dbxref_association() is not a CXGN::Metadata::Metadbdata object';
    
    throws_ok { $target6->obsolete_dbxref_association($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
    'TESTING DIE ERROR when none obsolete note is supplied to obsolete_dbxref_association() function';
    
    throws_ok { $target6->obsolete_dbxref_association($metadbdata, 'test note') } qr/OBSOLETE ERROR: None dbxref_id/, 
    'TESTING DIE ERROR when none dbxref_id is supplied to obsolete_dbxref_association() function';

    #########################################
    ## SIXTH BLOCK: General Store function ##
    #########################################

    ## First, check if it die correctly (TEST 94 AND 95)

    throws_ok { $target5->store() } qr/STORE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to store() function';
    
    throws_ok { $target5->store($schema) } qr/STORE ERROR: Metadbdata supplied/, 
    'TESTING DIE ERROR when argument supplied to store() is not a CXGN::Metadata::Metadbdata object';

    my $target7 = CXGN::GEM::Target->new($schema);
    $target7->set_target_name('target test');
    $target7->set_experiment_id($exp_id1);

     my $hashref_element3 = { 
	                     target_element_name   => 'element_3', 
                             sample_id             => $sample_id,
		             protocol_id           => $protocol_id,
                             dye                   => 'dye1 test',
                           };
    
    $target7->add_target_element($hashref_element3);
    
     my $hashref_element4 = { 
	                     target_element_name   => 'element_4', 
                             sample_id             => $sample_id,
		             protocol_id           => $protocol_id,
                             dye                   => 'dye2 test',
                           };
    
    $target7->add_target_element($hashref_element4);

    $target7->add_dbxref($new_dbxref_id1);
    
    $target7->store($metadbdata);

    ## Checking the parameters stored

    ## TEST 96 TO 98

    is($target7->get_target_id(), $last_target_id+2, 
        "TESTING GENERAL STORE FUNCTION, checking experiment_id")
	 or diag "Looks like this failed";
    
    my %target_element7 = $target7->get_target_elements();
    my $obtained_element_list = join(',', sort keys %target_element7);
    my $expected_element_list = 'element_3,element_4';
    is($obtained_element_list, $expected_element_list, "TESTING GENERAL STORE FUNCTION, checking target_element_name list")
	or diag "Looks like this failed";

    my @dbxref_list3 = $target7->get_dbxref_list();
    is($dbxref_list3[0], $new_dbxref_id1, "TESTING GENERAL STORE FUNCTION, checking dbxref_id")
	 or diag "Looks like this failed"; 
    
    #################################################################
    ## SIXTH BLOCK: Functions that interact with other GEM objects ##
    #################################################################
    
    ## To test get_experimental_design it doesn't need create any expdesign (this was done in the begining of the script )

    ## Testing experimental_design object (TEST 99 and 100)

    my $expdesign3 = $target7->get_experimental_design();

    is(ref($expdesign3), 'CXGN::GEM::ExperimentalDesign', 
       "TESTING GET_EXPERIMENTAL_DESIGN function, testing object reference")
	or diag "Looks like this failed";
    is($expdesign3->get_experimental_design_name(), 'experimental_design_test', 
       "TESTING GET_EXPERIMENTAL_DESIGN function, testing experimental_design_name")
	or diag "Looks like this failed";

     ## Testing experimental_design object (TEST 101 and 102)
     
    my $exp3 = $target7->get_experiment();

    is(ref($exp3), 'CXGN::GEM::Experiment', 
       "TESTING GET_EXPERIMENT function, testing object reference")
	or diag "Looks like this failed";
    is($exp3->get_experiment_name(), 'exp1_test', 
       "TESTING GET_EXPERIMENT function, testing experimental_design_name")
	or diag "Looks like this failed";

    ## Testing get_sample_list (TEST 103 and 104)

    my @sample_list = $target7->get_sample_list();

    my $x = 0;
    foreach my $sample_t (@sample_list) {
	$x++;
	is(ref($sample_t), 'CXGN::Biosource::Sample', 
	   "TESTING GET_SAMPLE_LIST function, testing object reference for element $x")
	    or diag "Looks like this failed";
	is($sample_t->get_sample_name(), 'sample_test', 
	   "TESTING GET_SAMPLE_LIST function, testing sample_name for element $x")
	    or diag "Looks like this failed";

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
