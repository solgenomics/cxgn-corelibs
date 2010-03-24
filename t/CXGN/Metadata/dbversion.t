#!/usr/bin/perl

=head1 NAME

  dbversion.t
  A piece of code to test the CXGN::Metadata::Dbversion module

=cut

=head1 SYNOPSIS

 perl Dbversion.t

 Note: To run the complete test the database connection should be done as 
       postgres user 
 (web_usr have not privileges to insert new data into the sed tables)  

 prove Dbversion.t

 this test need some environment variables:
    export GEMTEST_METALOADER= 'metaloader user'
    export GEMTEST_DBUSER= 'database user with insert permissions'
    export GEMTEST_DBPASS= 'database password'

 also is recommendable set the reset dbseq after run the script
    export RESET_DBSEQ=1

 if it is not set, after one run all the test that depends of a primary id
 (as metadata_id) will fail because it is calculated based in the last
 primary id and not in the current sequence for this primary id


=head1 DESCRIPTION

 This script check XX variables to test the right operation of the 
 CXGN::Metadata::DBipath module:

 + Test from 1 to 3 - use modules.
 + Test from 4 to 6 - BASIC SET/GET FUNCTIONS.
 + Test from 7 to 14 - STORE FUNCTION.
 + Test from 15 to 18 - OBSOLETE FUNCTION.
 + Test 19 and 20 - GET PATCH NUMBER METHOD.
 + Test 21 and 22 - EXISTS DBPATCH METHOD.
 + Test from 23 to 29 - CHECKING PREVIOUS DBPATCHES METHOD.

=cut

=head1 AUTHORS

 Aureliano Bombarely Gomez
 (ab782@cornell.edu)

=cut


use strict;
use warnings;

use Data::Dumper;
use Test::More  tests => 33; #qw | no_plan |; # while developing the tests
use Test::Exception;

use CXGN::DB::Connection;
use CXGN::DB::DBICFactory;

BEGIN {
    use_ok('CXGN::Metadata::Schema');               ## TEST1
    use_ok('CXGN::Metadata::Dbversion');            ## TEST2
    use_ok('CXGN::Metadata::Metadbdata');           ## TEST3
}

## Check the environment variables
my @env_variables = ('GEMTEST_METALOADER', 'GEMTEST_DBUSER', 'GEMTEST_DBPASS', 'RESET_DBSEQ');
foreach my $env (@env_variables) {
    unless ($ENV{$env} =~ m/^\w+/) {
	print STDERR "ENVIRONMENT VARIABLE WARNING: Environment variable $env was not set for this test. Use perldoc for more info.\n";
    }
}

#if we cannot load the CXGN::Metadata::Schema module, no point in continuing
CXGN::Metadata::Schema->can('connect')
    or BAIL_OUT('could not load the CXGN::Metadata::Schema module');

## Prespecified variable

my $metadata_creation_user = $ENV{GEMTEST_METALOADER};

## The triggers need to set the search path to tsearch2 in the version of psql 8.1
my $psqlv = `psql --version`;
chomp($psqlv);

my @schema_list = ('metadata', 'public');
if ($psqlv =~ /8\.1/) {
    push @schema_list, 'tsearch2';
}

my $schema = CXGN::DB::DBICFactory->open_schema( 'CXGN::Metadata::Schema', 
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
my $last_dbversion_id = $last_ids{'metadata.md_dbversion_dbversion_id_seq'};

## Create a empty metadata object to use in the database store functions
my $metadbdata = CXGN::Metadata::Metadbdata->new($schema, $metadata_creation_user);
my $creation_date = $metadbdata->get_object_creation_date();
my $creation_user_id = $metadbdata->get_object_creation_user_by_id();

## FIRST TEST BLOCK (TEST FROM 4 TO 6)
## This is the first group of tests, to check if an empty object can store and after can return the data
## Create a new empty object; 

my $dbversion = CXGN::Metadata::Dbversion->new($schema, undef); 

## Load of the eight different parameters for an empty object using a hash with keys=root name for tha function and
 ## values=value to test

my %test_values_for_empty_object=( dbversion_id       => $last_dbversion_id+1,
				   patch_name         => '9999_patch_test',
				   patch_description  => 'this is a test for description',
                                  );

## Load the data in the empty object
my @function_keys = sort keys %test_values_for_empty_object;
foreach my $rootfunction (@function_keys) {
    my $setfunction = 'set_' . $rootfunction;
    if ($rootfunction eq 'dbversion_id') {
	$setfunction = 'force_set_' . $rootfunction;
    } 
    $dbversion->$setfunction($test_values_for_empty_object{$rootfunction});
}
## Get the data from the object and store in two hashes. The first %getdata with keys=root_function_name and 
 ## value=value_get_from_object and the second, %testname with keys=root_function_name and values=name for the test.

my (%getdata, %testnames);
foreach my $rootfunction (@function_keys) {
    my $getfunction = 'get_'.$rootfunction;
    my $data = $dbversion->$getfunction();
    $getdata{$rootfunction} = $data;
    my $testname = 'BASIC SET/GET FUNCTION for ' . $rootfunction.' test';
    $testnames{$rootfunction} = $testname;
}

## And now run the test for each function and value

foreach my $rootfunction (@function_keys) {
    is($getdata{$rootfunction}, $test_values_for_empty_object{$rootfunction}, $testnames{$rootfunction}) 
	or diag "Looks like this failed.";
}

### SECOND TEST BLOCK
### Use of store functions.

eval {

    ### It will create a new object based in dbipath and it will store (TEST 7 to 9)
    my $dbversion2 = CXGN::Metadata::Dbversion->new($schema);
    $dbversion2->set_patch_name('9998_patch_test');
    $dbversion2->set_patch_description('This is a description test');
    $dbversion2->store($metadbdata);

    is($dbversion2->get_dbversion_id(), $last_dbversion_id+1, 'STORE FUNCTION test, checking dbversion_id') 
	or diag "Looks like this failed";
    is($dbversion2->get_patch_name(), '9998_patch_test', 'STORE FUNCTION test, checking patch_name') 
	or diag "Looks like this failed";
    is($dbversion2->get_patch_description(), 'This is a description test', 'STORE FUNCTION test, checking patch_description') 
	or diag "Looks like this failed";

    ## Get the metadbdata and test obsolete (TEST 10 and 11)

    my $dbv_md = $dbversion2->get_metadbdata();
    is($dbv_md->get_metadata_id(), $last_metadata_id+1, 'STORE FUNCTION (as insert) and GET METADATA test, checking metadata_id')
	or diag "Looks like this failed";

    is($dbversion2->is_obsolete(), 0, 'IS OBSOLETE FUNCTION test, checking boolean false')
	or diag "Looks like this failed";

    ## Testing new object based in path_name (TEST 12)
    my $dbversion3 = CXGN::Metadata::Dbversion->new($schema);
    $dbversion3->set_patch_name('9999_patch_test');
    $dbversion3->set_patch_description('This is a description test');
    $dbversion3->store($metadbdata);

    my $dbversion4 = CXGN::Metadata::Dbversion->new_by_patch_name($schema, '9999_patch_test');
    is($dbversion4->get_dbversion_id(), $last_dbversion_id+2, 'CONTRUCTOR new_by_patch_name TEST, checking dbversion_id')
	or diag "Looks like this failed";
    
    ## Testing modification and storing (TEST 13 and 14)
    $dbversion4->set_patch_description('This is another description test');
    $dbversion4->store($metadbdata);

    my $dbversion5 = CXGN::Metadata::Dbversion->new($schema, $dbversion4->get_dbversion_id() );
    is($dbversion5->get_patch_description(), 'This is another description test', 'STORE FUNCTION (as update) test, checking patch_descr')
	or diag "Looks like this failed";

    my $dbv_md2 = $dbversion4->get_metadbdata();
    is($dbv_md2->get_metadata_id(), $last_metadata_id+2, 'STORE FUNCTION (as update) and GET METADATA test, checking metadata_id')
	or diag "Looks like this failed";
    
    ## Testing obsolete and revert obsolete something (TEST 15 to 18)
    $dbversion5->obsolete($metadbdata, 'Obsolete test');
    is($dbversion5->is_obsolete(), 1, 'OBSOLETE FUNCTION test, checking boolean with is_obsolete() method')
	or diag "Looks like this failed";

    is($dbversion5->get_metadbdata()->get_metadata_id(), $last_metadata_id+3, 'OBSOLETE FUNTION test, checking new metadata_id')
	or diag "Looks like this failed";

    $dbversion5->obsolete($metadbdata, 'Obsolete test', 'REVERT');
    is($dbversion5->is_obsolete(), 0, 'REVERT OBSOLETE FUNCTION test, checking boolean with is_obsolete() method')
	or diag "Looks like this failed";

    is($dbversion5->get_metadbdata()->get_metadata_id(), $last_metadata_id+4, 'REVERT OBSOLETE FUNTION test, checking new metadata_id')
	or diag "Looks like this failed";

    ## Cheking a get_patch_number (TEST 19 and 20)
    my $patch_number = $dbversion5->get_patch_number();
    is ($patch_number, 9999, 'GET PATCH NUMBER METHOD, checking patch number') 
	or diag "Looks like this failed";

    ## It will test too with a patch name with zeros
    my $dbversion6 = CXGN::Metadata::Dbversion->new($schema);
    $dbversion6->set_patch_name('00023_patch_test');
    is($dbversion6->get_patch_number(), 23, 'GET PATCH NUMBER METHOD, cheking patch number with zeros')
	or diag "Looks like this failed";

    ## Using exists dbpatches (TEST 21 and 22)

    is($dbversion6->exists_dbpatch('9999_patch_test'), 1, 'EXISTS DBPATCH METHOD, checking boolean for a true value')
	or diag "Looks like this failed";
    is($dbversion6->exists_dbpatch('0023_patch_test'), 0, 'EXISTS DBPATCH METHOD, cheking boolean for a false value')
	or diag "Looks like this failed";

    ## Using checking previous dbpatches. It will check this function in three different ways:
    
     ## 1-With a specific value, 9999_patch_test. It should return 9998 keys into the hash, perhaps more if exists
     ## patch names with the same patch number, for example if during this test exists an original 9998_something
     
     ## (TEST 23 to 26)

    my %check_previous1 = $dbversion6->check_previous_dbpatches('9999_patch_test');
    my $key_n1 = scalar(keys %check_previous1); 

    ## It can have more than one patch with the same number, to fix that.

    my %rep;
    my $same_c = 0;
    foreach my $p (keys %check_previous1) {
	if ($p =~ m/^(\d+)/) {
	    my $number = $1;
	
	    if (exists $rep{$number}) {
		$same_c++;
	    }
	    else {
		$rep{$number} = 1;
	    }
	}
    }

    my $expected_key_n = 9998;
    if ($last_dbversion_id > 9998) {
   	$expected_key_n = 9999;
    }
    $expected_key_n += $same_c;

    is($key_n1, $expected_key_n, 'CHECKING PREVIOUS DBPATCHES METHOD, checking number of previous patch numbers (for 9999_patch_test)')
	or diag "Looks like this failed";
    
    is($check_previous1{'9998_patch_test'}, 1, 'CHECKING PREVIOUS DBPATCHES METHOD, checking boolean for a known patch name (9998)')
	or diag "Looks like this failed";

    is($check_previous1{'0000_patch_test'}, undef, 'CHECKING PREVIOUS DBPATCHES METHOD, checking boolean for a unknown patch name (0000)')
	or diag "Looks like this failed";

    if ($last_dbversion_id < 9997) {

	## 9997 should be a unknown number only if last_dbversion_id < 9997
	is($check_previous1{'9997'}, 0, 'CHEKING PREVIOUS DBPATCHES METHOD, checking boolean for a unknown patch number (9997)')
	    or diag "Looks like this failed";

    }
    else {

	## It still should do the same number of test.. so
	is($check_previous1{'9997'}, undef, 'CHEKING PREVIOUS DBPATCHES METHOD, checking boolean for a unknown patch name (9997)')
	    or diag "Looks like this failed";
    }

     ## 2- Without any specific value, in this case should take the $patch_name for $dbversion6. 
     ## We don't know how many of the db_patches exists from 22 to 1 but we know that there are 22 patch numbers
    
     ## TEST 27

    my %check_previous2 = $dbversion6->check_previous_dbpatches();
    is(scalar( keys %check_previous2), 22, 'CHECKING PREVIOUS DBPATCHES METHOD, checking previous patch n for patch 0023_patch_test')
	or diag "Looks like this failed";
    

    ## 3- In an object without any patch_name, it should take the last_dbversion_id (9999_test_patch for this case)

    ## TEST 28 and 29

    my $empty_dbversion = CXGN::Metadata::Dbversion->new($schema);
    my %check_previous3 = $empty_dbversion->check_previous_dbpatches();

    is($key_n1, $expected_key_n, 'CHECKING PREVIOUS DBPATCHES METHOD, checking number of previous patch numbers in EMPTY OBJ')
	or diag "Looks like this failed";
    
    is($check_previous1{'9998_patch_test'}, 1, 'CHECKING PREVIOUS DBPATCHES METHOD, checking boolean for a known patch name in EMPTY OBJ')
	or diag "Looks like this failed";

    ## Testing the complete checking

    my $dbversion7 = CXGN::Metadata::Dbversion->new($schema);
    
    ## Check that this patch has been executed before (test 30)

    throws_ok { $dbversion7->complete_checking({ patch_name => '9998_patch_test'}) } qr/DBPATCH EXECUTION ERROR/,	   
                "TESTING DIE for complete_checking when use patch_name";

    ## Check that other previous patches by default (using patch number) has not been runned (TEST 31)
    
    throws_ok { $dbversion7->complete_checking({ patch_name => '9999_other_test'}) } qr/PREVIOUS DB_PATCH by default ERROR/, 
	        "TESTING DIE for complete_checking when previous patches that don't exists";
      
    ## Check a list of previous patches using a list (TEST 32)
    
    throws_ok { $dbversion7->complete_checking({ patch_name => '9999_other_test', prepatch => ['9998_alt_test'] }) } 
                qr/PREVIOUS DB_PATCH ERROR/, 
	        "TESTING DIE for complete_checking when use patch_name";

    ## Test when pass the complete_cheking (TEST 33)

    lives_ok { $dbversion7->complete_checking({ patch_name => '9999_other_test', prepatch => ['9998_patch_test'] }) }
               "TESTING DON'T DIE for complete_checking when pass the check";


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
