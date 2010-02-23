#!/usr/bin/perl

=head1 NAME

  dbipath.t
  A piece of code to test the CXGN::Metadata::Dbipath module

=cut

=head1 SYNOPSIS

 perl Dbipath.t

 Note: To run the complete test the database connection should be done as 
       postgres user 
 (web_usr have not privileges to insert new data into the sed tables)  

 prove Dbipath.t

=head1 DESCRIPTION

 This script check XX variables to test the right operation of the 
 CXGN::Metadata::DBipath module:

 + test 1 and 3: Test for module use
 + test from 4 to 8: Test to set data into the object without any storage
 + test 9: Creation ob dbipath object using dbipath (schema, table, column)
 + test 10 and 11: Test store function
 + test 12 and 21: Test get_metadbdata function and all the metadbdata 
                   associated to a new row
 + test 22: Test is_obsolete function
 + test 23 and 24: Test store function for a modification in the row
 + test 25 to 34: Test get_metadbdata function and all the metadbdata 
                  associated to a modification
 + test 35: Obsolete function test
 + test 36 to 45: Test get_metadbdata function and all the metadbdata 
                  associated to obsolete
 + test 46: Obsolete function test with revert tag
 + test 57 to 56: Test get_metadbdata function and all the metadbdata 
                  associated to obsolete with revert tag

=cut

=head1 AUTHORS

 Aureliano Bombarely Gomez
 (ab782@cornell.edu)

=cut


use strict;
use warnings;

use Data::Dumper;
use Test::More tests=>56;  # use  qw | no_plan | while developing the tests

use CXGN::DB::Connection;
use CXGN::DB::DBICFactory;

BEGIN {
    use_ok('CXGN::Metadata::Schema');               ## TEST1
    use_ok('CXGN::Metadata::Dbipath');              ## TEST2
    use_ok('CXGN::Metadata::Metadbdata');           ## TEST3
}

#if we cannot load the CXGN::Metadata::Schema module, no point in continuing
CXGN::Metadata::Schema->can('connect')
    or BAIL_OUT('could not load the CXGN::Metadata::Schema module');


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
my $last_dbipath_id = $last_ids{'metadata.md_dbipath_dbipath_id_seq'};

## Create a empty metadata object to use in the database store functions
my $metadbdata = CXGN::Metadata::Metadbdata->new($schema, 'aure');
my $creation_date = $metadbdata->get_object_creation_date();
my $creation_user_id = $metadbdata->get_object_creation_user_by_id();

## FIRST TEST BLOCK (TEST FROM 4 TO 7)
## This is the first group of tests, to check if an empty object can store and after can return the data
## Create a new empty object; 

my $dbipath = CXGN::Metadata::Dbipath->new($schema, undef); 

## Load of the eight different parameters for an empty object using a hash with keys=root name for tha function and
 ## values=value to test

my %test_values_for_empty_object=( dbipath_id  => $last_dbipath_id+1,
				   column_name => 'dbipath_id',
				   table_name  => 'md_dbipath',
				   schema_name => 'metadata',
                                  );

## Load the data in the empty object
my @function_keys = sort keys %test_values_for_empty_object;
foreach my $rootfunction (@function_keys) {
    my $setfunction = 'set_' . $rootfunction;
    if ($rootfunction eq 'dbipath_id') {
	$setfunction = 'force_set_' . $rootfunction;
    } 
    $dbipath->$setfunction($test_values_for_empty_object{$rootfunction});
}
## Get the data from the object and store in two hashes. The first %getdata with keys=root_function_name and 
 ## value=value_get_from_object and the second, %testname with keys=root_function_name and values=name for the test.

my (%getdata, %testnames);
foreach my $rootfunction (@function_keys) {
    my $getfunction = 'get_'.$rootfunction;
    my $data = $dbipath->$getfunction();
    $getdata{$rootfunction} = $data;
    my $testname = 'BASIC SET/GET FUNCTION for ' . $rootfunction.' test';
    $testnames{$rootfunction} = $testname;
}

## And now run the test for each function and value

foreach my $rootfunction (@function_keys) {
    is($getdata{$rootfunction}, $test_values_for_empty_object{$rootfunction}, $testnames{$rootfunction}) 
	or diag "Looks like this failed.";
}

## Additional function set/get dbipath (TEST 8)
$dbipath->set_dbipath('metadata', 'md_metadata', 'metadata_id');
my @bt_dbipath_elements = $dbipath->get_dbipath();
my $bt_dbipath_elements = join('.', @bt_dbipath_elements);
is ($bt_dbipath_elements, 'metadata.md_metadata.metadata_id', 'COMPLEX SET/GET FUNCTION for dbipath test') 
    or diag "Looks like this failed";


### SECOND TEST BLOCK
### Use of store functions.

eval {

    ### It will create a new object based in dbipath (TEST 9)
    my $dbipath2 = CXGN::Metadata::Dbipath->new_by_path($schema, ['metadata', 'md_dbipath', 'dbipath_id']);
    my @bt_dbipath_elements2 = $dbipath2->get_dbipath();
    my $bt_dbipath_elements2 = join('.', @bt_dbipath_elements2);
    is ($bt_dbipath_elements2, 'metadata.md_dbipath.dbipath_id', 'CONSTRUCTOR FUNCTION new_by_path test') 
	or diag "Looks like this failed";

    ### It will store it (TEST 10 to 11)
    my $dbipath2_stored = $dbipath2->store($metadbdata);
    my $dbipath2_id = $dbipath2_stored->get_dbipath_id();
    is($dbipath2_id, $last_dbipath_id+1, 'STORE FUNCTION with a new dbipath row, checking dbipath_id')
	or diag "Looks like this failed";
    my @st_dbipath_elements = $dbipath2_stored->get_dbipath();
    my $st_dbipath_elements = join('.', @st_dbipath_elements);
    is($st_dbipath_elements, 'metadata.md_dbipath.dbipath_id', 'STORE FUNCTION with a new dbipath row, checking dbipath elements')
	or diag "Looks like this failed";

    ## Checking the metadbdata associated to this new creation (TEST 12 to 21)
    my $st_metadbdata = $dbipath2_stored->get_metadbdata();
    my %metadbdata = $st_metadbdata->get_metadata_by_rows();
    my %expected_metadata = ( metadata_id      => $last_metadata_id+1, 
			      create_date      => $creation_date, 
			      create_person_id => $creation_user_id, 
			      obsolete         => 0 
	                    );
    foreach my $st_metadata_type (keys %metadbdata) {
	my $message = "STORE FUNCTION METADBDATA INTERACTION, get_metadbdata test, checking $st_metadata_type";
	is($metadbdata{$st_metadata_type}, $expected_metadata{$st_metadata_type}, $message) or diag "Looks like this failed";
    }
    ## Checking the is_obsolete function (TEST 22)
    my $obsolete = $dbipath2_stored->is_obsolete();
    is($obsolete, 0,"IS OBSOLETE FUNCTION TEST") or diag "Looks like this failed";

    ## Testing a modification in the row data (TEST 23 and 24)
    $dbipath2_stored->set_column_name('column_name');
    my $dbipath2_modified = $dbipath2_stored->store($metadbdata);
    my $dbipath2_id2 = $dbipath2_modified->get_dbipath_id();
    is($dbipath2_id2, $last_dbipath_id+1, 'STORE FUNCTION with a modified dbipath row, checking dbipath_id')
	or diag "Looks like this failed";
    my @st_dbipath_elements2 = $dbipath2_modified->get_dbipath();
    my $st_dbipath_elements2 = join('.', @st_dbipath_elements2);
    is($st_dbipath_elements2, 'metadata.md_dbipath.column_name', 'STORE FUNCTION with a modified dbipath row, checking dbipath elements')
	or diag "Looks like this failed";
    
    ## Checking the metadbdata associated to this modification (TEST 25 to 34)
    my $st_metadbdata2 = $dbipath2_modified->get_metadbdata();
    my %metadbdata2 = $st_metadbdata2->get_metadata_by_rows();
    my %expected_metadata2 = ( metadata_id          => $last_metadata_id+2, 
			       create_date          => $creation_date, 
			       create_person_id     => $creation_user_id,
			       modified_date        => $creation_date,
			       modified_person_id   => $creation_user_id,
			       modification_note    => 'set value in column_name column',
			       previous_metadata_id => $last_metadata_id+1,
			       obsolete             => 0 
	                    );
    foreach my $st_metadata_type2 (keys %metadbdata2) {
	my $message2 = "STORE FUNCTION METADBDATA INTERACTION FOR MODIFICATIONS, get_metadbdata test, checking $st_metadata_type2";
	is($metadbdata2{$st_metadata_type2}, $expected_metadata2{$st_metadata_type2}, $message2) or diag "Looks like this failed";
    }

    ## Test the obsolete function (TEST 35)
    my $dbipath2_obsolete = $dbipath2_modified->obsolete($metadbdata, 'change to obsolete test');
    my $obsolete2 = $dbipath2_stored->is_obsolete();
    is($obsolete2, 1,"OBSOLETE FUNCTION TEST") or diag "Looks like this failed";

    ## Checking the metadata associated to this obsolete change (TEST 36 to 45)
    my $st_metadbdata3 = $dbipath2_obsolete->get_metadbdata();
    my %metadbdata3 = $st_metadbdata3->get_metadata_by_rows();
    my %expected_metadata3 = ( metadata_id          => $last_metadata_id+3, 
			       create_date          => $creation_date, 
			       create_person_id     => $creation_user_id,
			       modified_date        => $creation_date,
			       modified_person_id   => $creation_user_id,
			       modification_note    => 'change to obsolete',
			       previous_metadata_id => $last_metadata_id+2,
			       obsolete             => 1,
			       obsolete_note        => 'change to obsolete test'
	                    );
    foreach my $st_metadata_type3 (keys %metadbdata3) {
	my $message3 = "STORE FUNCTION METADBDATA INTERACTION FOR OBSOLETE, get_metadbdata test, checking $st_metadata_type3";
	is($metadbdata3{$st_metadata_type3}, $expected_metadata3{$st_metadata_type3}, $message3) or diag "Looks like this failed";
    }

    ## Test the REVERT tag for the obsolete function (TEST 46)
    my $dbipath2_revert = $dbipath2_obsolete->obsolete($metadbdata, 'revert obsolete test', 'REVERT');
    my $obsolete3 = $dbipath2_revert->is_obsolete();
    is($obsolete3, 0,"OBSOLETE FUNCTION TEST") or diag "Looks like this failed";

    ## Checking the metadata associated to this obsolete change (TEST 47 to 56)
    my $st_metadbdata4 = $dbipath2_revert->get_metadbdata();
    my %metadbdata4 = $st_metadbdata4->get_metadata_by_rows();
    my %expected_metadata4 = ( metadata_id          => $last_metadata_id+4, 
			       create_date          => $creation_date, 
			       create_person_id     => $creation_user_id,
			       modified_date        => $creation_date,
			       modified_person_id   => $creation_user_id,
			       modification_note    => 'revert obsolete',
			       previous_metadata_id => $last_metadata_id+3,
			       obsolete             => 0,
			       obsolete_note        => 'revert obsolete test'
	                    );
    foreach my $st_metadata_type4 (keys %metadbdata4) {
	my $message4 = "STORE FUNCTION METADBDATA INTERACTION FOR REVERT OBSOLETE, get_metadbdata test, checking $st_metadata_type4";
	is($metadbdata4{$st_metadata_type4}, $expected_metadata4{$st_metadata_type4}, $message4) or diag "Looks like this failed";
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
