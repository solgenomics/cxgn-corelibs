#!/usr/bin/perl

=head1 NAME

  metadbdata.t
  A piece of code to test the CXGN::Metadata::Metadbdata module

=cut

=head1 SYNOPSIS

 perl metadata.t

 Note: To run the complete test the database connection should be done as postgres user 
 (web_usr have not privileges to insert new data into the sed tables)  

=head1 DESCRIPTION

 This script check 57 variables to test the right operation of the CXGN::Metadata::Metadbdata module:

 + test 1 and 2: Test for module use
 + test from 3 to 11: Test the accessors (set and get) in an empty object. 
 + test 12: Test the create_person_id_by_username function that set the create_person_id value using a username.
 + test 13: Test the store function without previous metadata_id (a new metadata for a new Sgn Expression Data).   
 + test 14: Test the store function with a previous metadata_id (modify Sgn Expression Data, so it create a new metadata
             with a old metadata_id as previous metadata, in this case to obsolete a SED value)
 + test 15: get obsolete data from a metadata object.
 + test from 16 to 42: check the data obtained from the trace_history function
 + test 43 and 45: check the find_or_store function
 + test 46: check the exists_database_columns function
 + test from 47 to 48: check the exists_metadata for different metadata_types
 + test from 49 to 52: check the enforce functions (enforce_insert and enforce_update).

=cut

=head1 AUTHORS

 Aureliano Bombarely Gomez
 (ab782@cornell.edu)

=cut


use strict;
use warnings;

use Data::Dumper;
use Test::More tests=>53;  # use  qw | no_plan | while developing the tests

use CXGN::DB::Connection;
use CXGN::DB::DBICFactory;

BEGIN {
    use_ok('CXGN::Metadata::Schema');                  ## Test1
    use_ok('CXGN::Metadata::Metadbdata');              ## Test2
}

#if we cannot load the CXGN::Metadata::Schema module, no point in continuing
CXGN::Metadata::Schema->can('connect')
    or BAIL_OUT('could not load the CXGN::Metadata::Schema module');


## The triggers need to set the search path to tsearch2 in the version of psql 8.1
my $psqlv = `psql --version`;
chomp($psqlv);

my @schema_list = ('biosource', 'metadata', 'public');
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



## It will create some predefined times to use by the script

my $dbh = $schema->storage()
                 ->dbh();

my ($past) = $dbh->selectrow_array("SELECT now() + '-10 year'");
my ($present) = $dbh->selectrow_array("SELECT now()");
my ($future) = $dbh->selectrow_array("SELECT now() + '10 year'");
my ($far_future) = $dbh->selectrow_array("SELECT now() + '1000 year'");


## FIRST TEST BLOCK (Test from 3 to 11)
## This is the first group of tests, to check if an empty object can store and after can return the data
## Create a new empty object; 

my $metadata = CXGN::Metadata::Metadbdata->new($schema, undef); 

## Load of the eight different parameters for an empty object using a hash with keys=root name for tha function and
 ## values=value to test

my %test_values_for_empty_object=( metadata_id => 1, 
				   create_date => 'now', 
				   create_person_id => 1,
				   modified_date => 'now', 
				   modification_note => 'test for modification note', 
				   previous_metadata_id => 0, 
				   obsolete => 1,
				   obsolete_note => 'It is obsolete because it is a test',
				   permission_id => 1
                                  );

## Load the data in the empty object
my @function_keys = sort keys %test_values_for_empty_object;
foreach my $rootfunction (@function_keys) {
    my $setfunction = 'set_'.$rootfunction;
    $metadata->$setfunction($test_values_for_empty_object{$rootfunction});
}
## Get the data from the object and store in two hashes. The first %getdata with keys=root_function_name and 
 ## value=value_get_from_object and the second, %testname with keys=root_function_name and values=name for the test.

my (%getdata, %testnames);
foreach my $rootfunction (@function_keys) {
    my $getfunction = 'get_'.$rootfunction;
    my $data = $metadata->$getfunction();
    $getdata{$rootfunction} = $data;
    my $testname = $rootfunction.' test';
    $testnames{$rootfunction} = $testname;
}

## And now run the test for each function and value

foreach my $rootfunction (@function_keys) {
    is($getdata{$rootfunction}, $test_values_for_empty_object{$rootfunction}, $testnames{$rootfunction}) 
	or diag "Looks like this failed.";
}

 ## SECOND TEST BLOCK
## This block test the store function in two ways, as store a new metadata and modifing a data (it create a new one too). 
 ## It was runned as eval { }, because in the end of the test we need restore the database data (and if die... )
  ##  now we are going to store, but before could be a good idea get the last_id to set the seq after all the process.

my $all_last_ids_href = $schema->get_all_last_ids($schema);
my %last_ids = %{$all_last_ids_href};

my $last_metadata_id = $last_ids{'metadata.md_metadata_metadata_id_seq'};

eval {

 ## Create a new empty object with object_creation_user argument

   my $metadata_s = CXGN::Metadata::Metadbdata->new($schema, 'Aubombarely');

 ## Other option is use $metadata_s->set_create_person_id_by_username('Aubombarely');
 ## The module check if exists the sp_person_id in the sgn_people.sp_person table      
 ## Use the same to test the get_create_person_id_by_username
 ## Tests from 12 to 14

   is ($metadata_s->get_create_person_id_by_username(), undef, 'undefined create_person_id_by_username before store test')
       or diag "Looks like this failed.";
   my $stored_metadata = $metadata_s->store(); ## During the store the create_person_id should be set with the value by default
   is ($stored_metadata->get_create_person_id_by_username(), 'Aubombarely', 'create_person_id_by_username test')
       or diag "Looks like this failed.";
   my $store_metadata_id = $stored_metadata->get_metadata_id();
   my $expected_metadata_id = $last_metadata_id+1;
   is ($store_metadata_id, $expected_metadata_id, 'store an object without metadata_id test')
       or diag "Looks like this failed.";

 ## Now we are going to modify a metadata. First, we are going to obsolete the data.

   $stored_metadata->set_modified_date($future);

 ## We do not set the modification_person_by_username to see if it get the object_creation_user by default.
 ## An alternative is use $stored_metadata->set_modified_person_id_by_username('Aubombarely');
 ## Test 15 and 16

   $stored_metadata->set_modification_note('set_data');
   my $new_stored_metadata = $stored_metadata->store();   ## Now it should create a new metadata id
   my $new_expected_metadata_id = $last_metadata_id+2;
   my $new_store_metadata_id = $new_stored_metadata->get_metadata_id();
   is ($new_store_metadata_id, $new_expected_metadata_id, 'store an object with metadata_id test ')
       or diag "Looks like this failed.";
   is ($stored_metadata->get_obsolete(), 0, 'get obsolete from a store an object with metadata_id test')
       or diag "Look like this failed";
  
 ## We are going to mdify another time the data ans store it to see if the store function works propierly for more than one element
  ## We take the new_stored_metadata, and do the changes over this metadata (The last got from the db).
 ## Test 17 and 18

   $new_stored_metadata->set_metadata_by_rows({ modified_date => $far_future, modification_note => 'set_other_data'});
   my $newest_stored_metadata = $new_stored_metadata->store();
   my $newest_expected_metadata_id = $last_metadata_id+3;
   my $newest_stored_metadata_id = $newest_stored_metadata->get_metadata_id();
   my $newest_stored_modified_date = $newest_stored_metadata->get_modified_date();
   my $newest_stored_modification_note = $newest_stored_metadata->get_modification_note();
   my $modification_data_combined = $newest_stored_modified_date." AND ".$newest_stored_modification_note;
   is ($newest_stored_metadata_id, $newest_expected_metadata_id, 'store function over the object obtained from store function')
       or diag "Looks like this failed.";
   is ($modification_data_combined, "$far_future AND set_other_data", 'set_metadata_by_rows and store functions')
       or diag "Looks like this failed.";

## Finally we are going to try trace the history function (get use the last metadata_id)

   my @history_metadata = $stored_metadata->trace_history($newest_stored_metadata_id);
   
## According the data that we are insert this should have two entries:
## Test 19

   my $history_entries_number = scalar(@history_metadata);
   is ($history_entries_number, 3, 'trace_history number of entries test')
       or diag "Look like this failed";

   my $third_metadata_obj = $history_metadata[0];
   my $second_metadata_obj = $history_metadata[1];
   my $first_metadata_obj = $history_metadata[2];
   my %third_metadata_by_col = $third_metadata_obj->get_metadata_by_rows();
   my %second_metadata_by_col = $second_metadata_obj->get_metadata_by_rows();
   my %first_metadata_by_col = $first_metadata_obj->get_metadata_by_rows();
   
## Define the values expected for the three elements of the trace processing from first (oldest) to third (newest).

   my $general_create_date = $first_metadata_obj->get_object_creation_date();
   my $general_create_person_id = $first_metadata_obj->get_create_person_id();
   
   my $query_for_person_id = "SELECT sp_person_id FROM sgn_people.sp_person WHERE username=?";
   my $sth_p=$schema->storage->dbh->prepare($query_for_person_id);
   $sth_p->execute('Aubombarely');
   my ($sp_person_id_for_Aubombarely) = $sth_p->fetchrow_array();

   my %third_expected_metadata = (  metadata_id => $last_metadata_id+3,
				    create_date => $general_create_date,
				    create_person_id => $general_create_person_id,
				    modified_date => $far_future,
				    modified_person_id => $sp_person_id_for_Aubombarely, 
				    modification_note => 'set_other_data',
				    obsolete => 0,
				    obsolete_note => 'undefined',
				   );
   my $second_expected_obsolete_note = "New metadata was added (with metadata_id = ";
   $second_expected_obsolete_note .= $last_metadata_id+3;
   $second_expected_obsolete_note .= ")";
   my %second_expected_metadata = ( metadata_id => $last_metadata_id+2,
				    create_date => $general_create_date,
				    create_person_id => $general_create_person_id,
				    modified_date => $future,
				    modified_person_id => $sp_person_id_for_Aubombarely, 
				    modification_note => 'set_data',
				    obsolete => 0,
				    obsolete_note => 'undefined',
				   );
   my $first_expected_obsolete_note = "New metadata was added (with metadata_id = ";
   $first_expected_obsolete_note .= $last_metadata_id+2;
   $first_expected_obsolete_note .= ")";
   my %first_expected_metadata = (  metadata_id => $last_metadata_id+1,
				    create_date => $general_create_date,
				    create_person_id => $general_create_person_id,
				    modified_date => 'undefined',
				    modified_person_id => 'undefined', 
				    modification_note => 'undefined',
				    obsolete => 0,
				    obsolete_note => 'undefined',
				   );  

 ## Now test for each element the each values for each column
 ## Test from 20 to 43

   my @columns = keys %first_expected_metadata;
   foreach my $col (@columns) {
       my ($first_metadata_obtained, $second_metadata_obtained, $third_metadata_obtained);
       if (defined $first_metadata_by_col{$col}) {
	   $first_metadata_obtained = $first_metadata_by_col{$col};
       } else {
	   $first_metadata_obtained = 'undefined';
       }
       my $first_metadata_expected = $first_expected_metadata{$col};
       my $first_message = 'trace_history and get_metadata_by_rows tests for '.$col.' for the first element';
       is ($first_metadata_obtained, $first_metadata_expected, $first_message) or diag "Looks like this failed.";
       
       if (defined $second_metadata_by_col{$col}) {
	   $second_metadata_obtained = $second_metadata_by_col{$col};
       } else {
	   $second_metadata_obtained = 'undefined';
       }
       my $second_metadata_expected = $second_expected_metadata{$col};
       my $second_message = 'trace_history and get_metadata_by_rows tests for '.$col.' for the second element';
       is ($second_metadata_obtained, $second_metadata_expected, $second_message) or diag "Looks like this failed.";

       if (defined $third_metadata_by_col{$col}) {
	   $third_metadata_obtained = $third_metadata_by_col{$col};
       } else {
	   $third_metadata_obtained = 'undefined';
       }
       my $third_metadata_expected = $third_expected_metadata{$col};
       my $third_message = 'trace_history and get_metadata_by_rows tests for '.$col.' for the third element';
       is ($third_metadata_obtained, $third_metadata_expected, $third_message) or diag "Looks like this failed.";
   }

## Testing of the find_or_store_function. We are going to create two different metadata object. The first exists into the database
## so the function should return the db object with its id. To this object we are going to change one variable (modification note)
## and we are going to use the same function. Now should insert a new metadata_id.
## Test 44 and 45

   my $fos_metadata = CXGN::Metadata::Metadbdata->new($schema, 'Aubombarely');
   $fos_metadata->set_object_creation_date($general_create_date);          ## Now have the same object_create_date and object_create_user
   $fos_metadata->set_metadata_by_rows({ create_date          => $general_create_date,              ## We set the same values than the 
					 create_person_id     => $general_create_person_id,         ## third metadata object
					 modified_date        => $far_future,
					 modified_person_id   => $sp_person_id_for_Aubombarely, 
					 modification_note    => 'set_other_data',
					 previous_metadata_id => $last_metadata_id+2,
					 obsolete             => 0,
				       });
   my $new_fos_metadata = $fos_metadata->store();
   my $metadata_test_row = $new_fos_metadata->get_mdmetadata_row();
   is ($new_fos_metadata->get_metadata_id(), $last_metadata_id+3, 'test for store function with the find result') or
       diag "Looks like this failed.";
   $fos_metadata->set_modification_note('set_other_data_for_find_or_store_test');
   my $newest_fos_metadata = $fos_metadata->store();
   is ($newest_fos_metadata->get_metadata_id(), $last_metadata_id+4, 'test for store function with store result') or
       diag "Looks like this failed";

   

## Check the exists functions
 ## exists_database_columns function, if exists all the columns return a hash reference with 11 elements. All the values must be 1.
 ## Test 46

   my $check_columns_href = $metadata_s->exists_database_columns();
   my $check_columns_string = join ',', values %{$check_columns_href};
   is ($check_columns_string, '1,1,1,1,1,1,1,1,1,1,1', 'exists_database_columns test function') or diag "Looks like this failed.";

 ## exists_metadata check if exists or not a metadata_type in a metadata column. According this, we are going to test if exists 
  ## a metadata_id = last_metadata+10 (should not exists), a metadata_type = modification_note for last_metadata+1 (should not 
   ## exists also) and finally a obsolete_note for metadata_id = $last_metadata_id+2 (should exists).

   my $check_metadata_id = $metadata_s->exists_metadata($last_metadata_id+10, 'metadata_id');
   is ($check_metadata_id, 0, 'exists_metadata function for metadata_type = metadata_id test for FALSE result') 
       or diag "Looks like this failed.";
   my $check_metadata_modification_note = $metadata_s->exists_metadata($last_metadata_id+1, 'modification_note');
   is ($check_metadata_modification_note, 0, 'exists_metadata function for metadata_type = modification_note for FALSE result') 
       or diag "Looks like this failed";
   my $check_metadata_obsolete_note = $metadata_s->exists_metadata($last_metadata_id+2, 'obsolete_note');
   is ($check_metadata_obsolete_note, 0, 'exists_metadata function for metadata_type = obsolete_note for FALSE result')
       or diag "Looks like this failed";

 ## Finally we are going to test the enforce_methods

   my $f_metadata_object = CXGN::Metadata::Metadbdata->new($schema);
   $f_metadata_object->set_create_date($future);
   $f_metadata_object->set_create_person_id_by_username('Aubombarely');
   my $new_f_metadata_object = $f_metadata_object->force_insert();
   my $new_f_metadata_id = $new_f_metadata_object->get_metadata_id();
   my $new_f_metadata_id_expected = $last_metadata_id+5;
   is ($new_f_metadata_id, $new_f_metadata_id_expected, 'enforce_insert function test, metadata_id BY DEFAULT')
       or diag "Looks like this failed.";
   my $new_f_metadata_create_date = $new_f_metadata_object->get_create_date();
   is ($new_f_metadata_create_date, $future, 'enforce_insert function test, create_date FORCED') 
       or diag "Looks like this failed.";
   $new_f_metadata_object->set_create_date($past);
   my $newest_f_metadata_object = $new_f_metadata_object->force_update();
   my $newest_f_metadata_id = $newest_f_metadata_object->get_metadata_id();
   my $newest_f_metadata_create_date = $newest_f_metadata_object->get_create_date();
   is ($newest_f_metadata_id, $new_f_metadata_id_expected, 'enforce_update function test, metadata_id BY DEFAULT')
       or diag "Looks like this failed.";
   is ($newest_f_metadata_create_date, $past, 'enforce_update function test, create_date FORCED') 
       or diag "Looks like this failed.";

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


#####
1; ##
#####

