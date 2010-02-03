#!/usr/bin/perl

=head1 NAME

  experimentaldesign.t
  A piece of code to test the CXGN::GEM::ExperimentalDesign module

=cut

=head1 SYNOPSIS

 perl experimentaldesign.t

 Note: To run the complete test the database connection should be done as 
       postgres user 
 (web_usr have not privileges to insert new data into the gem tables)  

 prove experimentaldesign.t

=head1 DESCRIPTION

 This script check XXX variables to test the right operation of the 
 CXGN::GEM::ExperimentalDesign module:

 


=cut

=head1 AUTHORS

 Aureliano Bombarely Gomez
 (ab782@cornell.edu)

=cut


use strict;
use warnings;

use Data::Dumper;
use Test::More qw | no_plan |; # while developing the test
use Test::Exception;

use CXGN::DB::Connection;

BEGIN {
    use_ok('CXGN::GEM::Schema');             ## TEST1
    use_ok('CXGN::GEM::ExperimentalDesign'); ## TEST2
    use_ok('CXGN::Metadata::Metadbdata');    ## TEST3
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


## The GEM schema contain all the metadata, chado and biosource classes so don't need to create another Metadata schema


## The triggers need to set the search path to tsearch2 in the version of psql 8.1
my $psqlv = `psql --version`;
chomp($psqlv);

my $schema_list = 'gem,biosource,metadata,public';
if ($psqlv =~ /8\.1/) {
    $schema_list .= ',tsearch2';
}

my $schema = CXGN::GEM::Schema->connect( sub { CXGN::DB::Connection->new( 
						                           {
                                                                              dbuser => 'postgres',
                                                                              dbpass => 'Eise!Th9',
                                                                           }
                                                                        )->get_actual_dbh() },
                                             { 
                                                 on_connect_do => ["SET search_path TO $schema_list;"],
                                             },
                                        );

## Get the last values
my $all_last_ids_href = $schema->get_all_last_ids($schema);
my %last_ids = %{$all_last_ids_href};
my $last_metadata_id = $last_ids{'metadata.md_metadata_metadata_id_seq'} || 0;
my $last_expdesign_id = $last_ids{'gem.ge_experimental_design_experimental_design_id_seq'} || 0;
my $last_dbxref_id = $last_ids{'public.dbxref_dbxref_id_seq'} || 0;
my $last_pub_id = $last_ids{'public.pub_pub_id_seq'} || 0;

## Create a empty metadata object to use in the database store functions
my $metadbdata = CXGN::Metadata::Metadbdata->new($schema, 'aure');
my $creation_date = $metadbdata->get_object_creation_date();
my $creation_user_id = $metadbdata->get_object_creation_user_by_id();


#######################################
## FIRST TEST BLOCK: Basic functions ##
#######################################

## (TEST FROM 4 to 7)
## This is the first group of tests, to check if an empty object can store and after can return the data
## Create a new empty object; 

my $sample = CXGN::GEM::ExperimentalDesign->new($schema, undef); 

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
    $sample->$setfunction($test_values_for_empty_object{$rootfunction});
}

## Get the data from the object and store in two hashes. The first %getdata with keys=root_function_name and 
 ## value=value_get_from_object and the second, %testname with keys=root_function_name and values=name for the test.

my (%getdata, %testnames);
foreach my $rootfunction (@function_keys) {
    my $getfunction = 'get_'.$rootfunction;
    my $data = $sample->$getfunction();
    $getdata{$rootfunction} = $data;
    my $testname = 'BASIC SET/GET FUNCTION for ' . $rootfunction.' test';
    $testnames{$rootfunction} = $testname;
}

## And now run the test for each function and value

foreach my $rootfunction (@function_keys) {
    is($getdata{$rootfunction}, $test_values_for_empty_object{$rootfunction}, $testnames{$rootfunction}) 
	or diag "Looks like this failed.";
}


## Testing the die results (TEST 8 to 15)

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

      ## Testing the experimental_design_id and experimental_design_name for the new object stored (TEST 16 to 19)

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


      ## Testing the get_medatata function (TEST 20 to 22)

      my $obj_metadbdata = $expdesign2->get_experimental_design_metadbdata();
      is($obj_metadbdata->get_metadata_id(), $last_metadata_id+1, "TESTING GET_METADATA FUNCTION, checking the metadata_id")
  	or diag "Looks like this failed";
      is($obj_metadbdata->get_create_date(), $creation_date, "TESTING GET_METADATA FUNCTION, checking create_date")
  	or diag "Looks like this failed";
      is($obj_metadbdata->get_create_person_id_by_username, 'aure', "TESING GET_METADATA FUNCTION, checking create_person by username")
  	or diag "Looks like this failed";
    
      ## Testing die for store function (TEST 23 and 24)

      throws_ok { $expdesign2->store_experimental_design() } qr/STORE ERROR: None metadbdata/, 
      'TESTING DIE ERROR when none metadbdata object is supplied to store_experimental_design() function';

      throws_ok { $expdesign2->store_experimental_design($schema) } qr/STORE ERROR: Metadbdata supplied/, 
      'TESTING DIE ERROR when argument supplied to store_experimental_design() is not a CXGN::Metadata::Metadbdata object';

      ## Testing if it is obsolete (TEST 25)

      is($expdesign2->is_experimental_design_obsolete(), 0, "TESTING IS_EXPERIMENTAL_DESIGN_OBSOLETE FUNCTION, checking boolean")
	  or diag "Looks like this failed";

      ## Testing obsolete (TEST 26 to 29) 

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

      ## Testing die for obsolete function (TEST 30 to 32)

      throws_ok { $expdesign2->obsolete_experimental_design() } qr/OBSOLETE ERROR: None metadbdata/, 
      'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_experimental_design() function';

      throws_ok { $expdesign2->obsolete_experimental_design($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
      'TESTING DIE ERROR when argument supplied to obsolete_experimental_design() is not a CXGN::Metadata::Metadbdata object';

      throws_ok { $expdesign2->obsolete_experimental_design($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
      'TESTING DIE ERROR when none obsolete note is supplied to obsolete_experimental_design() function';
    
      ## Testing store for modifications (TEST 33 to 36)

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
    

      ## Testing new by name (TEST 37)

      my $expdesign3 = CXGN::GEM::ExperimentalDesign->new_by_name($schema, 'experimental_design_test');
      is($expdesign3->get_experimental_design_id(), $last_expdesign_id+1, "TESTING NEW_BY_NAME, checking experimental_design_id")
  	or diag "Looks like this failed";



      ####################################################
      ## THIRD BLOCK: Experimental_Design_Pub functions ##
      ####################################################

      ## Testing of the publication

      ## Testing the die when the wrong for the row accessions get/set_geexpdesignpub_rows (TEST 38 to 40)
    
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

      ## TEST 94 AND 95

#      $sample6->add_publication($new_pub_id1);
#      $sample6->add_publication({ title => 'testingtitle2' });
#      $sample6->add_publication({ dbxref_accession => 'TESTDBACC01' });

#      my @pub_id_list = $sample6->get_publication_list();
#      my $expected_pub_id_list = join(',', sort {$a <=> $b} @pub_list);
#      my $obtained_pub_id_list = join(',', sort {$a <=> $b} @pub_id_list);

#      is($obtained_pub_id_list, $expected_pub_id_list, 'TESTING ADD_PUBLICATION and GET_PUBLICATION_LIST, checking pub_id list')
#           or diag "Looks like this failed";

#      my @pub_title_list = $sample6->get_publication_list('title');
#      my $expected_pub_title_list = 'testingtitle1,testingtitle2,testingtitle3';
#      my $obtained_pub_title_list = join(',', sort @pub_title_list);
    
#      is($obtained_pub_title_list, $expected_pub_title_list, 'TESTING GET_PUBLICATION_LIST TITLE, checking pub_title list')
#           or diag "Looks like this failed";


#      ## Only the third pub has associated a dbxref_id (the rest will be undef) (TEST 96)
#      my @pub_accession_list = $sample6->get_publication_list('accession');
#      my $expected_pub_accession_list = 'TESTDBACC01';
#      my $obtained_pub_accession_list = $pub_accession_list[2];   
    
#      is($obtained_pub_accession_list, $expected_pub_accession_list, 'TESTING GET_PUBLICATION_LIST ACCESSION, checking pub_accession list')
#  	or diag "Looks like this failed";


#      ## Store functions (TEST 97)

#      $sample6->store_pub_associations($metadbdata);
     
#      my $sample7 = CXGN::Biosource::Sample->new($schema, $sample6->get_sample_id() );
     
#      my @pub_id_list2 = $sample7->get_publication_list();
#      my $expected_pub_id_list2 = join(',', sort {$a <=> $b} @pub_list);
#      my $obtained_pub_id_list2 = join(',', sort {$a <=> $b} @pub_id_list2);
    
#      is($obtained_pub_id_list2, $expected_pub_id_list2, 'TESTING STORE PUB ASSOCIATIONS, checking pub_id list')
# 	 or diag "Looks like this failed";
    
#      ## Testing die for store function (TEST 98 AND 99)
    
#      throws_ok { $sample6->store_pub_associations() } qr/STORE ERROR: None metadbdata/, 
#      'TESTING DIE ERROR when none metadbdata object is supplied to store_pub_associations() function';
    
#      throws_ok { $sample6->store_pub_associations($schema) } qr/STORE ERROR: Metadbdata supplied/, 
#      'TESTING DIE ERROR when argument supplied to store_pub_associations() is not a CXGN::Metadata::Metadbdata object';

#      ## Testing obsolete functions (TEST 100 to 103)
     
#      my $n = 0;
#      foreach my $pub_assoc (@pub_id_list2) {
#           $n++;
#           is($sample7->is_sample_pub_obsolete($pub_assoc), 0, 
#  	    "TESTING GET_SAMPLE_PUB_METADATA AND IS_SAMPLE_PUB_OBSOLETE, checking boolean ($n)")
#               or diag "Looks like this failed";
#      }

#      my %samplepub_md1 = $sample7->get_sample_pub_metadbdata();
#      is($samplepub_md1{$pub_id_list[1]}->get_metadata_id, $last_metadata_id+1, "TESTING GET_SAMPLE_PUB_METADATA, checking metadata_id")
# 	 or diag "Looks like this failed";

#      ## TEST 104 TO 107

#      $sample7->obsolete_pub_association($metadbdata, 'obsolete test', $pub_id_list[1]);
#      is($sample7->is_sample_pub_obsolete($pub_id_list[1]), 1, "TESTING OBSOLETE PUB ASSOCIATIONS, checking boolean") 
#           or diag "Looks like this failed";

#      my %samplepub_md2 = $sample7->get_sample_pub_metadbdata();
#      is($samplepub_md2{$pub_id_list[1]}->get_metadata_id, $last_metadata_id+8, "TESTING OBSOLETE PUB FUNCTION, checking new metadata_id")
# 	 or diag "Looks like this failed";

#      $sample7->obsolete_pub_association($metadbdata, 'obsolete test', $pub_id_list[1], 'REVERT');
#      is($sample7->is_sample_pub_obsolete($pub_id_list[1]), 0, "TESTING OBSOLETE PUB ASSOCIATIONS REVERT, checking boolean") 
#           or diag "Looks like this failed";

#      my %samplepub_md2o = $sample7->get_sample_pub_metadbdata();
#      my $samplepub_metadata_id2 = $samplepub_md2o{$pub_id_list[1]}->get_metadata_id();
#      is($samplepub_metadata_id2, $last_metadata_id+9, "TESTING OBSOLETE PUB FUNCTION REVERT, checking new metadata_id")
# 	 or diag "Looks like this failed";

#      ## Checking the errors for obsolete_pub_asociation (TEST 108 TO 111)
    
#      throws_ok { $sample7->obsolete_pub_association() } qr/OBSOLETE ERROR: None metadbdata/, 
#      'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_pub_association() function';

#      throws_ok { $sample7->obsolete_pub_association($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
#      'TESTING DIE ERROR when argument supplied to obsolete_pub_association() is not a CXGN::Metadata::Metadbdata object';
    
#      throws_ok { $sample7->obsolete_pub_association($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
#      'TESTING DIE ERROR when none obsolete note is supplied to obsolete_pub_association() function';
    
#      throws_ok { $sample7->obsolete_pub_association($metadbdata, 'test note') } qr/OBSOLETE ERROR: None pub_id/, 
#      'TESTING DIE ERROR when none pub_id is supplied to obsolete_pub_association() function';

    



#      ###########################################
#      ## EIGTHTH BLOCK: General Store function ##
#      ###########################################

#      ## Check if the set_bssampleelementcvterm_rows die correctly (TEST 250 TO 257)

#      throws_ok { $sample7->set_bssampleelementrelation_source_rows() } 
#      qr/FUNCTION PARAMETER ERROR: None bssampleelementrelation_source_row/, 
#      'TESTING DIE ERROR when none data is supplied to set_bssampleelementrelation_source_rows() function';

#      throws_ok { $sample7->set_bssampleelementrelation_source_rows('this is not an integer') } qr/SET ARGUMENT ERROR:/, 
#      'TESTING DIE ERROR when data type supplied to set_bssampleelementrelation_source_rows() function is not an hash reference';

#      throws_ok { $sample7->set_bssampleelementrelation_source_rows({ $sample_element_name1 => $schema}) } qr/SET ARGUMENT ERROR:/, 
#      'TESTING DIE ERROR when elements of the hash ref. supplied to set_bssampleelementrelation_source_rows() function are not array ref.';

#      throws_ok { $sample7->set_bssampleelementrelation_source_rows({ $sample_element_name1 => [$schema] }) } qr/SET ARGUMENT ERROR:/, 
#      "TESTING DIE ERROR when elements of the array ref. supplied to set_bssampleelementrelation_source_rows() function aren't a row obj.";

#      throws_ok { $sample7->set_bssampleelementrelation_result_rows() } 
#      qr/FUNCTION PARAMETER ERROR: None bssampleelementrelation_result_row/, 
#      'TESTING DIE ERROR when none data is supplied to set_bssampleelementrelation_result_rows() function';

#      throws_ok { $sample7->set_bssampleelementrelation_result_rows('this is not an integer') } qr/SET ARGUMENT ERROR:/, 
#      'TESTING DIE ERROR when data type supplied to set_bssampleelementrelation_result_rows() function is not an hash reference';

#      throws_ok { $sample7->set_bssampleelementrelation_result_rows({ $sample_element_name1 => $schema}) } qr/SET ARGUMENT ERROR:/, 
#      'TESTING DIE ERROR when elements of the hash ref. supplied to set_bssampleelementrelation_result_rows() function are not array ref.';

#      throws_ok { $sample7->set_bssampleelementrelation_result_rows({ $sample_element_name1 => [$schema] }) } qr/SET ARGUMENT ERROR:/, 
#      "TESTING DIE ERROR when elements of the array ref. supplied to set_bssampleelementrelation_result_rows() function aren't a row obj.";

#      ## Testing die for add_source_relation_to_sample_element and add_result_relation_to_sample_element (TEST 258 to 263)

#       throws_ok { $sample7->add_source_relation_to_sample_element() } qr/FUNCTION PARAMETER ERROR: None data/, 
#      'TESTING DIE ERROR when none data is supplied to add_source_relation_to_sample_element() function';

#      throws_ok { $sample7->add_source_relation_to_sample_element($a) } qr/FUNCTION PARAMETER ERROR: None element_name_B/, 
#      'TESTING DIE ERROR when none sample_element_name_B is supplied to add_source_relation_to_sample_element() function';

#      throws_ok { $sample7->add_source_relation_to_sample_element($a, $b) } qr/FUNCTION PARAMETER ERROR: None relation_type/, 
#      'TESTING DIE ERROR when none relation_type is supplied to add_source_relation_to_sample_element() function';
     
#      throws_ok { $sample7->add_source_relation_to_sample_element('none', $b, 'test') } qr/DATA OBJECT COHERENCE ERROR: Element_sam/, 
#      'TESTING DIE ERROR when element_sample_name supplied to add_source_relation_to_sample_element() do not exists into the object';


#      $sample13->add_sample_element(    
#                                     { 
# 				       sample_element_name => 'sample element 1',
# 				       alternative_name    => 'another sample element 1',
# 				       description         => 'This is a sample element test',
# 				       organism_id         => $organism_id, 
# 				       protocol_id         => $protocol_id,
#                                     }
#  	                          );

#      throws_ok { $sample13->add_source_relation_to_sample_element($a, $b, 'test') } qr/OBJECT MANIPULATION ERROR:/, 
#      'TESTING DIE ERROR when try to add_source_relation_to_sample_element where sample_element has not been stored';
     
#      throws_ok { $sample7->add_source_relation_to_sample_element($a, 'none', 'test') } qr/DATABASE COHERENCE ERROR: Sample_el/, 
#      'TESTING DIE ERROR when sample_element_name_B supplied to add_source_relation_to_sample_element() function do not exist in db';


#      ## Before add relations to sample elements it will create a new sample with new elements

#      my $sample_new = CXGN::Biosource::Sample->new($schema);
#      $sample_new->set_sample_name('sample_test_for_elements');
#      $sample_new->set_sample_type('test');
#      $sample_new->add_sample_element({ sample_element_name => 'element t', organism_name => 'Genus species'});
#      $sample_new->add_sample_element({ sample_element_name => 'element v', organism_name => 'Genus species'});
#      $sample_new->add_sample_element({ sample_element_name => 'element w', organism_name => 'Genus species'});
#      $sample_new->add_sample_element({ sample_element_name => 'element x', organism_name => 'Genus species'});
#      $sample_new->add_sample_element({ sample_element_name => 'element y', organism_name => 'Genus species'});
#      $sample_new->add_sample_element({ sample_element_name => 'element z', organism_name => 'Genus species'});
#      $sample_new->store_sample($metadbdata);
#      $sample_new->store_sample_elements($metadbdata);
 
#      my %new_sample_elements = $sample_new->get_sample_elements();
#      my ($t, $v, $w, $x, $y, $z) = sort keys %new_sample_elements;

#      ## Testing add_source_relation_to_sample_element function (TEST 264 to 272)
     
#      $sample15->add_source_relation_to_sample_element($a, $t, 'source relation test 1-t');
#      $sample15->add_source_relation_to_sample_element($a, $v, 'source relation test 1-v');
#      $sample15->add_source_relation_to_sample_element($b, $w, 'source relation test 2-w');
#      $sample15->add_result_relation_to_sample_element($a, $x, 'result relation test 1-x');

#      my ($source_relations_href, $result_relations_href) = $sample15->get_relations_from_sample_elements();

#      is(scalar(keys %{$source_relations_href}), 2, 
# 	"TESTING SOURCE RELATION TO SAMPLE ELEMENTS, checking number of source sample element names")
# 	 or diag "Looks like this failed";
#      is(scalar(keys %{$result_relations_href}), 1, 
# 	"TESTING RESULT RELATION TO SAMPLE ELEMENTS, checking number of result sample element names")
# 	 or diag "Looks like this failed";

#      is(scalar( @{ $source_relations_href->{$a} } ), 2, 
# 	"TESTING SOURCE RELATION TO SAMPLE ELEMENTS, checking number of element in the array reference associated to sample element ($a)")
# 	 or diag "Looks like this failed";
#      is(scalar( @{ $result_relations_href->{$a} } ), 1, 
# 	"TESTING RESULT RELATION TO SAMPLE ELEMENTS, checking number of element in the array reference associated to sample element ($a)")
# 	 or diag "Looks like this failed";

#      is($source_relations_href->{$a}->[0]->{'sample_element_name'}, $t, 
# 	"TESTING SOURCE RELATION TO SAMPLE ELEMENTS, sample_element_name for 1st element of the array associated to sample_element=$a")
# 	 or diag "Looks like this failed";
#      is($source_relations_href->{$a}->[1]->{'relation_type'}, 'source relation test 1-v' , 
# 	"TESTING SOURCE RELATION TO SAMPLE ELEMENTS, relation_type for 2nd element of the array associated to sample_element=$a")
# 	 or diag "Looks like this failed";
#      is($source_relations_href->{$b}->[0]->{'sample_element_name'}, $w, 
# 	"TESTING SOURCE RELATION TO SAMPLE ELEMENTS, sample_element_name for 2nd element of the array associated to sample_element=$b")
# 	 or diag "Looks like this failed";
#      is($source_relations_href->{$b}->[0]->{'relation_type'}, 'source relation test 2-w', 
# 	"TESTING SOURCE RELATION TO SAMPLE ELEMENTS, relation_type for 2nd element of the array associated to sample_element=$b")
# 	 or diag "Looks like this failed";
#      is($result_relations_href->{$a}->[0]->{'sample_element_name'}, $x, 
# 	"TESTING RESULT RELATION TO SAMPLE ELEMENTS, sample_element_name for 1st element of the array associated to sample_element=$a")
# 	 or diag "Looks like this failed";


#      ## Testing store function

#      ## First, check that the process die correctly (TEST 273 AND 274)

#      throws_ok { $sample7->store_element_relations() } qr/STORE ERROR: None metadbdata/, 
#      'TESTING DIE ERROR when none metadbdata object is supplied to store_element_relations() function';
    
#      throws_ok { $sample7->store_element_relations($schema) } qr/STORE ERROR: Metadbdata supplied/, 
#      'TESTING DIE ERROR when argument supplied to store_element_relations() is not a CXGN::Metadata::Metadbdata object';

#      ## TEST 275 TO 283

#      $sample15->store_element_relations($metadbdata);

#      my $sample17 = CXGN::Biosource::Sample->new($schema, $sample7->get_sample_id() );
#      my ($source_relations17_href, $result_relations17_href) = $sample17->get_relations_from_sample_elements();

#      ## It will use the same functions used to check the relations but over the hash references obteined after use store
 
#      is(scalar(keys %{$source_relations17_href}), 2, 
# 	"TESTING STORE ELEMENT RELATIONS, checking number of source sample element names")
# 	 or diag "Looks like this failed";
#      is(scalar(keys %{$result_relations17_href}), 1, 
# 	"TESTING STORE ELEMENT RELATIONS, checking number of result sample element names")
# 	 or diag "Looks like this failed";

#      is(scalar( @{ $source_relations17_href->{$a} } ), 2, 
# 	"TESTING STORE ELEMENT RELATIONS, checking number of element in the array reference associated to sample element ($a)")
# 	 or diag "Looks like this failed";
#      is(scalar( @{ $result_relations17_href->{$a} } ), 1, 
# 	"TESTING STORE ELEMENT RELATIONS, checking number of element in the array reference associated to sample element ($a)")
# 	 or diag "Looks like this failed";

#      is($source_relations17_href->{$a}->[0]->{'sample_element_name'}, $t, 
# 	"TESTING STORE ELEMENT RELATIONS, sample_element_name for 1st element of the array associated to sample_element=$a")
# 	 or diag "Looks like this failed";
#      is($source_relations17_href->{$a}->[1]->{'relation_type'}, 'source relation test 1-v' , 
# 	"TESTING STORE ELEMENT RELATIONS, relation_type for 2nd element of the array associated to sample_element=$a")
# 	 or diag "Looks like this failed";
#      is($source_relations17_href->{$b}->[0]->{'sample_element_name'}, $w, 
# 	"TESTING STORE ELEMENT RELATIONS, sample_element_name for 2nd element of the array associated to sample_element=$b")
# 	 or diag "Looks like this failed";
#      is($source_relations17_href->{$b}->[0]->{'relation_type'}, 'source relation test 2-w', 
# 	"TESTING STORE ELEMENT RELATIONS, relation_type for 2nd element of the array associated to sample_element=$b")
# 	 or diag "Looks like this failed";
#      is($result_relations17_href->{$a}->[0]->{'sample_element_name'}, $x, 
# 	"TESTING STORE ELEMENT RELATIONS, sample_element_name for 1st element of the array associated to sample_element=$a")
# 	 or diag "Looks like this failed";

#      ## Testing when the same relation is added (TEST 284 to 288)

#      $sample17->add_source_relation_to_sample_element($a, $v, 'source relation test 1-v');
#      $sample17->store_element_relations($metadbdata);

#      my $sample18 = CXGN::Biosource::Sample->new($schema, $sample8->get_sample_id() );
#      my ($source_relations18_href, $result_relations18_href) = $sample18->get_relations_from_sample_elements();

#      ## It will use the same functions used to check the relations but over the hash references obteined after use store
 
#      is(scalar(keys %{$source_relations18_href}), 2, 
# 	"TESTING STORE ELEMENT RELATIONS (adding same relation), checking number of source sample element names")
# 	 or diag "Looks like this failed";
#      is(scalar(keys %{$result_relations18_href}), 1, 
# 	"TESTING STORE ELEMENT RELATIONS (addins same relation), checking number of result sample element names")
# 	 or diag "Looks like this failed";

#      is(scalar( @{ $source_relations18_href->{$a} } ), 2, 
# 	"TESTING STORE ELEMENT RELATIONS (adding same relation), checking N of element in array ref. associated to sample element ($a)")
# 	 or diag "Looks like this failed";
#      is(scalar( @{ $result_relations18_href->{$a} } ), 1, 
# 	"TESTING STORE ELEMENT RELATIONS (adding same relation), checking N of element in array ref. associated to sample element ($a)")
# 	 or diag "Looks like this failed";
#      is($source_relations18_href->{$a}->[1]->{'relation_type'}, 'source relation test 1-v' , 
# 	"TESTING STORE ELEMENT RELATIONS (adding same relation), relation_type for 2nd element of array associated to sample_element=$a")
# 	 or diag "Looks like this failed";

#      ## check use of get metadata object (TEST 289 and 290)

#      my ($metadbdata_source_href, $metadbdata_result_href) = $sample17->get_element_relation_metadbdata($metadbdata);
     

#      is($metadbdata_source_href->{$a}->{$v}->get_metadata_id(), $last_metadata_id+1, 
# 	"TESTING GET_ELEMENT_SOURCE_RELATION_METADBDATA, checking metadata_id")
# 	or diag "Looks like this failed";
#      is($metadbdata_result_href->{$a}->{$x}->get_metadata_id(), $last_metadata_id+1, 
# 	"TESTING GET_ELEMENT_SOURCE_RELATION_METADBDATA, checking metadata_id")
# 	or diag "Looks like this failed";
     
     
#      ## Use of add_function to edit a relation_type (TEST 291 to 296)

#      $sample17->add_source_relation_to_sample_element($a, $v, 'source relation test 1-v modified');
#      $sample17->store_element_relations($metadbdata);

#      my $sample19 = CXGN::Biosource::Sample->new($schema, $sample8->get_sample_id() );
#      my ($source_relations19_href, $result_relations19_href) = $sample19->get_relations_from_sample_elements();
#      my %metadbdata_source_mod = $sample19->get_element_relation_metadbdata($metadbdata, 'source');

#      ## It will use the same functions used to check the relations but over the hash references obteined after use store
 
#      is(scalar(keys %{$source_relations19_href}), 2, 
# 	"TESTING STORE ELEMENT RELATIONS (editing a relation), checking number of source sample element names")
# 	 or diag "Looks like this failed";
#      is(scalar(keys %{$result_relations19_href}), 1, 
# 	"TESTING STORE ELEMENT RELATIONS (editing a relation), checking number of result sample element names")
# 	 or diag "Looks like this failed";

#      is(scalar( @{ $source_relations19_href->{$a} } ), 2, 
# 	"TESTING STORE ELEMENT RELATIONS (editing a relation), checking N of element in array ref. associated to sample element ($a)")
# 	 or diag "Looks like this failed";
#      is(scalar( @{ $result_relations19_href->{$a} } ), 1, 
# 	"TESTING STORE ELEMENT RELATIONS (editing a relation), checking N of element in array ref. associated to sample element ($a)")
# 	 or diag "Looks like this failed";
#      is($source_relations19_href->{$a}->[1]->{'relation_type'}, 'source relation test 1-v modified' , 
# 	"TESTING STORE ELEMENT RELATIONS (editing a relation), relation_type for 2nd element of array associated to sample_element=$a")
# 	 or diag "Looks like this failed";

#      is($metadbdata_source_mod{$a}->{$v}->get_metadata_id(), $last_metadata_id+14, 
# 	"TESTING STORE ELEMENT RELATIONS (editing a relation), checking the metadata_id for the relation modified")
# 	 or diag "Looks like this failed";

#      ## Testing when another relation is added (TEST 297 AND 300)

#      $sample17->add_source_relation_to_sample_element($a, $y, 'source relation test 1-y');
#      $sample17->store_element_relations($metadbdata);

#      my $sample20 = CXGN::Biosource::Sample->new($schema, $sample8->get_sample_id() );
#      my ($source_relations20_href, $result_relations20_href) = $sample20->get_relations_from_sample_elements();

#      ## It will use the same functions used to check the relations but over the hash references obtained after use store
 
#      is(scalar(keys %{$source_relations20_href}), 2, 
# 	"TESTING STORE ELEMENT RELATIONS, checking number of source sample element names")
# 	 or diag "Looks like this failed";
#      is(scalar(keys %{$result_relations20_href}), 1, 
# 	"TESTING STORE ELEMENT RELATIONS, checking number of result sample element names")
# 	 or diag "Looks like this failed";

#      is(scalar( @{ $source_relations20_href->{$a} } ), 3, 
# 	"TESTING STORE ELEMENT RELATIONS, checking number of element in the array reference associated to sample element ($a)")
# 	 or diag "Looks like this failed";
#      is(scalar( @{ $result_relations20_href->{$a} } ), 1, 
# 	"TESTING STORE ELEMENT RELATIONS, checking number of element in the array reference associated to sample element ($a)")
# 	 or diag "Looks like this failed";
     
#      ## Testing the metadata functions and obsolete funtion (TEST 301 and 302)

#      is($sample20->is_element_relation_obsolete($a, $v), 0, "TESTING IS_ELEMENT_RELATION_OBSOLETE for a source, checking boolean")
# 	 or diag "Looks like this failed";

#      is($sample20->is_element_relation_obsolete($a, $x), 0, "TESTING IS_ELEMENT_RELATION_OBSOLETE for a result, checking boolean")
# 	 or diag "Looks like this failed";


#      ## Testing die for obsolete function (TEST 303 TO 310)

#      throws_ok { $sample20->obsolete_element_relation() } qr/OBSOLETE ERROR: None metadbdata/, 
#      'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_element_relation() function';

#      throws_ok { $sample20->obsolete_element_relation($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
#      'TESTING DIE ERROR when argument supplied to obsolete_element_relation() is not a CXGN::Metadata::Metadbdata object';
   
#      throws_ok { $sample20->obsolete_element_relation($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
#      'TESTING DIE ERROR when none obsolete note is supplied to obsolete_element_relation() function';
    
#      throws_ok { $sample20->obsolete_element_relation($metadbdata, 'note') } qr/OBSOLETE ERROR: None element_name/, 
#      'TESTING DIE ERROR when none element_name is supplied to obsolete_element_relation() function';
     
#      throws_ok { $sample20->obsolete_element_relation($metadbdata, 'note', $a)} qr/OBSOLETE ERROR: None related/, 
#      'TESTING DIE ERROR when none related_sample_element is supplied to obsolete_element_relation() function';
     
#      throws_ok { $sample20->obsolete_element_relation($metadbdata, 'note' , 'none' , 'none') } 
#      qr/OBSOLETE PARAMETER ERROR/, 
#      'TESTING DIE ERROR when the sample_element and related_name supplied to obsolete_file_file_association() do not exist inside obj.';

#      throws_ok { $sample20->obsolete_element_relation($metadbdata, 'note' , $a, 'none') } 
#      qr/OBSOLETE PARAMETER ERROR/, 
#      'TESTING DIE ERROR when the related_sample_element supplied to obsolete_element_file_association() function donot exist inside obj.';

#      throws_ok { $sample20->obsolete_element_relation($metadbdata, 'note', 'none', $v) } 
#      qr/DATA COHERENCE ERROR/, 
#      'TESTING DIE ERROR when the sample_element supplied to obsolete_element_file_association() function do not exist inside obj.';


#      ## Test for obsolete_element_relation function (TEST 311 to 326)

#      $sample20->obsolete_element_relation($metadbdata, 'test obsolete source relation', $a, $v);

#      is($sample20->is_element_relation_obsolete($a, $v), 1, 
# 	"TESTING OBSOLETE_ELEMENT_RELATION for a source modified, checking boolean (1)")
# 	 or diag "Looks like this failed";

#      my ($metadbdata_source20_href, $metadbdata_result20_href) = $sample20->get_element_relation_metadbdata($metadbdata);

#      is($metadbdata_source20_href->{$a}->{$v}->get_metadata_id(), $last_metadata_id+15, 
# 	"TESTING OBSOLETE_ELEMENT_RELATION, checking the metadata_id for the relation modified")
# 	 or diag "Looks like this failed";

#      is($sample20->is_element_relation_obsolete($a, $x), 0, 
# 	"TESTING OBSOLETE_ELEMENT_RELATION for a result unmodified, checking boolean (0)")
# 	 or diag "Looks like this failed";

#      is($metadbdata_result20_href->{$a}->{$x}->get_metadata_id(), $last_metadata_id+1, 
# 	"TESTING OBSOLETE_ELEMENT_RELATION, checking the metadata_id for the relation unmodified")
# 	 or diag "Looks like this failed";


#      $sample20->obsolete_element_relation($metadbdata, 'test obsolete result relation', $a, $x);

#      is($sample20->is_element_relation_obsolete($a, $v), 1, 
# 	 "TESTING OBSOLETE_ELEMENT_RELATION for a source unmodified, checking boolean (1)")
# 	 or diag "Looks like this failed";

#      my ($metadbdata_source21_href, $metadbdata_result21_href) = $sample20->get_element_relation_metadbdata($metadbdata);

#      is($metadbdata_source21_href->{$a}->{$v}->get_metadata_id(), $last_metadata_id+15, 
# 	"TESTING OBSOLETE_ELEMENT_RELATION, checking the metadata_id for the relation unmodified")
# 	 or diag "Looks like this failed";

#      is($sample20->is_element_relation_obsolete($a, $x), 1, 
# 	"TESTING OBSOLETE_ELEMENT_RELATION for a modified result, checking boolean (1)")
# 	 or diag "Looks like this failed";

#      is($metadbdata_result21_href->{$a}->{$x}->get_metadata_id(), $last_metadata_id+16, 
# 	"TESTING OBSOLETE_ELEMENT_RELATION, checking the metadata_id for the relation modified")
# 	 or diag "Looks like this failed";

#      $sample20->obsolete_element_relation($metadbdata, 'test revert obsolete source relation', $a, $v, 'REVERT');

#      is($sample20->is_element_relation_obsolete($a, $v), 0, 
# 	 "TESTING OBSOLETE_ELEMENT_RELATION REVERT for a source modified, checking boolean (0)")
# 	 or diag "Looks like this failed";

#      my ($metadbdata_source22_href, $metadbdata_result22_href) = $sample20->get_element_relation_metadbdata($metadbdata);

#      is($metadbdata_source22_href->{$a}->{$v}->get_metadata_id(), $last_metadata_id+17, 
# 	"TESTING OBSOLETE_ELEMENT_RELATION REVERT, checking the metadata_id for the relation modified")
# 	 or diag "Looks like this failed";

#      is($sample20->is_element_relation_obsolete($a, $x), 1, 
# 	"TESTING OBSOLETE_ELEMENT_RELATION for a unmodified result during revert, checking boolean (1)")
# 	 or diag "Looks like this failed";

#      is($metadbdata_result22_href->{$a}->{$x}->get_metadata_id(), $last_metadata_id+16, 
# 	"TESTING OBSOLETE_ELEMENT_RELATION , checking the metadata_id for the relation unmodified during revert obsolete")
# 	 or diag "Looks like this failed";

#       $sample20->obsolete_element_relation($metadbdata, 'test revert obsolete source relation', $a, $x, 'REVERT');

#      is($sample20->is_element_relation_obsolete($a, $v), 0, 
# 	 "TESTING OBSOLETE_ELEMENT_RELATION REVERT for a source unmodified, checking boolean (0)")
# 	 or diag "Looks like this failed";

#      my ($metadbdata_source23_href, $metadbdata_result23_href) = $sample20->get_element_relation_metadbdata($metadbdata);

#      is($metadbdata_source23_href->{$a}->{$v}->get_metadata_id(), $last_metadata_id+17, 
# 	"TESTING OBSOLETE_ELEMENT_RELATION REVERT, checking the metadata_id for the relation unmodified")
# 	 or diag "Looks like this failed";

#      is($sample20->is_element_relation_obsolete($a, $x), 0, 
# 	"TESTING OBSOLETE_ELEMENT_RELATION REVERT for a modified result during revert, checking boolean (1)")
# 	 or diag "Looks like this failed";

#      is($metadbdata_result23_href->{$a}->{$x}->get_metadata_id(), $last_metadata_id+18, 
# 	"TESTING OBSOLETE_ELEMENT_RELATION REVERT, checking the metadata_id for the relation modified during revert obsolete")
# 	 or diag "Looks like this failed";



#      ###########################################
#      ## NINTH BLOCK: General Store function ##
#      ###########################################

#      ## First, check if it die correctly (TEST 327 AND 328)

#      throws_ok { $sample3->store() } qr/STORE ERROR: None metadbdata/, 
#      'TESTING DIE ERROR when none metadbdata object is supplied to store() function';
   
#      throws_ok { $sample3->store($schema) } qr/STORE ERROR: Metadbdata supplied/, 
#      'TESTING DIE ERROR when argument supplied to store() is not a CXGN::Metadata::Metadbdata object';

#      my $sample21 = CXGN::Biosource::Sample->new($schema);
#      $sample21->set_sample_name('protocol_test_for_exceptions');
#      $sample21->set_sample_type('another test');
#      $sample21->add_sample_element({ sample_element_name => 'last test', organism_name => 'Genus species' });
#      $sample21->add_dbxref_to_sample_element('last test', $t_dbxref_id2);
#      $sample21->add_cvterm_to_sample_element('last test', $t_cvterm_id2);
#      $sample21->add_publication($new_pub_id1);
#      $sample21->add_file_to_sample_element('last test', $fileids{'test3.txt'});
#      $sample21->store($metadbdata);

#      ## This not store relation because to do it, it needs store before the sample element

#      ## TEST 329 TO 334

#      is($sample21->get_sample_id(), $last_sample_id+3, "TESTING GENERAL STORE FUNCTION, checking sample_id")
#  	or diag "Looks like this failed";
    
#      my %elements21 = $sample21->get_sample_elements();
#      is($elements21{'last test'}->{'organism_name'}, 'Genus species', "TESTING GENERAL STORE FUNCTION, checking organism_name")
#  	or diag "Looks like this failed";

#      my @pub_list21 = $sample21->get_publication_list();
#      is($pub_list21[0], $new_pub_id1, "TESTING GENERAL STORE FUNCTION, checking pub_id")
#  	or diag "Looks like this failed";

#      my %element_dbxref21 = $sample21->get_dbxref_from_sample_elements();
#      is($element_dbxref21{'last test'}->[0], $t_dbxref_id2, "TESTING GENERAL STORE FUNCTION, checking dbxref_id")
#  	or diag "Looks like this failed";

#      my %element_cvterm21 = $sample21->get_cvterm_from_sample_elements();
#      is($element_cvterm21{'last test'}->[0], $t_cvterm_id2, "TESTING GENERAL STORE FUNCTION, checking cvterm_id")
#  	or diag "Looks like this failed";

#      my %element_file21 = $sample21->get_file_from_sample_elements();
#      is($element_file21{'last test'}->[0], $fileids{'test3.txt'}, "TESTING GENERAL STORE FUNCTION, checking file_id")
# 	 or diag "Looks like this failed";
     
    

};  ## End of the eval function

if ($@) {
    print "\nEVAL ERROR:\n\n$@\n";
}



 ## RESTORING THE ORIGINAL STATE IN THE DATABASE
## To restore the original state in the database, rollback (it is in a transaction) and set the table_sequence values. 

$schema->storage->dbh->rollback();

## The transaction change the values in the sequence, so if we want set the original value, before the changes
 ## we have two options:
  ##     1) SELECT setval (<sequence_name>, $last_value_before_change, true); that said, ok your last true value was...
   ##    2) SELECT setval (<sequence_name>, $last_value_before_change+1, false); It is false that your last value was ... so the 
    ##      next time take the value before this.
     ##  
      ##   The option 1 leave the seq information in a original state except if there aren't any value in the seq, that it is
       ##   more as the option 2 

$schema->set_sqlseq_values_to_original_state(\%last_ids);
