=head1 GEM TESTS

  For GEM test suite documentation, see L<CXGN::GEM::Test>.

=cut

use strict;
use warnings;

use Test::More;
use Test::Exception;

use CXGN::GEM::Test;

my $gem_test = CXGN::GEM::Test->new;

plan tests => 95;

use_ok('CXGN::GEM::Schema');             ## TEST1
use_ok('CXGN::GEM::ExperimentalDesign'); ## TEST2
use_ok('CXGN::GEM::Experiment');         ## TEST3
use_ok('CXGN::GEM::Target');             ## TEST4
use_ok('CXGN::Metadata::Metadbdata');    ## TEST5

my $creation_user_name = $gem_test->metaloader_user;

## The GEM schema contain all the metadata, chado and biosource classes so don't need to create another Metadata schema

my $schema = $gem_test->dbic_schema('CXGN::GEM::Schema');
$schema->txn_begin();

## Get the last values

my %nextvals = $schema->get_nextval();
my $last_metadata_id = $nextvals{'md_metadata'} || 0;
my $last_expdesign_id = $nextvals{'ge_experimental_design'} || 0;
my $last_dbxref_id = $nextvals{'dbxref'} || 0;
my $last_pub_id = $nextvals{'pub'} || 0;


## Create a empty metadata object to use in the database store functions
my $metadbdata = CXGN::Metadata::Metadbdata->new($schema, $creation_user_name);
my $creation_date = $metadbdata->get_object_creation_date();
my $creation_user_id = $metadbdata->get_object_creation_user_by_id();


#######################################
## FIRST TEST BLOCK: Basic functions ##
#######################################

## (TEST FROM 6 to 9)
## This is the first group of tests, to check if an empty object can store and after can return the data
## Create a new empty object; 

my $expdesign0 = CXGN::GEM::ExperimentalDesign->new($schema, undef); 

## Load of the eight different parameters for an empty object using a hash with keys=root name for tha function and
 ## values=value to test

my %test_values_for_empty_object=( experimental_design_id    => $last_expdesign_id+1,
				   experimental_design_name  => 'experimental design test',
				   description               => 'this is a test',
				   design_type               => 'test',
                                  );

## Load the data in the empty object
my @function_keys = sort keys %test_values_for_empty_object;
foreach my $rootfunction (@function_keys) {
    my $setfunction = 'set_' . $rootfunction;
    if ($rootfunction eq 'experimental_design_id') {
	$setfunction = 'force_set_' . $rootfunction;
    } 
    $expdesign0->$setfunction($test_values_for_empty_object{$rootfunction});
}

## Get the data from the object and store in two hashes. The first %getdata with keys=root_function_name and 
 ## value=value_get_from_object and the second, %testname with keys=root_function_name and values=name for the test.

my (%getdata, %testnames);
foreach my $rootfunction (@function_keys) {
    my $getfunction = 'get_'.$rootfunction;
    my $data = $expdesign0->$getfunction();
    $getdata{$rootfunction} = $data;
    my $testname = 'BASIC SET/GET FUNCTION for ' . $rootfunction.' test';
    $testnames{$rootfunction} = $testname;
}

## And now run the test for each function and value

foreach my $rootfunction (@function_keys) {
    is($getdata{$rootfunction}, $test_values_for_empty_object{$rootfunction}, $testnames{$rootfunction}) 
	or diag "Looks like this failed.";
}


## Testing the die results (TEST 10 to 17)

throws_ok { CXGN::GEM::ExperimentalDesign->new() } qr/PARAMETER ERROR: None schema/, 
    'TESTING DIE ERROR when none schema is supplied to new() function';

throws_ok { CXGN::GEM::ExperimentalDesign->new($schema, 'no integer')} qr/DATA TYPE ERROR/, 
    'TESTING DIE ERROR when a non integer is used to create a protocol object with new() function';

throws_ok { CXGN::GEM::ExperimentalDesign->new($schema)->set_geexpdesign_row() } qr/PARAMETER ERROR: None geexpdesign_row/, 
    'TESTING DIE ERROR when none schema is supplied to set_geexpdesign_row() function';

throws_ok { CXGN::GEM::ExperimentalDesign->new($schema)->set_geexpdesign_row($schema) } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_geexpdesign_row() is not a CXGN::GEM::Schema::GeExperimentalDesign row object';

throws_ok { CXGN::GEM::ExperimentalDesign->new($schema)->force_set_experimental_design_id() } qr/PARAMETER ERROR: None experimental_des/, 
    'TESTING DIE ERROR when none experimental_design_id is supplied to set_force_experimental_design_id() function';

throws_ok { CXGN::GEM::ExperimentalDesign->new($schema)->force_set_experimental_design_id('non integer') } qr/DATA TYPE ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_force_experimental_design_id() is not an integer';

throws_ok { CXGN::GEM::ExperimentalDesign->new($schema)->set_experimental_design_name() } qr/PARAMETER ERROR: None data/, 
    'TESTING DIE ERROR when none data is supplied to set_experimental_design_name() function';

throws_ok { CXGN::GEM::ExperimentalDesign->new($schema)->set_design_type() } qr/PARAMETER ERROR: None data/, 
    'TESTING DIE ERROR when none data is supplied to set_design_type() function';




##########################################################################
### SECOND TEST BLOCK: Experimental Design Store and Obsolete Functions ##
##########################################################################

### Use of store functions.

 eval {

      my $expdesign2 = CXGN::GEM::ExperimentalDesign->new($schema);
      $expdesign2->set_experimental_design_name('experimental_design_test');
      $expdesign2->set_design_type('test');
      $expdesign2->set_description('This is a description test');

      $expdesign2->store_experimental_design($metadbdata);

      ## Testing the experimental_design_id and experimental_design_name for the new object stored (TEST 18 to 21)

      is($expdesign2->get_experimental_design_id(), $last_expdesign_id+1, 
	 "TESTING STORE_EXPERIMENTAL_DESIGN FUNCTION, checking the experimental_design_id")
 	 or diag "Looks like this failed";
      is($expdesign2->get_experimental_design_name(), 'experimental_design_test', 
	 "TESTING STORE_EXPERIMENTAL_DESIGN FUNCTION, checking the experimental_design_name")
 	 or diag "Looks like this failed";
      is($expdesign2->get_design_type(), 'test', 
	 "TESTING STORE_EXPERIMENTAL_DESIGN FUNCTION, checking the design type")
 	 or diag "Looks like this failed";
      is($expdesign2->get_description(), 'This is a description test', 
	 "TESTING STORE_EXPERIMENTAL_DESIGN FUNCTION, checking description")
 	 or diag "Looks like this failed";


      ## Testing the get_medatata function (TEST 22 to 24)

      my $obj_metadbdata = $expdesign2->get_experimental_design_metadbdata();
      is($obj_metadbdata->get_metadata_id(), $last_metadata_id+1, "TESTING GET_METADATA FUNCTION, checking the metadata_id")
  	or diag "Looks like this failed";
      is($obj_metadbdata->get_create_date(), $creation_date, "TESTING GET_METADATA FUNCTION, checking create_date")
  	or diag "Looks like this failed";
      is($obj_metadbdata->get_create_person_id_by_username, $creation_user_name, 
	 "TESING GET_METADATA FUNCTION, checking create_person by username")
  	or diag "Looks like this failed";
    
      ## Testing die for store function (TEST 25 and 26)

      throws_ok { $expdesign2->store_experimental_design() } qr/STORE ERROR: None metadbdata/, 
      'TESTING DIE ERROR when none metadbdata object is supplied to store_experimental_design() function';

      throws_ok { $expdesign2->store_experimental_design($schema) } qr/STORE ERROR: Metadbdata supplied/, 
      'TESTING DIE ERROR when argument supplied to store_experimental_design() is not a CXGN::Metadata::Metadbdata object';

      ## Testing if it is obsolete (TEST 27)

      is($expdesign2->is_experimental_design_obsolete(), 0, "TESTING IS_EXPERIMENTAL_DESIGN_OBSOLETE FUNCTION, checking boolean")
	  or diag "Looks like this failed";

      ## Testing obsolete (TEST 28 to 31) 

      $expdesign2->obsolete_experimental_design($metadbdata, 'testing obsolete');
    
      is($expdesign2->is_experimental_design_obsolete(), 1, 
	 "TESTING EXPERIMENTAL_DESIGN_OBSOLETE FUNCTION, checking boolean after obsolete the experimental_design")
	  or diag "Looks like this failed";

      is($expdesign2->get_experimental_design_metadbdata()->get_metadata_id, $last_metadata_id+2, 
	 "TESTING EXPERIMENTAL_DESIGN_OBSOLETE, checking metadata_id")
	  or diag "Looks like this failed";

      $expdesign2->obsolete_experimental_design($metadbdata, 'testing obsolete', 'REVERT');
    
      is($expdesign2->is_experimental_design_obsolete(), 0, 
	 "TESTING REVERT EXPERIMENTAL_DESIGN_OBSOLETE FUNCTION, checking boolean after revert obsolete")
	  or diag "Looks like this failed";

      is($expdesign2->get_experimental_design_metadbdata()->get_metadata_id, $last_metadata_id+3, 
	 "TESTING REVERT EXPERIMENTAL_DESIGN_OBSOLETE, for metadata_id")
	  or diag "Looks like this failed";

      ## Testing die for obsolete function (TEST 32 to 34)

      throws_ok { $expdesign2->obsolete_experimental_design() } qr/OBSOLETE ERROR: None metadbdata/, 
      'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_experimental_design() function';

      throws_ok { $expdesign2->obsolete_experimental_design($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
      'TESTING DIE ERROR when argument supplied to obsolete_experimental_design() is not a CXGN::Metadata::Metadbdata object';

      throws_ok { $expdesign2->obsolete_experimental_design($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
      'TESTING DIE ERROR when none obsolete note is supplied to obsolete_experimental_design() function';
    
      ## Testing store for modifications (TEST 35 to 38)

      $expdesign2->set_description('This is another test');
      $expdesign2->store_experimental_design($metadbdata);
      
      is($expdesign2->get_experimental_design_id(), $last_expdesign_id+1, 
	 "TESTING STORE_EXPERIMENTAL_DESIGN for modifications, checking the experimental_design_id")
	  or diag "Looks like this failed";
      is($expdesign2->get_experimental_design_name(), 'experimental_design_test', 
	 "TESTING STORE_EXPERIMENTAL_DESIGN for modifications, checking the experimental_design_name")
	  or diag "Looks like this failed";
      is($expdesign2->get_description(), 'This is another test', 
	 "TESTING EXPERIMENTAL_DESIGN_SAMPLE for modifications, checking description")
	  or diag "Looks like this failed";

      my $obj_metadbdata2 = $expdesign2->get_experimental_design_metadbdata();
      is($obj_metadbdata2->get_metadata_id(), $last_metadata_id+4, 
	 "TESTING STORE_EXPERIMENTAL_DESIGN for modifications, checking new metadata_id")
	  or diag "Looks like this failed";
    

      ## Testing new by name (TEST 39)

      my $expdesign3 = CXGN::GEM::ExperimentalDesign->new_by_name($schema, 'experimental_design_test');
      is($expdesign3->get_experimental_design_id(), $last_expdesign_id+1, "TESTING NEW_BY_NAME, checking experimental_design_id")
  	or diag "Looks like this failed";



      ####################################################
      ## THIRD BLOCK: Experimental_Design_Pub functions ##
      ####################################################

      ## Testing of the publication

      ## Testing the die when the wrong for the row accessions get/set_geexpdesignpub_rows (TEST 40 to 42)
    
      throws_ok { $expdesign3->set_geexpdesignpub_rows() } qr/FUNCTION PARAMETER ERROR: None geexpdesignpub_row/, 
      'TESTING DIE ERROR when none data is supplied to set_geexpdesignpub_rows() function';

      throws_ok { $expdesign3->set_geexpdesignpub_rows('this is not an integer') } qr/SET ARGUMENT ERROR:/, 
      'TESTING DIE ERROR when data type supplied to set_geexpdesignpub_rows() function is not an array reference';

      throws_ok { $expdesign3->set_geexpdesignpub_rows([$schema, $schema]) } qr/SET ARGUMENT ERROR:/, 
      'TESTING DIE ERROR when the elements of the array reference supplied to set_geexpdesignpub_rows() function are not row objects';


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

      ## TEST 43 AND 44

      $expdesign3->add_publication($new_pub_id1);
      $expdesign3->add_publication({ title => 'testingtitle2' });
      $expdesign3->add_publication({ dbxref_accession => 'TESTDBACC01' });

      my @pub_id_list = $expdesign3->get_publication_list();
      my $expected_pub_id_list = join(',', sort {$a <=> $b} @pub_list);
      my $obtained_pub_id_list = join(',', sort {$a <=> $b} @pub_id_list);

      is($obtained_pub_id_list, $expected_pub_id_list, 'TESTING ADD_PUBLICATION and GET_PUBLICATION_LIST, checking pub_id list')
           or diag "Looks like this failed";

      my @pub_title_list = $expdesign3->get_publication_list('title');
      my $expected_pub_title_list = 'testingtitle1,testingtitle2,testingtitle3';
      my $obtained_pub_title_list = join(',', sort @pub_title_list);
    
      is($obtained_pub_title_list, $expected_pub_title_list, 'TESTING GET_PUBLICATION_LIST TITLE, checking pub_title list')
           or diag "Looks like this failed";


      ## Only the third pub has associated a dbxref_id (the rest will be undef) (TEST 45)

      my @pub_accession_list = $expdesign3->get_publication_list('accession');
      my $expected_pub_accession_list = 'TESTDBACC01';
      my $obtained_pub_accession_list = $pub_accession_list[2];   
    
      is($obtained_pub_accession_list, $expected_pub_accession_list, 'TESTING GET_PUBLICATION_LIST ACCESSION, checking pub_accession')
  	or diag "Looks like this failed";

      ## Store functions (TEST 46)

      $expdesign3->store_pub_associations($metadbdata);
     
      my $expdesign4 = CXGN::GEM::ExperimentalDesign->new($schema, $expdesign3->get_experimental_design_id() );
     
      my @pub_id_list2 = $expdesign4->get_publication_list();
      my $expected_pub_id_list2 = join(',', sort {$a <=> $b} @pub_list);
      my $obtained_pub_id_list2 = join(',', sort {$a <=> $b} @pub_id_list2);
    
      is($obtained_pub_id_list2, $expected_pub_id_list2, 'TESTING STORE PUB ASSOCIATIONS, checking pub_id list')
 	 or diag "Looks like this failed";
    
      ## Testing die for store function (TEST 47 AND 48)
    
      throws_ok { $expdesign3->store_pub_associations() } qr/STORE ERROR: None metadbdata/, 
      'TESTING DIE ERROR when none metadbdata object is supplied to store_pub_associations() function';
    
      throws_ok { $expdesign3->store_pub_associations($schema) } qr/STORE ERROR: Metadbdata supplied/, 
      'TESTING DIE ERROR when argument supplied to store_pub_associations() is not a CXGN::Metadata::Metadbdata object';

      ## Testing obsolete functions (TEST 49 to 52)
     
      my $n = 0;
      foreach my $pub_assoc (@pub_id_list2) {
           $n++;
           is($expdesign4->is_experimental_design_pub_obsolete($pub_assoc), 0, 
  	    "TESTING GET_EXPERIMENTAL_DESIGN_PUB_METADATA AND IS_EXPERIMENTAL_DESIGN_PUB_OBSOLETE, checking boolean ($n)")
               or diag "Looks like this failed";
      }

      my %expdesignpub_md1 = $expdesign4->get_experimental_design_pub_metadbdata();
      is($expdesignpub_md1{$pub_id_list[1]}->get_metadata_id, $last_metadata_id+1, 
	 "TESTING GET_EXPDESIGN_PUB_METADATA, checking metadata_id")
 	 or diag "Looks like this failed";

      ## TEST 53 TO 56

      $expdesign4->obsolete_pub_association($metadbdata, 'obsolete test for pub', $pub_id_list[1]);
      is($expdesign4->is_experimental_design_pub_obsolete($pub_id_list[1]), 1, 
	 "TESTING OBSOLETE EXPERIMENTAL_DESIGN PUB ASSOCIATIONS, checking boolean") 
           or diag "Looks like this failed";

      my %expdesignpub_md2 = $expdesign4->get_experimental_design_pub_metadbdata();
      is($expdesignpub_md2{$pub_id_list[1]}->get_metadata_id, $last_metadata_id+5, 
	 "TESTING OBSOLETE EXPERIMENTAL_DESIGN PUB FUNCTION, checking new metadata_id")
 	 or diag "Looks like this failed";

      $expdesign4->obsolete_pub_association($metadbdata, 'revert obsolete test for pub', $pub_id_list[1], 'REVERT');
      is($expdesign4->is_experimental_design_pub_obsolete($pub_id_list[1]), 0, 
	 "TESTING OBSOLETE PUB ASSOCIATIONS REVERT, checking boolean") 
           or diag "Looks like this failed";

      my %expdesignpub_md2o = $expdesign4->get_experimental_design_pub_metadbdata();
      my $expdesignpub_metadata_id2 = $expdesignpub_md2o{$pub_id_list[1]}->get_metadata_id();
      is($expdesignpub_metadata_id2, $last_metadata_id+6, "TESTING OBSOLETE PUB FUNCTION REVERT, checking new metadata_id")
 	 or diag "Looks like this failed";

      ## Checking the errors for obsolete_pub_asociation (TEST 57 TO 60)
    
      throws_ok { $expdesign4->obsolete_pub_association() } qr/OBSOLETE ERROR: None metadbdata/, 
      'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_pub_association() function';

      throws_ok { $expdesign4->obsolete_pub_association($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
      'TESTING DIE ERROR when argument supplied to obsolete_pub_association() is not a CXGN::Metadata::Metadbdata object';
    
      throws_ok { $expdesign4->obsolete_pub_association($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
      'TESTING DIE ERROR when none obsolete note is supplied to obsolete_pub_association() function';
    
      throws_ok { $expdesign4->obsolete_pub_association($metadbdata, 'test note') } qr/OBSOLETE ERROR: None pub_id/, 
      'TESTING DIE ERROR when none pub_id is supplied to obsolete_pub_association() function';


      #######################################################
      ## FORTH BLOCK: Experimental_Design_Dbxref functions ##
      #######################################################

      ## Testing of the dbxref

      ## Testing the die when the wrong for the row accessions get/set_geexpdesigndbxref_rows (TEST 61 to 63)
    
      throws_ok { $expdesign3->set_geexpdesigndbxref_rows() } qr/FUNCTION PARAMETER ERROR: None geexpdesigndbxref_row/, 
      'TESTING DIE ERROR when none data is supplied to set_geexpdesigndbxref_rows() function';

      throws_ok { $expdesign3->set_geexpdesigndbxref_rows('this is not an integer') } qr/SET ARGUMENT ERROR:/, 
      'TESTING DIE ERROR when data type supplied to set_geexpdesigndbxref_rows() function is not an array reference';

      throws_ok { $expdesign3->set_geexpdesigndbxref_rows([$schema, $schema]) } qr/SET ARGUMENT ERROR:/, 
      'TESTING DIE ERROR when the elements of the array reference supplied to set_geexpdesigndbxref_rows() function are not row objects';

      ## Check set/get for dbxref (TEST 64)

      $expdesign3->add_dbxref($new_dbxref_id1);
      $expdesign3->add_dbxref( 
	                        { 
	                         accession => 'TESTDBACC02', 
			         dbxname   => 'dbtesting',
			        }
                             );

      my @dbxref_list = ($new_dbxref_id1, $new_dbxref_id2);
      my @dbxref_id_list = $expdesign3->get_dbxref_list();
      my $expected_dbxref_id_list = join(',', sort {$a <=> $b} @dbxref_list);
      my $obtained_dbxref_id_list = join(',', sort {$a <=> $b} @dbxref_id_list);

      is($obtained_dbxref_id_list, $expected_dbxref_id_list, 'TESTING ADD_DBXREF and GET_DBXREF_LIST, checking dbxref_id list')
           or diag "Looks like this failed";

      ## Store function (TEST 65)

      $expdesign3->store_dbxref_associations($metadbdata);
     
      my $expdesign5 = CXGN::GEM::ExperimentalDesign->new($schema, $expdesign3->get_experimental_design_id() );
     
      my @dbxref_id_list2 = $expdesign5->get_dbxref_list();
      my $expected_dbxref_id_list2 = join(',', sort {$a <=> $b} @dbxref_list);
      my $obtained_dbxref_id_list2 = join(',', sort {$a <=> $b} @dbxref_id_list2);
    
      is($obtained_dbxref_id_list2, $expected_dbxref_id_list2, 'TESTING STORE DBXREF ASSOCIATIONS, checking dbxref_id list')
 	 or diag "Looks like this failed";

      ## Testing die for store function (TEST 66 AND 67)
    
      throws_ok { $expdesign3->store_dbxref_associations() } qr/STORE ERROR: None metadbdata/, 
      'TESTING DIE ERROR when none metadbdata object is supplied to store_dbxref_associations() function';
    
      throws_ok { $expdesign3->store_dbxref_associations($schema) } qr/STORE ERROR: Metadbdata supplied/, 
      'TESTING DIE ERROR when argument supplied to store_dbxref_associations() is not a CXGN::Metadata::Metadbdata object';

      ## Testing obsolete functions (TEST 68 to 70)
     
      my $m = 0;
      foreach my $dbxref_assoc (@dbxref_id_list2) {
           $m++;
           is($expdesign5->is_experimental_design_dbxref_obsolete($dbxref_assoc), 0, 
  	    "TESTING GET_EXPERIMENTAL_DESIGN_DBXREF_METADATA AND IS_EXPERIMENTAL_DESIGN_DBXREF_OBSOLETE, checking boolean ($m)")
               or diag "Looks like this failed";
      }

      my %expdesigndbxref_md1 = $expdesign5->get_experimental_design_dbxref_metadbdata();
      is($expdesigndbxref_md1{$dbxref_id_list[1]}->get_metadata_id, $last_metadata_id+1, 
	 "TESTING GET_EXPDESIGN_DBXREF_METADATA, checking metadata_id")
 	 or diag "Looks like this failed";

      ## TEST 71 TO 74

      $expdesign5->obsolete_dbxref_association($metadbdata, 'obsolete test for dbxref', $dbxref_id_list[1]);
      is($expdesign5->is_experimental_design_dbxref_obsolete($dbxref_id_list[1]), 1, 
	 "TESTING OBSOLETE EXPERIMENTAL_DESIGN DBXREF ASSOCIATIONS, checking boolean") 
           or diag "Looks like this failed";

      my %expdesigndbxref_md2 = $expdesign5->get_experimental_design_dbxref_metadbdata();
      is($expdesigndbxref_md2{$dbxref_id_list[1]}->get_metadata_id, $last_metadata_id+7, 
	 "TESTING OBSOLETE EXPERIMENTAL_DESIGN DBXREF FUNCTION, checking new metadata_id")
 	 or diag "Looks like this failed";

      $expdesign5->obsolete_dbxref_association($metadbdata, 'revert obsolete test for dbxref', $dbxref_id_list[1], 'REVERT');
      is($expdesign5->is_experimental_design_dbxref_obsolete($dbxref_id_list[1]), 0, 
	 "TESTING OBSOLETE DBXREF ASSOCIATIONS REVERT, checking boolean") 
           or diag "Looks like this failed";

      my %expdesigndbxref_md2o = $expdesign5->get_experimental_design_dbxref_metadbdata();
      my $expdesigndbxref_metadata_id2 = $expdesigndbxref_md2o{$dbxref_id_list[1]}->get_metadata_id();
      is($expdesigndbxref_metadata_id2, $last_metadata_id+8, "TESTING OBSOLETE DBXREF FUNCTION REVERT, checking new metadata_id")
 	 or diag "Looks like this failed";

      ## Checking the errors for obsolete_pub_asociation (TEST 75 TO 78)
      
      throws_ok { $expdesign4->obsolete_dbxref_association() } qr/OBSOLETE ERROR: None metadbdata/, 
      'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_dbxref_association() function';

      throws_ok { $expdesign4->obsolete_dbxref_association($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
      'TESTING DIE ERROR when argument supplied to obsolete_dbxref_association() is not a CXGN::Metadata::Metadbdata object';
    
      throws_ok { $expdesign4->obsolete_dbxref_association($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
      'TESTING DIE ERROR when none obsolete note is supplied to obsolete_dbxref_association() function';
    
      throws_ok { $expdesign4->obsolete_dbxref_association($metadbdata, 'test note') } qr/OBSOLETE ERROR: None dbxref_id/, 
      'TESTING DIE ERROR when none dbxref_id is supplied to obsolete_dbxref_association() function';

      #########################################
      ## FIFTH BLOCK: General Store function ##
      #########################################

      ## First, check if it die correctly (TEST 79 AND 80)

      throws_ok { $expdesign4->store() } qr/STORE ERROR: None metadbdata/, 
      'TESTING DIE ERROR when none metadbdata object is supplied to store() function';
   
      throws_ok { $expdesign4->store($schema) } qr/STORE ERROR: Metadbdata supplied/, 
      'TESTING DIE ERROR when argument supplied to store() is not a CXGN::Metadata::Metadbdata object';

      my $expdesign6 = CXGN::GEM::ExperimentalDesign->new($schema);
      $expdesign6->set_experimental_design_name('another test for expdesign');
      $expdesign6->set_design_type('another test for types');
      $expdesign6->add_publication($new_pub_id1);
      $expdesign6->add_dbxref($new_dbxref_id1);

      $expdesign6->store($metadbdata);

      ## Checking the parameters stored

      ## TEST 81 TO 83

      is($expdesign6->get_experimental_design_id(), $last_expdesign_id+2, 
	 "TESTING GENERAL STORE FUNCTION, checking experimental_design_id")
	  or diag "Looks like this failed";

      my @pub_list3 = $expdesign6->get_publication_list();
      is($pub_list3[0], $new_pub_id1, "TESTING GENERAL STORE FUNCTION, checking pub_id")
  	or diag "Looks like this failed";

      my @dbxref_list3 = $expdesign6->get_dbxref_list();
      is($dbxref_list3[0], $new_dbxref_id1, "TESTING GENERAL STORE FUNCTION, checking dbxref_id")
  	or diag "Looks like this failed"; 
    
      #################################################################
      ## SIXTH BLOCK: Functions that interact with other GEM objects ##
      #################################################################

      ## First it will create a two Experiment object and store its data (TEST 84 to 87)

      my @exp_names = ('exp test 1', 'exp test 2');

      foreach my $exp_name (@exp_names) {
	  my $experiment = CXGN::GEM::Experiment->new($schema);
	  $experiment->set_experiment_name($exp_name);
	  $experiment->set_experimental_design_id($last_expdesign_id+1);
	  $experiment->set_replicates_nr(3);
	  $experiment->set_colour_nr(1);

	  $experiment->store($metadbdata);
      }

      my $expdesign7 = CXGN::GEM::ExperimentalDesign->new($schema, $last_expdesign_id+1);

      ## Now test the get_experiment_list function
  
      my @experiments = $expdesign7->get_experiment_list();
      my $o = 0;

      foreach my $exp (@experiments) {
	  my $t = $o+1;
	  is(ref($exp), 'CXGN::GEM::Experiment', "TESTING GET_EXPERIMENT_LIST function, testing object reference ($t)")
	      or diag "Looks like this failed";
	  is($exp->get_experiment_name(), $exp_names[$o], "TESTING GET_EXPERIMENT_LIST function, testing experiment_names ($t)")
	      or diag "Looks like this failed";
	  $o++;
      }

      ## Second it will create a four Target objects and store it
      
      my @target_base_names = ( 'target1', 'target2');
      my @target_names = ();

      foreach my $exp2 (@experiments) {
	  my $exp2_id = $exp2->get_experiment_id();
	  my $exp2_name = $exp2->get_experiment_name();

	  foreach my $target_base_name (@target_base_names) {
	      my $target_name = $target_base_name . "_from_" . $exp2_name;
	      push @target_names, $target_name;

	      my $target = CXGN::GEM::Target->new($schema);
	      $target->set_target_name($target_name);
	      $target->set_experiment_id($exp2_id);

	      $target->store_target($metadbdata);
	  }
      }

      ## This should create four target associated with the experiments, now check it. (TEST 88 to 95)

      my @targets = $expdesign7->get_target_list();
      my $p = 0;

      foreach my $targ (@targets) {
	  my $u = $p+1;
	  is(ref($targ), 'CXGN::GEM::Target', "TESTING GET_TARGET_LIST function, testing object reference ($u)")
	      or diag "Looks like this failed";
	  is($targ->get_target_name(), $target_names[$p], "TESTING GET_TARGET_LIST function, testing target_names ($u)")
	      or diag "Looks like this failed";
	  $p++;
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

## This test does not set the table sequence value anymore (these methods are deprecated)
