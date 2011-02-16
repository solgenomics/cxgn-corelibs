=head1 GEM TESTS

  For GEM test suite documentation, see L<CXGN::GEM::Test>.

=cut

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warn;

use CXGN::GEM::Test;

my $gem_test = CXGN::GEM::Test->new;

use_ok('CXGN::GEM::Schema');             ## TEST1
use_ok('CXGN::GEM::TechnologyType');     ## TEST2
use_ok('CXGN::GEM::Platform');           ## TEST3
use_ok('CXGN::Metadata::Metadbdata');    ## TEST4

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
my $creation_user_name = $gem_test->metaloader_user;

## The GEM schema contain all the metadata, chado and biosource classes so don't need to create another Metadata schema

my $schema = $gem_test->dbic_schema('CXGN::GEM::Schema');

$schema->txn_begin();


## Get the last values
my %nextvals = $schema->get_nextval();
my $last_metadata_id = $nextvals{'md_metadata'} || 0;
my $last_techtype_id = $nextvals{'ge_technology_type'} || 0;
my $last_platform_id = $nextvals{'ge_platform'} || 0;

## Create a empty metadata object to use in the database store functions
my $metadbdata = CXGN::Metadata::Metadbdata->new($schema, $creation_user_name);
my $creation_date = $metadbdata->get_object_creation_date();
my $creation_user_id = $metadbdata->get_object_creation_user_by_id();


#######################################
## FIRST TEST BLOCK: Basic functions ##
#######################################

## (TEST FROM 5 to 7)
## This is the first group of tests, to check if an empty object can store and after can return the data
## Create a new empty object; 

my $techtype0 = CXGN::GEM::TechnologyType->new($schema, undef); 

## Load of the eight different parameters for an empty object using a hash with keys=root name for tha function and
 ## values=value to test

my %test_values_for_empty_object=( technology_type_id    => $last_techtype_id+1,
				   technology_name       => 'technology type test',
				   description           => 'this is a test',
                                  );

## Load the data in the empty object
my @function_keys = sort keys %test_values_for_empty_object;
foreach my $rootfunction (@function_keys) {
    my $setfunction = 'set_' . $rootfunction;
    if ($rootfunction eq 'technology_type_id') {
	$setfunction = 'force_set_' . $rootfunction;
    } 
    $techtype0->$setfunction($test_values_for_empty_object{$rootfunction});
}

## Get the data from the object and store in two hashes. The first %getdata with keys=root_function_name and 
## value=value_get_from_object and the second, %testname with keys=root_function_name and values=name for the test.

my (%getdata, %testnames);
foreach my $rootfunction (@function_keys) {
    my $getfunction = 'get_'.$rootfunction;
    my $data = $techtype0->$getfunction();
    $getdata{$rootfunction} = $data;
    my $testname = 'BASIC SET/GET FUNCTION for ' . $rootfunction.' test';
    $testnames{$rootfunction} = $testname;
}

## And now run the test for each function and value

foreach my $rootfunction (@function_keys) {
    is($getdata{$rootfunction}, $test_values_for_empty_object{$rootfunction}, $testnames{$rootfunction}) 
	or diag "Looks like this failed.";
}


## Testing the die results (TEST 8 to 14)

throws_ok { CXGN::GEM::TechnologyType->new() } qr/PARAMETER ERROR: None schema/, 
    'TESTING DIE ERROR when none schema is supplied to new() function';

throws_ok { CXGN::GEM::TechnologyType->new($schema, 'no integer')} qr/DATA TYPE ERROR/, 
    'TESTING DIE ERROR when a non integer is used to create a technology type object with new() function';

throws_ok { CXGN::GEM::TechnologyType->new($schema)->set_getechnologytype_row() } qr/PARAMETER ERROR: None getechnologytype_row/, 
    'TESTING DIE ERROR when none schema is supplied to set_getechnologytype_row() function';

throws_ok { CXGN::GEM::TechnologyType->new($schema)->set_getechnologytype_row($schema) } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_getechnologytype_row() is not a CXGN::GEM::Schema::GeTechnologyType row object';

throws_ok { CXGN::GEM::TechnologyType->new($schema)->force_set_technology_type_id() } qr/PARAMETER ERROR: None technology_type/, 
    'TESTING DIE ERROR when none technology_type_id is supplied to set_force_technology_type_id() function';

throws_ok { CXGN::GEM::TechnologyType->new($schema)->force_set_technology_type_id('non integer') } qr/DATA TYPE ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_force_technology_type_id() is not an integer';

throws_ok { CXGN::GEM::TechnologyType->new($schema)->set_technology_name() } qr/PARAMETER ERROR: None data/, 
    'TESTING DIE ERROR when none data is supplied to set_technology_name() function';




##########################################################################
### SECOND TEST BLOCK: Experimental Design Store and Obsolete Functions ##
##########################################################################

### Use of store functions.

 eval {

      my $techtype1 = CXGN::GEM::TechnologyType->new($schema);
      $techtype1->set_technology_name('technology_name_test');
      $techtype1->set_description('This is a description test');

      $techtype1->store_technology_type($metadbdata);

      ## Testing the technology_type_id and technology_name for the new object stored (TEST 15 to 17)

      is($techtype1->get_technology_type_id(), $last_techtype_id+1, 
	 "TESTING STORE_TECHNOLOGY_TYPE FUNCTION, checking the technology_type_id")
 	 or diag "Looks like this failed";
      is($techtype1->get_technology_name(), 'technology_name_test', 
	 "TESTING STORE_TECHNOLOGY_TYPE FUNCTION, checking the technology_name")
 	 or diag "Looks like this failed";
      is($techtype1->get_description(), 'This is a description test', 
	 "TESTING STORE_EXPERIMENTAL_DESIGN FUNCTION, checking description")
 	 or diag "Looks like this failed";


      ## Testing the get_medatata function (TEST 18 to 20)

      my $obj_metadbdata = $techtype1->get_technology_type_metadbdata();
      is($obj_metadbdata->get_metadata_id(), $last_metadata_id+1, "TESTING GET_METADATA FUNCTION, checking the metadata_id")
  	or diag "Looks like this failed";
      is($obj_metadbdata->get_create_date(), $creation_date, "TESTING GET_METADATA FUNCTION, checking create_date")
  	or diag "Looks like this failed";
      is($obj_metadbdata->get_create_person_id_by_username, $creation_user_name, 
	 "TESING GET_METADATA FUNCTION, checking create_person by username")
  	or diag "Looks like this failed";
    
      ## Testing die for store function (TEST 21 and 22)

      throws_ok { $techtype1->store_technology_type() } qr/STORE ERROR: None metadbdata/, 
      'TESTING DIE ERROR when none metadbdata object is supplied to store_technology_type() function';

      throws_ok { $techtype1->store_technology_type($schema) } qr/STORE ERROR: Metadbdata supplied/, 
      'TESTING DIE ERROR when argument supplied to store_technology_type() is not a CXGN::Metadata::Metadbdata object';

      ## Testing if it is obsolete (TEST 23)

      is($techtype1->is_technology_type_obsolete(), 0, "TESTING IS_TECHNOLOGY_TYPE_OBSOLETE FUNCTION, checking boolean")
	  or diag "Looks like this failed";

      ## Testing obsolete (TEST 24 to 27) 

      $techtype1->obsolete_technology_type($metadbdata, 'testing obsolete');
    
      is($techtype1->is_technology_type_obsolete(), 1, 
	 "TESTING TECHNOLOGY_TYPE_OBSOLETE FUNCTION, checking boolean after obsolete the technology_type")
	  or diag "Looks like this failed";

      is($techtype1->get_technology_type_metadbdata()->get_metadata_id, $last_metadata_id+2, 
	 "TESTING TECHNOLOGY_TYPE_OBSOLETE, checking metadata_id")
	  or diag "Looks like this failed";

      $techtype1->obsolete_technology_type($metadbdata, 'testing obsolete', 'REVERT');
    
      is($techtype1->is_technology_type_obsolete(), 0, 
	 "TESTING REVERT TECHNOLOGY_TYPE_OBSOLETE FUNCTION, checking boolean after revert obsolete")
	  or diag "Looks like this failed";

      is($techtype1->get_technology_type_metadbdata()->get_metadata_id, $last_metadata_id+3, 
	 "TESTING REVERT TECHNOLOGY_TYPE_OBSOLETE, for metadata_id")
	  or diag "Looks like this failed";

      ## Testing die for obsolete function (TEST 28 to 30)

      throws_ok { $techtype1->obsolete_technology_type() } qr/OBSOLETE ERROR: None metadbdata/, 
      'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_technology_type() function';

      throws_ok { $techtype1->obsolete_technology_type($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
      'TESTING DIE ERROR when argument supplied to obsolete_technology_type() is not a CXGN::Metadata::Metadbdata object';

      throws_ok { $techtype1->obsolete_technology_type($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
      'TESTING DIE ERROR when none obsolete note is supplied to obsolete_technology_type() function';
    
      ## Testing store for modifications (TEST 31 to 34)

      $techtype1->set_description('This is another test');
      $techtype1->store_technology_type($metadbdata);
      
      is($techtype1->get_technology_type_id(), $last_techtype_id+1, 
	 "TESTING STORE_TECHNOLOGY_TYPE for modifications, checking the technology_type_id")
	  or diag "Looks like this failed";
      is($techtype1->get_technology_name(), 'technology_name_test', 
	 "TESTING STORE_TECHNOLOGY_TYPE for modifications, checking the technology_name")
	  or diag "Looks like this failed";
      is($techtype1->get_description(), 'This is another test', 
	 "TESTING STORE_TECHNOLOGY_TYPE for modifications, checking description")
	  or diag "Looks like this failed";

      my $obj_metadbdata2 = $techtype1->get_technology_type_metadbdata();
      is($obj_metadbdata2->get_metadata_id(), $last_metadata_id+4, 
	 "TESTING STORE_TECHNOLOGY_TYPE for modifications, checking new metadata_id")
	  or diag "Looks like this failed";
    

      ## Testing new by name

      ## Die functions (TEST 35)

      throws_ok { CXGN::GEM::TechnologyType->new_by_name() } qr/PARAMETER ERROR: None schema/, 
      'TESTING DIE ERROR when none schema is supplied to constructor: new_by_name()';
      
      ## Warning function (TEST 36)
      warning_like { CXGN::GEM::TechnologyType->new_by_name($schema, 'fake element') } qr/DATABASE OUTPUT WARNING/, 
      'TESTING WARNING ERROR when the technology_name do not exists into the database';
                   
      ## Constructor (TEST 37)
    
      my $techtype2 = CXGN::GEM::TechnologyType->new_by_name($schema, 'technology_name_test');
      is($techtype2->get_technology_type_id(), $last_techtype_id+1, "TESTING NEW_BY_NAME, checking technology_type_id")
	  or diag "Looks like this failed";


     
      #########################################
      ## THIRD BLOCK: General Store function ##
      #########################################

      ## First, check if it die correctly (TEST 38 AND 39)

      throws_ok { $techtype2->store() } qr/STORE ERROR: None metadbdata/, 
      'TESTING DIE ERROR when none metadbdata object is supplied to store() function';
   
      throws_ok { $techtype2->store($schema) } qr/STORE ERROR: Metadbdata supplied/, 
      'TESTING DIE ERROR when argument supplied to store() is not a CXGN::Metadata::Metadbdata object';

      my $techtype3 = CXGN::GEM::TechnologyType->new($schema);
      $techtype3->set_technology_name('technology_name_test2');
      $techtype3->set_description('another test for description');

      $techtype3->store($metadbdata);

      ## Checking the parameters stored

      ## TEST 40

      is($techtype3->get_technology_type_id(), $last_techtype_id+2, 
	 "TESTING GENERAL STORE FUNCTION, checking technology_type_id")
	  or diag "Looks like this failed";

    
      #################################################################
      ## FORTH BLOCK: Functions that interact with other GEM objects ##
      #################################################################

      ## First it will create a two Platform object and store its data (TEST 84 to 87)

      my @platform_names = ('platform test 1', 'platform test 2');

      foreach my $platform_name (@platform_names) {
 	  my $platform = CXGN::GEM::Platform->new($schema);
 	  $platform->set_platform_name($platform_name);
 	  $platform->set_technology_type_id($last_techtype_id+1);
 	  $platform->set_description("This is adescription test");
	  
 	  $platform->store($metadbdata);
      }

      my $techtype4 = CXGN::GEM::TechnologyType->new($schema, $last_techtype_id+1);

      ## Now test the get_platform_list function
  
      my @platforms = $techtype4->get_platform_list();
      my $o = 0;

      foreach my $platf (@platforms) {
	   my $t = $o+1;
 	  is(ref($platf), 'CXGN::GEM::Platform', "TESTING GET_PLATFORM_LIST function, testing object reference ($t)")
 	      or diag "Looks like this failed";
 	  is($platf->get_platform_name(), $platform_names[$o], "TESTING GET_PLATFORM_LIST function, testing platform_names ($t)")
 	      or diag "Looks like this failed";
 	  $o++;
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

## This test does not set table sequences anymore (these methods are deprecated)
done_testing;
