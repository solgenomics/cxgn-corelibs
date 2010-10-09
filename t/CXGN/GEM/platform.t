#!/usr/bin/perl

=head1 NAME

  platform.t
  A piece of code to test the CXGN::GEM::Platform module

=cut

=head1 SYNOPSIS

 perl platform.t

 Note: To run the complete test the database connection should be done as 
       postgres user 
 (web_usr have not privileges to insert new data into the gem tables)  

 prove platform.t

 This test needs some env. variables.
  export GEM_TEST_METALOADER='metaloader user'
  export GEM_TEST_DBDSN='database dsn as: 
     'dbi:DriverName:database=database_name;host=hostname;port=port'

  Example:
    export GEM_TEST_DBDSN='dbi:Pg:database=sandbox;host=localhost;'

  export GEM_TEST_DBUSER='database user with insert permissions'
  export GEM_TEST_DBPASS='database password'

=head1 DESCRIPTION

 This script check 118 variables to test the right operation of the 
 CXGN::GEM::Platform module:

=cut

=head1 AUTHORS

 Aureliano Bombarely Gomez
 (ab782@cornell.edu)

=cut


use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warn;

use CXGN::GEM::Test;

my $gem_test = CXGN::GEM::Test->new;

plan tests => 118;

use_ok('CXGN::GEM::Schema');    ## TEST1
use_ok('CXGN::GEM::Platform');  ## TEST2
use_ok('CXGN::GEM::TechnologyType'); ## TEST3
use_ok('CXGN::GEM::Template');  ## TEST4
use_ok('CXGN::Biosource::Sample'); ## TEST5
use_ok('CXGN::Metadata::Metadbdata'); ## TEST6

## Variables predifined
my $creation_user_name = $gem_test->metaloader_user;

## The GEM schema contain all the metadata, chado and biosource
## classes so don't need to create another Metadata schema

my $schema = $gem_test->dbic_schema('CXGN::GEM::Schema');

$schema->txn_begin();

## Get the last values

my %nextvals = $schema->get_nextval();
my $last_metadata_id = $nextvals{'md_metadata'} || 0;
my $last_platform_id = $nextvals{'ge_platform'} || 0;
my $last_techtype_id = $nextvals{'ge_technology_type'} || 0;
my $last_sample_id = $nextvals{'bs_sample'} || 0;
my $last_dbxref_id = $nextvals{'dbxref'} || 0;
my $last_pub_id = $nextvals{'pub'} || 0;
my $last_contact_id = $nextvals{'sp_person'} || 0;

## Create a empty metadata object to use in the database store functions
my $metadbdata = CXGN::Metadata::Metadbdata->new($schema, $creation_user_name);
my $creation_date = $metadbdata->get_object_creation_date();
my $creation_user_id = $metadbdata->get_object_creation_user_by_id();


#######################################
## FIRST TEST BLOCK: Basic functions ##
#######################################

## (TEST FROM 7 to 11)
## This is the first group of tests, to check if an empty object can store and after can return the data
## Create a new empty object; 

my $platform0 = CXGN::GEM::Platform->new($schema, undef); 

## Load of the eight different parameters for an empty object using a hash with keys=root name for tha function and
 ## values=value to test

my %test_values_for_empty_object=( platform_id        => $last_platform_id+1,
				   platform_name      => 'platform test',
				   technology_type_id => $last_techtype_id+1,
				   description        => 'this is a test',
				   contact_id         => $last_contact_id+1,
                                  );

## Load the data in the empty object
my @function_keys = sort keys %test_values_for_empty_object;
foreach my $rootfunction (@function_keys) {
    my $setfunction = 'set_' . $rootfunction;
    if ($rootfunction eq 'platform_id') {
	$setfunction = 'force_set_' . $rootfunction;
    } 
    $platform0->$setfunction($test_values_for_empty_object{$rootfunction});
}

## Get the data from the object and store in two hashes. The first %getdata with keys=root_function_name and 
 ## value=value_get_from_object and the second, %testname with keys=root_function_name and values=name for the test.

my (%getdata, %testnames);
foreach my $rootfunction (@function_keys) {
    my $getfunction = 'get_'.$rootfunction;
    my $data = $platform0->$getfunction();
    $getdata{$rootfunction} = $data;
    my $testname = 'BASIC SET/GET FUNCTION for ' . $rootfunction.' test';
    $testnames{$rootfunction} = $testname;
}

## And now run the test for each function and value

foreach my $rootfunction (@function_keys) {
    is($getdata{$rootfunction}, $test_values_for_empty_object{$rootfunction}, $testnames{$rootfunction}) 
	or diag "Looks like this failed.";
}


## Testing the die results (TEST 12 to 23)

throws_ok { CXGN::GEM::Platform->new() } qr/PARAMETER ERROR: No schema/, 
    'TESTING DIE ERROR when none schema is supplied to new() function';

throws_ok { CXGN::GEM::Platform->new($schema, 'no integer')} qr/DATA TYPE ERROR/, 
    'TESTING DIE ERROR when a non integer is used to create a platform object with new() function';

throws_ok { CXGN::GEM::Platform->new($schema)->set_geplatform_row() } qr/PARAMETER ERROR: None geplatform_row/, 
    'TESTING DIE ERROR when none schema is supplied to set_geplatform_row() function';

throws_ok { CXGN::GEM::Platform->new($schema)->set_geplatform_row($schema) } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_geplatform_row() is not a CXGN::GEM::Schema::GePlatform row object';

throws_ok { CXGN::GEM::Platform->new($schema)->force_set_platform_id() } qr/PARAMETER ERROR: None platform/, 
    'TESTING DIE ERROR when none platform_id is supplied to set_force_platform_id() function';

throws_ok { CXGN::GEM::Platform->new($schema)->force_set_platform_id('non integer') } qr/DATA TYPE ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_force_platfomr_id() is not an integer';

throws_ok { CXGN::GEM::Platform->new($schema)->set_platform_name() } qr/PARAMETER ERROR: None data/, 
    'TESTING DIE ERROR when none data is supplied to set_platform_name() function';

throws_ok { CXGN::GEM::Platform->new($schema)->set_technology_type_id() } qr/PARAMETER ERROR: None data/, 
    'TESTING DIE ERROR when none data is supplied to set_technology_type_id() function';

throws_ok { CXGN::GEM::Platform->new($schema)->set_technology_type_id('non integer') } qr/DATA TYPE ERROR:/, 
    'TESTING DIE ERROR when arguyment supplied to set_technology_type_id() function is not an integer';

throws_ok { CXGN::GEM::Platform->new($schema)->set_contact_id('non integer') } qr/DATA TYPE ERROR/, 
    'TESTING DIE ERROR when arguyment supplied to set_contact_id() function is not an integer';

throws_ok { CXGN::GEM::Platform->new($schema)->set_contact_by_username() } qr/SET ARGUMENT ERROR/,
    'TESTING DIE ERROE when none data is supplied to set_contact_by_username() function';

throws_ok { CXGN::GEM::Platform->new($schema)->set_contact_by_username('fake_username') } qr/DATABASE COHERENCE ERROR/,
    'TESTING DIE ERROE when username supplied to set_contact_by_username() function do not exists into the database';


###############################################################
### SECOND TEST BLOCK: Platform Store and Obsolete Functions ##
###############################################################

### Use of store functions.

 eval {

     ## First, create a technology_type object, populate it and store it

     my $techtype1 = CXGN::GEM::TechnologyType->new($schema);
     $techtype1->set_technology_name('techtype_test1');
     $techtype1->set_description('This is a test description for techtype');

     $techtype1->store($metadbdata);
     my $techtype_id = $techtype1->get_technology_type_id();

     ## Second, create platform object and populate it.

     my $platform1 = CXGN::GEM::Platform->new($schema);
     $platform1->set_platform_name('platform_test1');
     $platform1->set_technology_type_id($techtype_id);
     $platform1->set_description('This is a description test for platform');
     $platform1->set_contact_by_username($creation_user_name);

     $platform1->store_platform($metadbdata);

     ## Testing the platform data stored for the new object stored (TEST 24 to 28)

     my $platform_id = $platform1->get_platform_id();

     is($platform_id, $last_platform_id+1, "TESTING STORE_PLATFORM FUNCTION, checking the platform_id")
  	 or diag "Looks like this failed";

     my $platform2 = CXGN::GEM::Platform->new($schema, $platform_id);

     is($platform2->get_platform_name(), 'platform_test1', "TESTING STORE_PLATFORM FUNCTION, checking the experimental_design_name")
  	 or diag "Looks like this failed";
     is($platform2->get_technology_type_id(), $techtype_id, "TESTING STORE_PLATFORM FUNCTION, checking the design type")
  	 or diag "Looks like this failed";
     is($platform2->get_description(), 'This is a description test for platform', "TESTING STORE_PLATFORM FUNCTION, checking description")
  	 or diag "Looks like this failed";
     is($platform2->get_contact_by_username(), $creation_user_name, "TESTING STORE_PLATFORM FUNCTION, checking contact_by_username")
  	 or diag "Looks like this failed";


     ## Testing the get_medatata function (TEST 29 to 31)

     my $obj_metadbdata = $platform2->get_platform_metadbdata();
     is($obj_metadbdata->get_metadata_id(), $last_metadata_id+1, "TESTING GET_METADATA FUNCTION, checking the metadata_id")
	 or diag "Looks like this failed";
     is($obj_metadbdata->get_create_date(), $creation_date, "TESTING GET_METADATA FUNCTION, checking create_date")
	 or diag "Looks like this failed";
     is($obj_metadbdata->get_create_person_id_by_username, $creation_user_name, "TESING GET_METADATA FUNCTION, checking create_person")
	 or diag "Looks like this failed";
  
     ## Testing die for store function (TEST 32 and 33)

     throws_ok { $platform2->store_platform() } qr/STORE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to store_platform() function';

     throws_ok { $platform2->store_platform($schema) } qr/STORE ERROR: Metadbdata supplied/, 
     'TESTING DIE ERROR when argument supplied to store_platform() is not a CXGN::Metadata::Metadbdata object';

     ## Testing if it is obsolete (TEST 34)

     is($platform2->is_platform_obsolete(), 0, "TESTING IS_PLATFORM_OBSOLETE FUNCTION, checking boolean")
	 or diag "Looks like this failed";

     ## Testing obsolete (TEST 35 to 38) 

     $platform2->obsolete_platform($metadbdata, 'testing obsolete');
    
     is($platform2->is_platform_obsolete(), 1, 
	"TESTING PLATFORM_OBSOLETE FUNCTION, checking boolean after obsolete the platform")
	 or diag "Looks like this failed";

     is($platform2->get_platform_metadbdata()->get_metadata_id, $last_metadata_id+2, 
	"TESTING PLATFORM_OBSOLETE, checking metadata_id")
	 or diag "Looks like this failed";

     $platform2->obsolete_platform($metadbdata, 'testing obsolete', 'REVERT');
     
     is($platform2->is_platform_obsolete(), 0, 
	"TESTING REVERT PLATFORM_OBSOLETE FUNCTION, checking boolean after revert obsolete")
	 or diag "Looks like this failed";
     
     is($platform2->get_platform_metadbdata()->get_metadata_id, $last_metadata_id+3, 
	"TESTING REVERT PLATFORM_OBSOLETE, for metadata_id")
	 or diag "Looks like this failed";

     ## Testing die for obsolete function (TEST 39 to 41)

     throws_ok { $platform2->obsolete_platform() } qr/OBSOLETE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_platform() function';

     throws_ok { $platform2->obsolete_platform($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
     'TESTING DIE ERROR when argument supplied to obsolete_platform() is not a CXGN::Metadata::Metadbdata object';

     throws_ok { $platform2->obsolete_platform($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
     'TESTING DIE ERROR when none obsolete note is supplied to obsolete_platform() function';
    
     ## Testing store for modifications (TEST 42 to 45)

     $platform2->set_description('This is another test');
     $platform2->store_platform($metadbdata);
     
     is($platform2->get_platform_id(), $last_platform_id+1, 
	"TESTING STORE_PLATFORM for modifications, checking the experimental_design_id")
	 or diag "Looks like this failed";
     is($platform2->get_platform_name(), 'platform_test1', 
	"TESTING STORE_PLATFORM for modifications, checking the platform_name")
	 or diag "Looks like this failed";
     is($platform2->get_description(), 'This is another test', 
	"TESTING STORE_PLATFORM for modifications, checking description")
	 or diag "Looks like this failed";

     my $obj_metadbdata2 = $platform2->get_platform_metadbdata();
     is($obj_metadbdata2->get_metadata_id(), $last_metadata_id+4, 
	"TESTING STORE_PLATFORM for modifications, checking new metadata_id")
	 or diag "Looks like this failed";
    
     ## Testing new by name
    
     ## Die functions (TEST 46)

     throws_ok { CXGN::GEM::Platform->new_by_name() } qr/PARAMETER ERROR: None schema/, 
     'TESTING DIE ERROR when none schema is supplied to constructor: new_by_name()';
    
     ## Warning function (TEST 47)
     warning_like { CXGN::GEM::Platform->new_by_name($schema, 'fake element') } qr/DATABASE OUTPUT WARNING/, 
     'TESTING WARNING ERROR when the platform do not exists into the database';
     
     ## Constructor (TEST 48)
    
     my $platform3 = CXGN::GEM::Platform->new_by_name($schema, 'platform_test1');
     is($platform3->get_platform_id(), $last_platform_id+1, "TESTING NEW_BY_NAME, checking platform_id")
	 or diag "Looks like this failed";

     ##############################################
     ### THIRD BLOCK: Platform_Design functions ###
     ##############################################

     ## This is a test to check if the functions associated to link the Platform with Samples (PlatformDesign rows)
     ## works in the right way

     ## First, create two samples to link
     
     my @sample_names = ('sample_test1', 'sample_test2');
     my @sample_ids = ();
     foreach my $sample_name (@sample_names) {
	 my $sample1 = CXGN::Biosource::Sample->new($schema);
	 $sample1->set_sample_name($sample_name);
	 ### deprecated new CXGN::Biosource::Sample ### $sample1->set_sample_type('test');
	 $sample1->set_description('test description for sample');

	 $sample1->store($metadbdata);
	 push @sample_ids, $sample1->get_sample_id();
     }

     ## Second, add this samples to the platformdesign using add_platform_design function and store it

     foreach my $samplename (@sample_names) {
	 $platform3->add_platform_design($samplename);
     }
     
     $platform3->store_platform_designs($metadbdata);


     ## Third, check if the objects have been stored (TEST 49 and 50)

     my $platform4 = CXGN::GEM::Platform->new($schema, $platform3->get_platform_id() );

     my @platform_design_id_list = $platform4->get_design_list();
     my $obtained_id_list = join(',', sort @platform_design_id_list);
     my $expected_id_list = join(',', sort @sample_ids);

     is($obtained_id_list, $expected_id_list, "TESTING ADD_PLATFORM_DESIGN and STORE_PLATFORM_DESIGN, cheking sample_id_list")
	 or diag("Looks like this failed");

     my @platform_design_name_list = $platform4->get_design_list('sample_name');
     my $obtained_name_list = join(',', sort @platform_design_name_list);
     my $expected_name_list = join(',', sort @sample_names);

     is($obtained_id_list, $expected_id_list, "TESTING ADD_PLATFORM_DESIGN and STORE_PLATFORM_DESIGN, cheking sample_name_list")
	 or diag("Looks like this failed");

     ## Test that add_platform_design die (TEST 51 and 52)

     throws_ok { $platform4->add_platform_design() } qr/FUNCTION PARAMETER ERROR: None data was/, 
     'TESTING DIE ERROR when none data is supplied to add_platform_design() function';

     throws_ok { $platform4->add_platform_design('fake_sample_name') } qr/DATABASE COHERENCE ERROR/, 
     'TESTING DIE ERROR when sample_name supplied to add_platform_design() function does not exists into the database';

     ## Test to store_platform_designs die (TEST 53 to 55)
     
     throws_ok { $platform4->store_platform_designs() } qr/STORE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none data is supplied to store_platform_designs() function';

     throws_ok { $platform4->store_platform_designs($schema) } qr/STORE ERROR: Metadbdata/, 
     'TESTING DIE ERROR when metadbdata supplied to store_platform_designs() function is not CXGN::Metadata::Metadbdata object';

     my $empty_platform = CXGN::GEM::Platform->new($schema);

     throws_ok { $empty_platform->store_platform_designs($metadbdata) } qr/STORE ERROR: Don't exist/, 
     'TESTING DIE ERROR when the platform object used to store_platform_designs() have not platform_id';

     ## Testing Metadata and obsolete functions (TEST 56 to 58)

     my %design_metadata = $platform4->get_platform_design_metadbdata();
     
     is($design_metadata{'sample_test1'}->get_metadata_id, $last_metadata_id+1, 
	"TESTING GET_PLATFORM_DESIGN_METADBDATA, checking metadata_id")
	 or diag("Looks like this failed");

     is($platform4->is_platform_design_obsolete('sample_test1'), 0, "TESTING IS_PLATFORM_DESIGN_OBSOLETE, checking boolean")
	 or diag("Looks like this failed");

     throws_ok { $empty_platform->get_platform_design_metadbdata() } qr/OBJECT MANIPULATION ERROR/, 
     'TESTING DIE ERROR when the platform object used to get_platform_design_metadbdata() have not platform_id';
     
     ## Testing new by design
    
     ## Die functions (TEST 59 and 61)

     throws_ok { CXGN::GEM::Platform->new_by_design() } qr/PARAMETER ERROR: None schema/, 
     'TESTING DIE ERROR when none schema is supplied to constructor: new_by_design()';
    
     throws_ok { CXGN::GEM::Platform->new_by_design($schema, 'It is not an array ref') } qr/PARAMETER ERROR: The element array/, 
     'TESTING DIE ERROR when the array reference supplied to constructor: new_by_design() is not an array reference';

     throws_ok { 
	          warning_like { CXGN::GEM::Platform->new_by_design($schema, ['fake element']) } 
		  qr/DATABASE WARNING: sample_name /,
		  'TESTING WARNING ERROR when the sample name do not exists into the bs_sample table';
     }
     qr/DATABASE OUTPUT WARNING: The sample_name/, 
     'TESTING DIE ERROR when the sample name do not exists into the biosource.bs_sample table in the database for new_by_design()';
     
     ## Warning function (TEST 62 and 63)

     ## It need a sample_name that is in the database but not in the platform_design table

     my $sample2 = CXGN::Biosource::Sample->new($schema);
     $sample2->set_sample_name('sample_test3');
     #$sample2->set_sample_type('test');
     $sample2->set_description('test description for sample');

     $sample2->store($metadbdata);

     warning_like { CXGN::GEM::Platform->new_by_design($schema, ['sample_test3']) } qr/DATABASE OUTPUT WARNING: Elements/, 
     'TESTING WARNING ERROR when the sample name exists in bs_sample table but not in the platform_design table for new_by_design()';

     ## Testing that platform that contain more than one element but only one of then appears in the search produce the same warning 

     warning_like { CXGN::GEM::Platform->new_by_design($schema, ['sample_test1']) } qr/DATABASE OUTPUT WARNING: Elements/, 
     'TESTING WARNING ERROR when the sample name exists in bs_sample table but not in the platform_design table for new_by_design()';


     ## Constructor (TEST 64)
    
     my $platform5 = CXGN::GEM::Platform->new_by_design($schema, ['sample_test1', 'sample_test2']);
     is($platform5->get_platform_id(), $last_platform_id+1, "TESTING NEW_BY_DESIGN, checking platform_id")
	 or diag "Looks like this failed";


     #########################################
     ## FORTH BLOCK: Platform_Pub functions ##
     #########################################

     ## Testing of the publication

     ## Testing the die when the wrong for the row accessions get/set_geexpdesignpub_rows (TEST 65 to 67)
    
     throws_ok { $platform4->set_geplatformpub_rows() } qr/FUNCTION PARAMETER ERROR:None geplatformpub_row/, 
     'TESTING DIE ERROR when none data is supplied to set_geplatformpub_rows() function';

     throws_ok { $platform4->set_geplatformpub_rows('this is not an integer') } qr/SET ARGUMENT ERROR:/, 
     'TESTING DIE ERROR when data type supplied to set_geplatformpub_rows() function is not an array reference';

     throws_ok { $platform4->set_geplatformpub_rows([$schema, $schema]) } qr/SET ARGUMENT ERROR:/, 
     'TESTING DIE ERROR when the elements of the array reference supplied to set_geplatformpub_rows() function are not row objects';


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

     ## TEST 68 AND 69

     $platform4->add_publication($new_pub_id1);
     $platform4->add_publication({ title => 'testingtitle2' });
     $platform4->add_publication({ dbxref_accession => 'TESTDBACC01' });

     my @pub_id_list = $platform4->get_publication_list();
     my $expected_pub_id_list = join(',', sort {$a <=> $b} @pub_list);
     my $obtained_pub_id_list = join(',', sort {$a <=> $b} @pub_id_list);

     is($obtained_pub_id_list, $expected_pub_id_list, 'TESTING ADD_PUBLICATION and GET_PUBLICATION_LIST, checking pub_id list')
	 or diag "Looks like this failed";

     my @pub_title_list = $platform4->get_publication_list('title');
     my $expected_pub_title_list = 'testingtitle1,testingtitle2,testingtitle3';
     my $obtained_pub_title_list = join(',', sort @pub_title_list);
    
     is($obtained_pub_title_list, $expected_pub_title_list, 'TESTING GET_PUBLICATION_LIST TITLE, checking pub_title list')
	 or diag "Looks like this failed";


     ## Only the third pub has associated a dbxref_id (the rest will be undef) (TEST 70)

     my @pub_accession_list = $platform4->get_publication_list('accession');
     my $expected_pub_accession_list = 'TESTDBACC01';
     my $obtained_pub_accession_list = $pub_accession_list[2];   
    
     is($obtained_pub_accession_list, $expected_pub_accession_list, 'TESTING GET_PUBLICATION_LIST ACCESSION, checking pub_accession')
	 or diag "Looks like this failed";

     ## Store functions (TEST 71)

     $platform4->store_pub_associations($metadbdata);
     
     my $platform6 = CXGN::GEM::Platform->new($schema, $platform4->get_platform_id() );
     
     my @pub_id_list2 = $platform6->get_publication_list();
     my $expected_pub_id_list2 = join(',', sort {$a <=> $b} @pub_list);
     my $obtained_pub_id_list2 = join(',', sort {$a <=> $b} @pub_id_list2);
    
     is($obtained_pub_id_list2, $expected_pub_id_list2, 'TESTING STORE PUB ASSOCIATIONS, checking pub_id list')
  	 or diag "Looks like this failed";
    
     ## Testing die for store function (TEST 72 AND 73)
    
     throws_ok { $platform4->store_pub_associations() } qr/STORE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to store_pub_associations() function';
    
     throws_ok { $platform4->store_pub_associations($schema) } qr/STORE ERROR: Metadbdata supplied/, 
     'TESTING DIE ERROR when argument supplied to store_pub_associations() is not a CXGN::Metadata::Metadbdata object';

     ## Testing obsolete functions (TEST 74 to 77)
     
     my $n = 0;
     foreach my $pub_assoc (@pub_id_list2) {
	 $n++;
	 is($platform6->is_platform_pub_obsolete($pub_assoc), 0, 
   	    "TESTING GET_PLATFORM_PUB_METADATA AND IS_PLATFORM_PUB_OBSOLETE, checking boolean ($n)")
	     or diag "Looks like this failed";
     }

     my %platformpub_md1 = $platform6->get_platform_pub_metadbdata();
     is($platformpub_md1{$pub_id_list[1]}->get_metadata_id, $last_metadata_id+1, 
	"TESTING GET_PLATFORM_PUB_METADATA, checking metadata_id")
  	 or diag "Looks like this failed";
     
     ## TEST 78 TO 81

     $platform6->obsolete_pub_association($metadbdata, 'obsolete test for pub', $pub_id_list[1]);
     is($platform6->is_platform_pub_obsolete($pub_id_list[1]), 1, 
	"TESTING OBSOLETE PLATFORM PUB ASSOCIATIONS, checking boolean") 
	 or diag "Looks like this failed";

     my %platformpub_md2 = $platform6->get_platform_pub_metadbdata();
     is($platformpub_md2{$pub_id_list[1]}->get_metadata_id, $last_metadata_id+5, 
	"TESTING OBSOLETE PLATFORM PUB FUNCTION, checking new metadata_id")
  	 or diag "Looks like this failed";

     $platform6->obsolete_pub_association($metadbdata, 'revert obsolete test for pub', $pub_id_list[1], 'REVERT');
     is($platform6->is_platform_pub_obsolete($pub_id_list[1]), 0, 
	"TESTING OBSOLETE PUB ASSOCIATIONS REVERT, checking boolean") 
	 or diag "Looks like this failed";

     my %platformpub_md2o = $platform6->get_platform_pub_metadbdata();
     my $platformpub_metadata_id2 = $platformpub_md2o{$pub_id_list[1]}->get_metadata_id();
     is($platformpub_metadata_id2, $last_metadata_id+6, "TESTING OBSOLETE PUB FUNCTION REVERT, checking new metadata_id")
  	 or diag "Looks like this failed";

     ## Checking the errors for obsolete_pub_asociation (TEST 82 TO 85)
    
     throws_ok { $platform6->obsolete_pub_association() } qr/OBSOLETE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_pub_association() function';
     
     throws_ok { $platform6->obsolete_pub_association($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
     'TESTING DIE ERROR when argument supplied to obsolete_pub_association() is not a CXGN::Metadata::Metadbdata object';
    
     throws_ok { $platform6->obsolete_pub_association($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
     'TESTING DIE ERROR when none obsolete note is supplied to obsolete_pub_association() function';
     
     throws_ok { $platform6->obsolete_pub_association($metadbdata, 'test note') } qr/OBSOLETE ERROR: None pub_id/, 
     'TESTING DIE ERROR when none pub_id is supplied to obsolete_pub_association() function';


     ############################################
     ## FIFTH BLOCK: Platform_Dbxref functions ##
     ############################################

     ## Testing of the dbxref

     ## Testing the die when the wrong for the row accessions get/set_geplatformdbxref_rows (TEST 86 to 88)
     
     throws_ok { $platform6->set_geplatformdbxref_rows() } qr/FUNCTION PARAMETER ERROR:None geplatformdbxref_row/, 
     'TESTING DIE ERROR when none data is supplied to set_geplatformdbxref_rows() function';

     throws_ok { $platform6->set_geplatformdbxref_rows('this is not an integer') } qr/SET ARGUMENT ERROR:/, 
     'TESTING DIE ERROR when data type supplied to set_geplatformdbxref_rows() function is not an array reference';

     throws_ok { $platform6->set_geplatformdbxref_rows([$schema, $schema]) } qr/SET ARGUMENT ERROR:/, 
     'TESTING DIE ERROR when the elements of the array reference supplied to set_geplatformdbxref_rows() function are not row objects';

     ## Check set/get for dbxref (TEST 89)

     $platform6->add_dbxref($new_dbxref_id1);
     $platform6->add_dbxref( 
 	                      { 
 	                        accession => 'TESTDBACC02', 
 			        dbxname   => 'dbtesting',
 			      }
                            );

     my @dbxref_list = ($new_dbxref_id1, $new_dbxref_id2);
     my @dbxref_id_list = $platform6->get_dbxref_list();
     my $expected_dbxref_id_list = join(',', sort {$a <=> $b} @dbxref_list);
     my $obtained_dbxref_id_list = join(',', sort {$a <=> $b} @dbxref_id_list);

     is($obtained_dbxref_id_list, $expected_dbxref_id_list, 'TESTING ADD_DBXREF and GET_DBXREF_LIST, checking dbxref_id list')
	 or diag "Looks like this failed";

     ## Store function (TEST 90)
     
     $platform6->store_dbxref_associations($metadbdata);
     
     my $platform7 = CXGN::GEM::Platform->new($schema, $platform6->get_platform_id() );
     
     my @dbxref_id_list2 = $platform7->get_dbxref_list();
     my $expected_dbxref_id_list2 = join(',', sort {$a <=> $b} @dbxref_list);
     my $obtained_dbxref_id_list2 = join(',', sort {$a <=> $b} @dbxref_id_list2);
    
     is($obtained_dbxref_id_list2, $expected_dbxref_id_list2, 'TESTING STORE DBXREF ASSOCIATIONS, checking dbxref_id list')
  	 or diag "Looks like this failed";

     ## Testing die for store function (TEST 91 AND 92)
    
     throws_ok { $platform6->store_dbxref_associations() } qr/STORE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to store_dbxref_associations() function';
    
     throws_ok { $platform6->store_dbxref_associations($schema) } qr/STORE ERROR: Metadbdata supplied/, 
     'TESTING DIE ERROR when argument supplied to store_dbxref_associations() is not a CXGN::Metadata::Metadbdata object';

     ## Testing obsolete functions (TEST 93 to 95)
     
     my $m = 0;
     foreach my $dbxref_assoc (@dbxref_id_list2) {
	 $m++;
	 is($platform7->is_platform_dbxref_obsolete($dbxref_assoc), 0, 
   	    "TESTING GET_PLATFORM_DBXREF_METADATA AND IS_PLATFORM_DBXREF_OBSOLETE, checking boolean ($m)")
	     or diag "Looks like this failed";
     }

     my %platformdbxref_md1 = $platform7->get_platform_dbxref_metadbdata();
     is($platformdbxref_md1{$dbxref_id_list[1]}->get_metadata_id, $last_metadata_id+1, 
	"TESTING GET_PLATFORM_DBXREF_METADATA, checking metadata_id")
	 or diag "Looks like this failed";

     ## TEST 96 TO 99
     
     $platform7->obsolete_dbxref_association($metadbdata, 'obsolete test for dbxref', $dbxref_id_list[1]);
     is($platform7->is_platform_dbxref_obsolete($dbxref_id_list[1]), 1, 
	"TESTING OBSOLETE PLATFORM DBXREF ASSOCIATIONS, checking boolean") 
	 or diag "Looks like this failed";

     my %platformdbxref_md2 = $platform7->get_platform_dbxref_metadbdata();
     is($platformdbxref_md2{$dbxref_id_list[1]}->get_metadata_id, $last_metadata_id+7, 
	"TESTING OBSOLETE PLATFORM DBXREF FUNCTION, checking new metadata_id")
  	 or diag "Looks like this failed";

     $platform7->obsolete_dbxref_association($metadbdata, 'revert obsolete test for dbxref', $dbxref_id_list[1], 'REVERT');
     is($platform7->is_platform_dbxref_obsolete($dbxref_id_list[1]), 0, 
	"TESTING OBSOLETE DBXREF ASSOCIATIONS REVERT, checking boolean") 
	 or diag "Looks like this failed";
     
     my %platformdbxref_md2o = $platform7->get_platform_dbxref_metadbdata();
     my $platformdbxref_metadata_id2 = $platformdbxref_md2o{$dbxref_id_list[1]}->get_metadata_id();
     is($platformdbxref_metadata_id2, $last_metadata_id+8, "TESTING OBSOLETE DBXREF FUNCTION REVERT, checking new metadata_id")
  	 or diag "Looks like this failed";

     ## Checking the errors for obsolete_pub_asociation (TEST 100 TO 103)
      
     throws_ok { $platform7->obsolete_dbxref_association() } qr/OBSOLETE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_dbxref_association() function';
     
     throws_ok { $platform7->obsolete_dbxref_association($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
     'TESTING DIE ERROR when argument supplied to obsolete_dbxref_association() is not a CXGN::Metadata::Metadbdata object';
    
     throws_ok { $platform7->obsolete_dbxref_association($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
     'TESTING DIE ERROR when none obsolete note is supplied to obsolete_dbxref_association() function';
    
     throws_ok { $platform7->obsolete_dbxref_association($metadbdata, 'test note') } qr/OBSOLETE ERROR: None dbxref_id/, 
     'TESTING DIE ERROR when none dbxref_id is supplied to obsolete_dbxref_association() function';


     #########################################
     ## SIXTH BLOCK: General Store function ##
     #########################################

     ## First, check if it die correctly (TEST 104 AND 105)

     throws_ok { $platform7->store() } qr/STORE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to store() function';
   
     throws_ok { $platform7->store($schema) } qr/STORE ERROR: Metadbdata supplied/, 
     'TESTING DIE ERROR when argument supplied to store() is not a CXGN::Metadata::Metadbdata object';

     ## Second, create all the new data to store this new object

     my $platform8 = CXGN::GEM::Platform->new($schema);
     $platform8->set_platform_name('platform_test8');
     $platform8->set_technology_type_id($techtype_id);
     $platform8->set_description('This is a description test for platform');
     $platform8->set_contact_by_username($creation_user_name);

     $platform8->add_platform_design('sample_test3');
     $platform8->add_publication($new_pub_id1);
     $platform8->add_dbxref($new_dbxref_id1);

     $platform8->store($metadbdata);

     ## Checking the parameters stored

     ## TEST 106 TO 109

     is($platform8->get_platform_id(), $last_platform_id+2, 
	"TESTING GENERAL STORE FUNCTION, checking platform_id")
	 or diag "Looks like this failed";

     my @sample_list3 = $platform8->get_design_list('sample_name');
     is($sample_list3[0], 'sample_test3', "TESTING GENERAL STORE FUNCTION, checking sample_name")
	 or diag "Looks like this failed";

     my @pub_list3 = $platform8->get_publication_list();
     is($pub_list3[0], $new_pub_id1, "TESTING GENERAL STORE FUNCTION, checking pub_id")
	 or diag "Looks like this failed";

     my @dbxref_list3 = $platform8->get_dbxref_list();
     is($dbxref_list3[0], $new_dbxref_id1, "TESTING GENERAL STORE FUNCTION, checking dbxref_id")
	 or diag "Looks like this failed"; 
    


     ###################################################################
     ## SEVENTH BLOCK: Functions that interact with other GEM objects ##
     ###################################################################

     ## First, it will check if it can get the technology_type

     ## To test get_technology_type it doesn't need create any techtype (this was done in the begining of the script )

     ## Testing technology_type object (TEST 110 and 111)

     my $techtype2 = $platform8->get_technology_type();

     is(ref($techtype2), 'CXGN::GEM::TechnologyType', 
	"TESTING GET_TECHNOLOGY_TYPE function, testing object reference")
	 or diag "Looks like this failed";
     is($techtype2->get_technology_name(), 'techtype_test1', 
	"TESTING GET_TECHNOLOGY_TYPE function, testing technology_type_name")
	 or diag "Looks like this failed";

     ## To check templates it will create 4 different templates (TEST 112 to 116)

     my @template_names = ('template_test1', 'template_test2', 'template_test3', 'template_test4');
     my @expected_template_ids = ();

     foreach my $template_name (@template_names) {

	 my $template = CXGN::GEM::Template->new($schema);
	 $template->set_template_name($template_name);
	 $template->set_template_type('test_type');
	 $template->set_platform_id( $platform8->get_platform_id() );
	 
	 $template->store($metadbdata);
	 my $template_id = $template->get_template_id();
	 
	 push @expected_template_ids, $template_id;
     }

     ## Now, check if works the get_template function

     my @template_list = $platform8->get_template_list();
     my @obtained_template_ids = ();

     foreach my $template_obj (@template_list) {

	 is(ref($template_obj), 'CXGN::GEM::Template', "TESTING GET_TEMPLATE_LIST, checking template object reference")
	     or diag("Looks like this failed");

	 my $template_id1 = $template_obj->get_template_id();
	 push @obtained_template_ids, $template_id1;
     }

     my $expected_value = join(',', sort @expected_template_ids);
     my $obtained_value = join(',', sort @obtained_template_ids);
     
     is($obtained_value, $expected_value, "TESTING GET_TEMPLATE_LIST, checking template_id_list")
	 or diag("Looks like this failed");

     ## Check count_templates function (TEST 117)

     my $template_count = $platform8->count_templates();

     is($template_count, scalar(@template_list), "TESTING COUNT_TEMPLATES checking template number")
	 or diag("Looks like this failed");

     ## Check count_probes function (it should be 0) (TEST 118)

     my $probe_count = $platform8->count_probes();

     is($probe_count, 0, "TESTING COUNT_PROBES checking probes number")
	 or diag("Looks like this failed");


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

## This test does not set the table sequences (methods are deprecated)


####
1; #
####
