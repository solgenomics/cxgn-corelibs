#!/usr/bin/perl

=head1 NAME

  dbiref.t
  A piece of code to test the CXGN::Metadata::Dbiref module

=cut

=head1 SYNOPSIS

 perl Dbiref.t

 Note: To run the complete test the database connection should be done as 
       postgres user 
 (web_usr have not privileges to insert new data into the sed tables)  

 prove Dbiref.t

this test need some environment variables:

   export METADATA_TEST_METALOADER='metaloader user'
   export METADATA_TEST_DBDSN='database dsn as: 
    dbi:DriverName:database=database_name;host=hostname;port=port'

   example: 
    export METADATA_TEST_DBDSN='dbi:Pg:database=sandbox;host=localhost;'
    
   export METADATA_TEST_DBUSER='database user with insert permissions'
   export METADATA_TEST_DBPASS='database password'

=head1 DESCRIPTION

 This script check XX variables to test the right operation of the 
 CXGN::Metadata::DBipath module:

 + test 1 and 3: Test for module use
 + test from 4 to 7: Test to set data into the object without any storage
 + test 8 and 9: Test store function for a new row
 + test 10 and 11: Test store related with metadata for dbipath and dbiref 
 + test 12: Test get_dbipath_obj function
 + test 13: Test set_dbipath_id_by_dbipath_elements
 + test 14 to 23: Test the store function for a modification case.
                  Checking the metadbdata.
 + test 24: Testing constructor new with a id
 + test 25: Testing is_obsolete function
 + test 26: Testing obsolete function
 + test from 27 to 36: Testing the metadbdata associated to obsolete change
 + test 37: Testing the revert tag for the obsolete function
 + test 38 to 47: Testing the metadbdata associated with the revert change  
 + test 48: Testing new_by_accession constructor

=cut

=head1 AUTHORS

 Aureliano Bombarely Gomez
 (ab782@cornell.edu)

=cut


use strict;
use warnings;

use Data::Dumper;
use Test::More;  # use  qw | no_plan | while developing the tests

use CXGN::DB::Connection;

## The tests still need search_path

my @schema_list = ('metadata', 'public');
my $schema_list = join(',', @schema_list);
my $set_path = "SET search_path TO $schema_list";

## First check env. variables and connection

BEGIN {

    ## Env. variables have been changed to use biosource specific ones

    my @env_variables = qw/METADATA_TEST_METALOADER METADATA_TEST_DBDSN METADATA_TEST_DBUSER METADATA_TEST_DBPASS/;

    for my $env (@env_variables) {
        unless (defined $ENV{$env}) {
            plan skip_all => "Environment variable $env not set, aborting";
        }
    }

    eval { 
        CXGN::DB::Connection->new( 
                                   $ENV{METADATA_TEST_DBDSN}, 
                                   $ENV{METADATA_TEST_DBUSER}, 
                                   $ENV{METADATA_TEST_DBPASS}, 
                                   {on_connect_do => $set_path}
                                 ); 
    };

    if ($@ =~ m/DBI connect/) {

        plan skip_all => "Could not connect to database";
    }

    plan tests => 48;
}

BEGIN {
    use_ok('CXGN::Metadata::Schema');               ## TEST1
    use_ok('CXGN::Metadata::Dbiref');               ## TEST2
    use_ok('CXGN::Metadata::Metadbdata');           ## TEST3
}


#if we cannot load the CXGN::Metadata::Schema module, no point in continuing
CXGN::Metadata::Schema->can('connect')
    or BAIL_OUT('could not load the CXGN::Metadata::Schema module');

## Prespecified variable

my $metadata_creation_user = $ENV{METADATA_TEST_METALOADER};

## The biosource schema contain all the metadata classes so don't need to create another Metadata schema
## CXGN::DB::DBICFactory is obsolete, it has been replaced by CXGN::Metadata::Schema

my $schema = CXGN::Metadata::Schema->connect( $ENV{METADATA_TEST_DBDSN}, 
                                               $ENV{METADATA_TEST_DBUSER}, 
                                               $ENV{METADATA_TEST_DBPASS}, 
                                               {on_connect_do => $set_path});

$schema->txn_begin();

## Get the last values
my %nextvals = $schema->get_nextval();
my $last_metadata_id = $nextvals{'md_metadata'};
my $last_dbipath_id = $nextvals{'md_dbipath'};
my $last_dbiref_id = $nextvals{'md_dbiref'};

## Create a empty metadata object to use in the database store functions
my $metadbdata = CXGN::Metadata::Metadbdata->new($schema, $metadata_creation_user);
my $creation_date = $metadbdata->get_object_creation_date();
my $creation_user_id = $metadbdata->get_object_creation_user_by_id();


## FIRST TEST BLOCK (TEST FROM 4 TO 7)
## This is the first group of tests, to check if an empty object can store and after can return the data
## Create a new empty object (It is not necessary add any dbipath_id becuase it don't interact with the db; 

my $dbiref = CXGN::Metadata::Dbiref->new($schema, undef); 

## Load of the eight different parameters for an empty object using a hash with keys=root name for tha function and
 ## values=value to test

my %test_values_for_empty_object=( dbiref_id      => $last_dbiref_id+1,
				   iref_accession => $last_dbipath_id+1,
				   accession      => $last_dbipath_id+1, ## A synonym for iref_accession
				   dbipath_id     => $last_dbipath_id+1,
                                  );

## Load the data in the empty object
my @function_keys = sort keys %test_values_for_empty_object;
foreach my $rootfunction (@function_keys) {
    my $setfunction = 'set_' . $rootfunction;
    if ($rootfunction eq 'dbiref_id') {
	$setfunction = 'force_set_' . $rootfunction;
    } 
    $dbiref->$setfunction($test_values_for_empty_object{$rootfunction});
}
## Get the data from the object and store in two hashes. The first %getdata with keys=root_function_name and 
 ## value=value_get_from_object and the second, %testname with keys=root_function_name and values=name for the test.

my (%getdata, %testnames);
foreach my $rootfunction (@function_keys) {
    my $getfunction = 'get_'.$rootfunction;
    my $data = $dbiref->$getfunction();
    $getdata{$rootfunction} = $data;
    my $testname = 'BASIC SET/GET FUNCTION for ' . $rootfunction.' test';
    $testnames{$rootfunction} = $testname;
}

## And now run the test for each function and value

foreach my $rootfunction (@function_keys) {
    is($getdata{$rootfunction}, $test_values_for_empty_object{$rootfunction}, $testnames{$rootfunction}) 
	or diag "Looks like this failed.";
}

## SECOND BLOCK, Interactions with the DB for metadata object

eval {

    ## First, the store functions check if exists a dbipath_id into the database, so it will create a dbipath id
    ## for the path 'metadata.md_dbipath.dbipath_id' (with itself to be sure that it don't exists into the database)

    ### It will create a new object based in dbipath
    my $dbipath = CXGN::Metadata::Dbipath->new_by_path($schema, ['metadata', 'md_dbipath', 'dbipath_id']);
    my $dbipath_stored = $dbipath->store($metadbdata);
    my $dbipath_id = $dbipath_stored->get_dbipath_id();
    
    ## New, it will create the dbiref object (TEST 8 and 9)
    my $dbiref2 = CXGN::Metadata::Dbiref->new($schema, undef); 
    $dbiref2->set_accession($dbipath_id);
    $dbiref2->set_dbipath_id($dbipath_id);
    my $dbiref2_stored = $dbiref2->store($metadbdata);
    is($dbiref2_stored->get_accession(), $last_dbipath_id+1, 'STORE FUNCTION for a new row, checking iref_accession')
	or diag "Looks like this failed";
    is($dbiref2_stored->get_dbipath_id(), $last_dbipath_id+1, 'STORE FUNCTION for a new row, checking dbipath_id')
	or diag "Looks like this failed";
    
    my $test5 = $dbiref2_stored->get_dbipath_id();

    ## Check the metadata for dbipath and dbiref (TEST 10 and 11)
    ## The metadata should be the same because both were created at the same time (with the same metadbdata)
    my $dbipath_metadata_id = $dbipath_stored->get_metadbdata()->get_metadata_id();
    my $dbiref_metadata_id = $dbiref2_stored->get_metadbdata()->get_metadata_id();
    is($dbipath_metadata_id, $last_metadata_id+1, 'STORE FUNCTION METADATA RELATED, checking metadata_id for a new dbipath')
	or diag "Looks like this failed";
    is($dbiref_metadata_id, $last_metadata_id+1, 'STORE FUNCTION METADATA RELATED, checking metadata_id for a new dbiref')
	or diag "Looks like this failed";
    
    ## Testing get_dbipath_obj function (TEST 12)
    my $dbipath2 = $dbiref2_stored->get_dbipath_obj();
    my @dbipath_elements = $dbipath2->get_dbipath();
    my $dbipath_elements = join('.', @dbipath_elements);
    is($dbipath_elements, 'metadata.md_dbipath.dbipath_id', 'GET DBIPATH_OBJ FUNCTION, checking the dbipath elements')
	or diag "Looks like this failed";

    ## Testing set_dbipath_id_by_dbipath_elements (TEST 13)
    ## Before it need a different dbipath row to set
    my $dbipath3 = CXGN::Metadata::Dbipath->new_by_path($schema, ['metadata', 'md_dbiref', 'dbiref_id']);
    my $dbipath3_stored = $dbipath3->store($metadbdata);
    my $dbipath3_id = $dbipath3_stored->get_dbipath_id();
    
    $dbiref2_stored->set_dbipath_id_by_dbipath_elements(['metadata', 'md_dbiref', 'dbiref_id']);
    is($dbiref2_stored->get_dbipath_id(), $dbipath3_id, 'SET DBIPATH ID BY DBIPATH ELEMENTS, checking the new dbipath_id')
	or diag "Looks like this failed";

    ## Now test store for a modification checking the metadbdata (TEST 14 to 23)
    my $dbiref3_stored = $dbiref2_stored->store($metadbdata);
    my $dbiref3_metadbdata = $dbiref3_stored->get_metadbdata();
    my %metadbdata3 = $dbiref3_metadbdata->get_metadata_by_rows();
    my %expected_metadata3 = ( metadata_id          => $last_metadata_id+2, 
			       create_date          => $creation_date, 
			       create_person_id     => $creation_user_id,
			       modified_date        => $creation_date,
			       modified_person_id   => $creation_user_id,
			       modification_note    => 'set value in dbipath_id column',
			       previous_metadata_id => $last_metadata_id+1,
			       obsolete             => 0 
	                    );
    foreach my $st_metadata_type3 (keys %metadbdata3) {
	my $message3 = "STORE FUNCTION METADBDATA INTERACTION FOR MODIFICATIONS, get_metadbdata test, checking $st_metadata_type3";
	is($metadbdata3{$st_metadata_type3}, $expected_metadata3{$st_metadata_type3}, $message3) or diag "Looks like this failed";
    }

    ## Get a new dbiref using id (TEST 24)
    my $dbiref4 = CXGN::Metadata::Dbiref->new($schema, $dbiref2_stored->get_dbiref_id());
    is($dbiref4->get_accession(), $dbiref2_stored->get_accession(), 'CONSTRUCTOR NEW using a dbxref_id, checking iref_accession')
	or diag "Looks like this failed";

    ## Testing the obsolete features
    ## Checking the is_obsolete function (TEST 25)
    my $obsolete = $dbiref4->is_obsolete();
    is($obsolete, 0,"IS OBSOLETE FUNCTION TEST") or diag "Looks like this failed";

    ## Test the obsolete function (TEST 26)
    my $dbiref5_obsolete = $dbiref4->obsolete($metadbdata, 'change to obsolete test');
    my $obsolete2 = $dbiref5_obsolete->is_obsolete();
    is($obsolete2, 1,"OBSOLETE FUNCTION TEST") or diag "Looks like this failed";

    ## Checking the metadata associated to this obsolete change (TEST 27 to 36)
    my $metadbdata5 = $dbiref5_obsolete->get_metadbdata();
    my %metadbdata5 = $metadbdata5->get_metadata_by_rows();
    my %expected_metadata5 = ( metadata_id          => $last_metadata_id+3, 
			       create_date          => $creation_date, 
			       create_person_id     => $creation_user_id,
			       modified_date        => $creation_date,
			       modified_person_id   => $creation_user_id,
			       modification_note    => 'change to obsolete',
			       previous_metadata_id => $last_metadata_id+2,
			       obsolete             => 1,
			       obsolete_note        => 'change to obsolete test'
	                    );
    foreach my $metadata_type5 (keys %metadbdata5) {
	my $message5 = "STORE FUNCTION METADBDATA INTERACTION FOR OBSOLETE, get_metadbdata test, checking $metadata_type5";
	is($metadbdata5{$metadata_type5}, $expected_metadata5{$metadata_type5}, $message5) or diag "Looks like this failed";
    }

    ## Test the REVERT tag for the obsolete function (TEST 37)
    my $dbiref5_revert = $dbiref5_obsolete->obsolete($metadbdata, 'revert obsolete test', 'REVERT');
    my $obsolete3 = $dbiref5_revert->is_obsolete();
    is($obsolete3, 0,"OBSOLETE FUNCTION TEST") or diag "Looks like this failed";

    ## Checking the metadata associated to this obsolete change (TEST 38 to 47)
    my $metadbdata6 = $dbiref5_revert->get_metadbdata();
    my %metadbdata6 = $metadbdata6->get_metadata_by_rows();
    my %expected_metadata6 = ( metadata_id          => $last_metadata_id+4, 
			       create_date          => $creation_date, 
			       create_person_id     => $creation_user_id,
			       modified_date        => $creation_date,
			       modified_person_id   => $creation_user_id,
			       modification_note    => 'revert obsolete',
			       previous_metadata_id => $last_metadata_id+3,
			       obsolete             => 0,
			       obsolete_note        => 'revert obsolete test'
	                    );
    foreach my $metadata_type6 (keys %metadbdata6) {
	my $message6 = "STORE FUNCTION METADBDATA INTERACTION FOR REVERT OBSOLETE, get_metadbdata test, checking $metadata_type6";
	is($metadbdata6{$metadata_type6}, $expected_metadata6{$metadata_type6}, $message6) or diag "Looks like this failed";
    }

    ## Testing new_by_accession constructor (TEST 48).
    ## It will use the first dbiref object stored with accession=$dbipath_id and path = ['metadata', 'md_dbipath', dbipath_id]
    ## It should return an object with dbiref_id= $last_dbiref_id+1
    
    my $dbiref6 = CXGN::Metadata::Dbiref->new_by_accession( $schema, 
							    $dbiref2_stored->get_accession(), 
							    ['metadata', 'md_dbiref', 'dbiref_id'] ); ## It was modificated

    is($dbiref6->get_dbiref_id(), $last_dbiref_id+1, "NEW_BY_ACCESSION constructor, checking dbiref_id") 
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

## These tests do not reset the db sequences anymore

####
1; #
####
