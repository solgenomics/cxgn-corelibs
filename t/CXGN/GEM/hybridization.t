#!/usr/bin/perl

=head1 NAME

  hybridization.t
  A piece of code to test the CXGN::GEM::Hybridization module

=cut

=head1 SYNOPSIS

 perl hybridization.t

 Note: To run the complete test the database connection should be done as 
       postgres user 
 (web_usr have not privileges to insert new data into the gem tables)  

 prove hybridization.t

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

 This script check 63 variables to test the right operation of the 
 CXGN::GEM::Hybridization module:

=cut

=head1 AUTHORS

 Aureliano Bombarely Gomez
 (ab782@cornell.edu)

=cut


use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 63; # qw | no_plan |; # while developing the test
use Test::Exception;
use Test::Warn;

use CXGN::DB::Connection;
use CXGN::DB::DBICFactory;

BEGIN {
    use_ok('CXGN::GEM::Schema');             ## TEST1
    use_ok('CXGN::GEM::Hybridization');      ## TEST2
    use_ok('CXGN::GEM::Platform');           ## TEST3
    use_ok('CXGN::GEM::Target');             ## TEST4
    use_ok('CXGN::Biosource::Protocol');     ## TEST5
    use_ok('CXGN::Metadata::Metadbdata');    ## TEST6
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

my @schema_list = ('GEM', 'biosource', 'metadata', 'public');
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
my $last_hybridization_id = $last_ids{'gem.ge_hybridization_hybridization_id_seq'} || 0;
my $last_metadata_id = $last_ids{'metadata.md_metadata_metadata_id_seq'} || 0;
my $last_platform_id = $last_ids{'gem.ge_platform_platform_id_seq'} || 0;
my $last_target_id = $last_ids{'gem.ge_target_target_id_seq'} || 0;
my $last_protocol_id = $last_ids{'biosource.bs_protocol_protocol_id_seq'} || 0;



## Create a empty metadata object to use in the database store functions
my $metadbdata = CXGN::Metadata::Metadbdata->new($schema, $creation_user_name);
my $creation_date = $metadbdata->get_object_creation_date();
my $creation_user_id = $metadbdata->get_object_creation_user_by_id();


## Before work with any store function for Hybridization, it will need create a Platform, Technology_type, Experimental_Design, 
## Experiment, Target and Protocol the database to get real ids (There are some functions that check these values before set the
## it in the object)

## Technology_type
    
my $techtype1 = CXGN::GEM::TechnologyType->new($schema);
$techtype1->set_technology_name('techtype1');
$techtype1->set_description('description test for technology_type');

$techtype1->store($metadbdata);
my $techtype_id1 = $techtype1->get_technology_type_id();

## Platform

my $platform1 = CXGN::GEM::Platform->new($schema);
$platform1->set_platform_name('platform_test1');
$platform1->set_technology_type_id($techtype_id1);
$platform1->set_description('description test for platform');
$platform1->set_contact_id($creation_user_id);

$platform1->store($metadbdata);
my $platform_id1 = $platform1->get_platform_id();

## Experimental_design

my $expdesign = CXGN::GEM::ExperimentalDesign->new($schema);
$expdesign->set_experimental_design_name('experimental_design_test');
$expdesign->set_design_type('test');
$expdesign->set_description('This is a description test');
    
$expdesign->store_experimental_design($metadbdata);
my $expdesign_id = $expdesign->get_experimental_design_id();

## Experiment
    
my $exp1 = CXGN::GEM::Experiment->new($schema);
$exp1->set_experiment_name('exp1_test');
$exp1->set_experimental_design_id($expdesign_id);
$exp1->set_replicates_nr(5);
$exp1->set_colour_nr(2);
$exp1->set_contact_id($creation_user_id);

$exp1->store_experiment($metadbdata);
my $exp_id1 = $exp1->get_experiment_id();

## Target (It will create two to check the Store (modification) functions)

my $target1 = CXGN::GEM::Target->new($schema);
$target1->set_target_name('target_test1');
$target1->set_experiment_id($exp_id1);

$target1->store($metadbdata);
my $target_id1 = $target1->get_target_id();

my $target2 = CXGN::GEM::Target->new($schema);
$target2->set_target_name('target_test2');
$target2->set_experiment_id($exp_id1);

$target2->store($metadbdata);
my $target_id2 = $target2->get_target_id();

## Protocol

my $protocol1 = CXGN::Biosource::Protocol->new($schema);
$protocol1->set_protocol_name('protocol_test1');
$protocol1->set_protocol_type('type_test1');
$protocol1->set_description('This is a description test');

$protocol1->store($metadbdata);
my $protocol_id1 = $protocol1->get_protocol_id();

#######################################
## FIRST TEST BLOCK: Basic functions ##
#######################################

## (TEST FROM 7 to 11)
## This is the first group of tests, to check if an empty object can store and after can return the data
## Create a new empty object; 

my $hybridization = CXGN::GEM::Hybridization->new($schema, undef); 

## Load of the eight different parameters for an empty object using a hash with keys=root name for tha function and
## values=value to test

my %test_values_for_empty_object=( hybridization_id => $last_hybridization_id+1,
				   platform_id      => $platform_id1,
				   platform_batch   => 'batch_test1',
				   target_id        => $target_id1,
				   protocol_id      => $protocol_id1,
                                  );

## Load the data in the empty object
my @function_keys = sort keys %test_values_for_empty_object;
foreach my $rootfunction (@function_keys) {
    my $setfunction = 'set_' . $rootfunction;
    if ($rootfunction eq 'hybridization_id') {
	$setfunction = 'force_set_' . $rootfunction;
    } 
    $hybridization->$setfunction($test_values_for_empty_object{$rootfunction});
}

## Get the data from the object and store in two hashes. The first %getdata with keys=root_function_name and 
 ## value=value_get_from_object and the second, %testname with keys=root_function_name and values=name for the test.

my (%getdata, %testnames);
foreach my $rootfunction (@function_keys) {
    my $getfunction = 'get_'.$rootfunction;
    my $data = $hybridization->$getfunction();
    $getdata{$rootfunction} = $data;
    my $testname = 'BASIC SET/GET FUNCTION for ' . $rootfunction.' test';
    $testnames{$rootfunction} = $testname;
}

## And now run the test for each function and value

foreach my $rootfunction (@function_keys) {
    is($getdata{$rootfunction}, $test_values_for_empty_object{$rootfunction}, $testnames{$rootfunction}) 
	or diag "Looks like this failed.";
}


## Testing the die results (TEST 12 to 32)

throws_ok { CXGN::GEM::Hybridization->new() } qr/PARAMETER ERROR: None schema/, 
    'TESTING DIE ERROR when none schema is supplied to new() function';

throws_ok { CXGN::GEM::Hybridization->new($schema, 'no integer')} qr/DATA TYPE ERROR/, 
    'TESTING DIE ERROR when a non integer is used to create a protocol object with new() function';

throws_ok { CXGN::GEM::Hybridization->new($schema)->set_gehybridization_row() } qr/PARAMETER ERROR: None gehybridization_row/, 
    'TESTING DIE ERROR when none schema is supplied to set_gehybridization_row() function';

throws_ok { CXGN::GEM::Hybridization->new($schema)->set_gehybridization_row($schema) } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_gehybridization_row() is not a CXGN::GEM::Schema::GeHybridization row object';

throws_ok { CXGN::GEM::Hybridization->new($schema)->force_set_hybridization_id() } qr/PARAMETER ERROR: None/, 
    'TESTING DIE ERROR when none hybridization_id is supplied to set_force_hybridization_id() function';

throws_ok { CXGN::GEM::Hybridization->new($schema)->force_set_hybridization_id('non integer') } qr/DATA TYPE ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_force_hybridization_id() is not an integer';

throws_ok { CXGN::GEM::Hybridization->new($schema)->set_platform_id() } qr/PARAMETER ERROR: None/, 
    'TESTING DIE ERROR when none platform_id is supplied to set_platform_id() function';

throws_ok { CXGN::GEM::Hybridization->new($schema)->set_platform_id('non integer') } qr/DATA TYPE ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_platform_id() is not an integer';

throws_ok { CXGN::GEM::Hybridization->new($schema)->set_platform_id($last_platform_id+10) } qr/INPUT PARAMETER ERROR/, 
    'TESTING DIE ERROR when platform_id supplied to set_platform_id() function do not exists into the database';

throws_ok { CXGN::GEM::Hybridization->new($schema)->set_platform_by_name() } qr/PARAMETER ERROR: None/, 
    'TESTING DIE ERROR when none platform_by_name is supplied to set_platform_by_name() function';

throws_ok { CXGN::GEM::Hybridization->new($schema)->set_platform_by_name('fake_element') } qr/INPUT PARAMETER ERROR/, 
    'TESTING DIE ERROR when platform_name supplied to set_platform_by_name() function do not exists into the database';

throws_ok { CXGN::GEM::Hybridization->new($schema)->set_target_id() } qr/PARAMETER ERROR: None/, 
    'TESTING DIE ERROR when none target_id is supplied to set_target_id() function';

throws_ok { CXGN::GEM::Hybridization->new($schema)->set_target_id('non integer') } qr/DATA TYPE ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_target_id() is not an integer';

throws_ok { CXGN::GEM::Hybridization->new($schema)->set_target_id($last_target_id+10) } qr/INPUT PARAMETER ERROR/, 
    'TESTING DIE ERROR when target_id supplied to set_target_id() function do not exists into the database';

throws_ok { CXGN::GEM::Hybridization->new($schema)->set_target_by_name() } qr/PARAMETER ERROR: None/, 
    'TESTING DIE ERROR when none target_by_name is supplied to set_target_by_name() function';

throws_ok { CXGN::GEM::Hybridization->new($schema)->set_target_by_name('fake_element') } qr/INPUT PARAMETER ERROR/, 
    'TESTING DIE ERROR when target_name supplied to set_target_by_name() function do not exists into the database';

throws_ok { CXGN::GEM::Hybridization->new($schema)->set_protocol_id() } qr/PARAMETER ERROR: None/, 
    'TESTING DIE ERROR when none protocol_id is supplied to set_protocol_id() function';

throws_ok { CXGN::GEM::Hybridization->new($schema)->set_protocol_id('non integer') } qr/DATA TYPE ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_protocol_id() is not an integer';

throws_ok { CXGN::GEM::Hybridization->new($schema)->set_protocol_id($last_protocol_id+10) } qr/INPUT PARAMETER ERROR/, 
    'TESTING DIE ERROR when protocol_id supplied to set_protocol_id() function do not exists into the database';

throws_ok { CXGN::GEM::Hybridization->new($schema)->set_protocol_by_name() } qr/PARAMETER ERROR: None/, 
    'TESTING DIE ERROR when none protocol_by_name is supplied to set_protocol_by_name() function';

throws_ok { CXGN::GEM::Hybridization->new($schema)->set_protocol_by_name('fake_element') } qr/INPUT PARAMETER ERROR/, 
    'TESTING DIE ERROR when protocol_name supplied to set_protocol_by_name() function do not exists into the database';


###################################################################
## SECOND TEST BLOCK: Hybridization Store and Obsolete Functions ##
###################################################################

## Use of store functions.

eval {

    ## The prerequists ids were created before so it will create the Hybridization Object. 
    ## The accessors get/set ids were tested too, so it will use the accessors 'by_name' to tested

    my $hybridization1 = CXGN::GEM::Hybridization->new($schema);
    $hybridization1->set_platform_by_name('platform_test1');
    $hybridization1->set_platform_batch('batch_test1');
    $hybridization1->set_target_by_name('target_test1');
    $hybridization1->set_protocol_by_name('protocol_test1');
    
    $hybridization1->store_hybridization($metadbdata);


    ## Testing the platform data stored (TEST 33 TO 37)
    
    my $hybridization_id1 = $hybridization1->get_hybridization_id();
    is($hybridization_id1, $last_hybridization_id+1, "TESTING STORE_HYBRIDIZATION FUNCTION, checking hybridization_id")
  	or diag "Looks like this failed";

    my $hybridization2 = CXGN::GEM::Hybridization->new($schema, $hybridization_id1);
    is($hybridization2->get_platform_by_name(), 'platform_test1', "TESTING STORE_HYBRIDIZATION FUNCTION, checking platform_name")
 	or diag "Looks like this failed";
    is($hybridization2->get_platform_batch(), 'batch_test1', "TESTING STORE_HYBRIDIZATION FUNCTION, checking platform_batch")
 	or diag "Looks like this failed";
    is($hybridization2->get_target_by_name(), 'target_test1', "TESTING STORE_HYBRIDIZATION FUNCTION, checking target_name")
 	or diag "Looks like this failed";
    is($hybridization2->get_protocol_by_name(), 'protocol_test1', "TESTING STORE_HYBRIDIZATION FUNCTION, checking protocol_name")
 	or diag "Looks like this failed";
   
    
    ## Testing the get_medatata function (TEST 38 to 40)

    my $obj_metadbdata = $hybridization2->get_hybridization_metadbdata();
    is($obj_metadbdata->get_metadata_id(), $last_metadata_id+1, "TESTING GET_METADATA FUNCTION, checking the metadata_id")
	or diag "Looks like this failed";
    is($obj_metadbdata->get_create_date(), $creation_date, "TESTING GET_METADATA FUNCTION, checking create_date")
	or diag "Looks like this failed";
    is($obj_metadbdata->get_create_person_id_by_username, $creation_user_name, 
       "TESING GET_METADATA FUNCTION, checking create_person by username")
	or diag "Looks like this failed";
    
    ## Testing die for store_platform function (TEST 41 and 42)

    throws_ok { $hybridization2->store_hybridization() } qr/STORE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to store_hybridization() function';
    
    throws_ok { $hybridization2->store_hybridization($schema) } qr/STORE ERROR: Metadbdata supplied/, 
    'TESTING DIE ERROR when argument supplied to store_hybridization() is not a CXGN::Metadata::Metadbdata object';
    
    ## Testing if it is_obsolete (TEST 43)
    
    is($hybridization2->is_hybridization_obsolete(), 0, "TESTING IS_HYBRIDIZATION_OBSOLETE FUNCTION, checking boolean")
	or diag "Looks like this failed";

    ## Testing obsolete functions (TEST 44 to 47) 

     $hybridization2->obsolete_hybridization($metadbdata, 'testing obsolete');
    
     is($hybridization2->is_hybridization_obsolete(), 1, 
        "TESTING HYBRIDIZATION_OBSOLETE FUNCTION, checking boolean after obsolete the hybridization")
  	or diag "Looks like this failed";
    
     is($hybridization2->get_hybridization_metadbdata()->get_metadata_id, $last_metadata_id+2, 
        "TESTING HYBRIDIZATION_OBSOLETE, checking metadata_id")
  	or diag "Looks like this failed";
    
     $hybridization2->obsolete_hybridization($metadbdata, 'testing obsolete', 'REVERT');
    
     is($hybridization2->is_hybridization_obsolete(), 0, 
        "TESTING REVERT HYBRIDIZATION_OBSOLETE FUNCTION, checking boolean after revert obsolete")
  	or diag "Looks like this failed";

     is($hybridization2->get_hybridization_metadbdata()->get_metadata_id, $last_metadata_id+3, 
        "TESTING REVERT HYBRIDIZATION_OBSOLETE, for metadata_id")
 	or diag "Looks like this failed";

    ## Testing die for obsolete function (TEST 48 to 50)

    throws_ok { $hybridization2->obsolete_hybridization() } qr/OBSOLETE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_hybridization() function';
    
    throws_ok { $hybridization2->obsolete_hybridization($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
    'TESTING DIE ERROR when argument supplied to obsolete_hybridization() is not a CXGN::Metadata::Metadbdata object';
    
    throws_ok { $hybridization2->obsolete_hybridization($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
    'TESTING DIE ERROR when none obsolete note is supplied to obsolete_hybridization() function';
    
    ## Testing store for modifications (TEST 51 to 54)

    $hybridization2->set_target_id($target_id2);
    $hybridization2->store_hybridization($metadbdata);
      
    is($hybridization2->get_hybridization_id(), $last_hybridization_id+1, 
       "TESTING STORE_HYBRIDIZATION for modifications, checking the hybridization_id")
  	or diag "Looks like this failed";
    is($hybridization2->get_platform_id(), $platform_id1, 
       "TESTING STORE_HYBRIDIZATION for modifications, checking the platform_id (unmodified variable)")
  	or diag "Looks like this failed";
    is($hybridization2->get_target_id(), $target_id2, 
        "TESTING STORE_HYBRIDIZATION for modifications, checking the target_id (modified variable)")
 	or diag "Looks like this failed";

    my $obj_metadbdata2 = $hybridization2->get_hybridization_metadbdata();
    is($obj_metadbdata2->get_metadata_id(), $last_metadata_id+4, 
       "TESTING STORE_HYBRIDIZATION for modifications, checking new metadata_id")
  	or diag "Looks like this failed";
    
    
    #########################################
    ## FIFTH BLOCK: General Store function ##
    #########################################

    ## First, check if it die correctly (TEST 55 AND 56)

    throws_ok { $hybridization2->store() } qr/STORE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to store() function';
    
    throws_ok { $hybridization2->store($schema) } qr/STORE ERROR: Metadbdata supplied/, 
    'TESTING DIE ERROR when argument supplied to store() is not a CXGN::Metadata::Metadbdata object';

    my $hybridization3 = CXGN::GEM::Hybridization->new($schema);

    $hybridization3->set_platform_by_name('platform_test1');
    $hybridization3->set_platform_batch('batch_test2');
    $hybridization3->set_target_by_name('target_test1');
    $hybridization3->set_protocol_by_name('protocol_test1');

    $hybridization3->store($metadbdata);

    ## Checking the parameters stored

    ## TEST 57
    
     is($hybridization3->get_hybridization_id(), $last_hybridization_id+2, 
        "TESTING GENERAL STORE FUNCTION, checking platform_id")
 	or diag "Looks like this failed";
    

    #################################################################
    ## SIXTH BLOCK: Functions that interact with other GEM objects ##
    #################################################################
   
    ## Testing platform object (TEST 58 and 59)
    
    my $platform3 = $hybridization3->get_platform();
    
    is(ref($platform3), 'CXGN::GEM::Platform', 
        "TESTING GET_PLATFORM function, testing object reference")
	 or diag "Looks like this failed";
    is($platform3->get_platform_name(), 'platform_test1', 
        "TESTING GET_PLATFORM function, testing platform_name")
	 or diag "Looks like this failed";

    ## Testing platform object (TEST 60 and 61)
    
    my $target3 = $hybridization3->get_target();
    
    is(ref($target3), 'CXGN::GEM::Target', 
        "TESTING GET_TARGET function, testing object reference")
	 or diag "Looks like this failed";
    is($target3->get_target_name(), 'target_test1', 
        "TESTING GET_TARGET function, testing target_name")
	 or diag "Looks like this failed";

    ## Testing platform object (TEST 62 and 63)
    
    my $protocol3 = $hybridization3->get_protocol();
    
    is(ref($protocol3), 'CXGN::Biosource::Protocol', 
        "TESTING GET_PROTOCOL function, testing object reference")
	 or diag "Looks like this failed";
    is($protocol3->get_protocol_name(), 'protocol_test1', 
        "TESTING GET_PROTOCOL function, testing protocol_name")
	 or diag "Looks like this failed";
    



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
