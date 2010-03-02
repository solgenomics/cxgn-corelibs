#!/usr/bin/perl

=head1 NAME

  template.t
  A piece of code to test the CXGN::GEM::Template module

=cut

=head1 SYNOPSIS

 perl template.t

 Note: To run the complete test the database connection should be done as 
       postgres user 
 (web_usr have not privileges to insert new data into the gem tables)  

 prove template.t

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

 This script check 90 variables to test the right operation of the 
 CXGN::GEM::Template module:

=cut

=head1 AUTHORS

 Aureliano Bombarely Gomez
 (ab782@cornell.edu)

=cut


use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 92; # qw | no_plan |; # while developing the test
use Test::Exception;
use Test::Warn;

use CXGN::DB::Connection;
use CXGN::DB::DBICFactory;

BEGIN {
    use_ok('CXGN::GEM::Schema');             ## TEST1
    use_ok('CXGN::GEM::Platform');           ## TEST2
    use_ok('CXGN::GEM::Template');           ## TEST3
    use_ok('CXGN::Biosource::Sample');       ## TEST4
    use_ok('CXGN::Biosource::Protocol');     ## TEST5
    use_ok('CXGN::Metadata::Metadbdata');    ## TEST6
    use_ok('CXGN::Metadata::Dbiref');        ## TEST7
    use_ok('CXGN::Metadata::Dbipath');       ## TEST8
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
my $last_platform_id = $last_ids{'gem.ge_platform_platform_id_seq'} || 0;
my $last_template_id = $last_ids{'gem.ge_template_template_id_seq'} || 0;
my $last_dbxref_id = $last_ids{'public.dbxref_dbxref_id_seq'} || 0;
my $last_dbiref_id = $last_ids{'metadata.dbiref_dbiref_id_seq'} || 0;
my $last_dbipath_id = $last_ids{'metadata.dbipath_dbipath_id_seq'} || 0;


## Create a empty metadata object to use in the database store functions
my $metadbdata = CXGN::Metadata::Metadbdata->new($schema, $creation_user_name);
my $creation_date = $metadbdata->get_object_creation_date();
my $creation_user_id = $metadbdata->get_object_creation_user_by_id();


#######################################
## FIRST TEST BLOCK: Basic functions ##
#######################################

## (TEST FROM 9 to 12)
## This is the first group of tests, to check if an empty object can store and after can return the data
## Create a new empty object; 

my $template = CXGN::GEM::Template->new($schema, undef); 

## Load of the eight different parameters for an empty object using a hash with keys=root name for tha function and
## values=value to test

my %test_values_for_empty_object=( template_id      => $last_template_id+1,
				   template_name    => 'template test',
				   template_type    => 'template type test',
				   platform_id      => $last_platform_id+1,
                                  );

## Load the data in the empty object
my @function_keys = sort keys %test_values_for_empty_object;
foreach my $rootfunction (@function_keys) {
    my $setfunction = 'set_' . $rootfunction;
    if ($rootfunction eq 'template_id') {
	$setfunction = 'force_set_' . $rootfunction;
    } 
    $template->$setfunction($test_values_for_empty_object{$rootfunction});
}

## Get the data from the object and store in two hashes. The first %getdata with keys=root_function_name and 
 ## value=value_get_from_object and the second, %testname with keys=root_function_name and values=name for the test.

my (%getdata, %testnames);
foreach my $rootfunction (@function_keys) {
    my $getfunction = 'get_'.$rootfunction;
    my $data = $template->$getfunction();
    $getdata{$rootfunction} = $data;
    my $testname = 'BASIC SET/GET FUNCTION for ' . $rootfunction.' test';
    $testnames{$rootfunction} = $testname;
}

## And now run the test for each function and value

foreach my $rootfunction (@function_keys) {
    is($getdata{$rootfunction}, $test_values_for_empty_object{$rootfunction}, $testnames{$rootfunction}) 
	or diag "Looks like this failed.";
}


## Testing the die results (TEST 13 to 22)

throws_ok { CXGN::GEM::Template->new() } qr/PARAMETER ERROR: None schema/, 
    'TESTING DIE ERROR when none schema is supplied to new() function';

throws_ok { CXGN::GEM::Template->new($schema, 'no integer')} qr/DATA TYPE ERROR/, 
    'TESTING DIE ERROR when a non integer is used to create a protocol object with new() function';

throws_ok { CXGN::GEM::Template->new($schema)->set_getemplate_row() } qr/PARAMETER ERROR: None getemplate_row/, 
    'TESTING DIE ERROR when none schema is supplied to set_getemplate_row() function';

throws_ok { CXGN::GEM::Template->new($schema)->set_getemplate_row($schema) } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_getemplate_row() is not a CXGN::GEM::Schema::GeTemplate row object';

throws_ok { CXGN::GEM::Template->new($schema)->force_set_template_id() } qr/PARAMETER ERROR: None/, 
    'TESTING DIE ERROR when none template_id is supplied to set_force_template_id() function';

throws_ok { CXGN::GEM::Template->new($schema)->force_set_template_id('non integer') } qr/DATA TYPE ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_force_template_id() is not an integer';

throws_ok { CXGN::GEM::Template->new($schema)->set_template_name() } qr/PARAMETER ERROR: None data/, 
    'TESTING DIE ERROR when none data is supplied to set_template_name() function';

throws_ok { CXGN::GEM::Template->new($schema)->set_template_type() } qr/PARAMETER ERROR: None data/, 
    'TESTING DIE ERROR when none data is supplied to set_template_type() function';

throws_ok { CXGN::GEM::Template->new($schema)->set_platform_id() } qr/PARAMETER ERROR: None/, 
    'TESTING DIE ERROR when none platform_id is supplied to set_platform_id() function';

throws_ok { CXGN::GEM::Template->new($schema)->set_platform_id('non integer') } qr/DATA TYPE ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_platform_id() is not an integer';



################################################################
## SECOND TEST BLOCK: Platform Store and Obsolete Functions ##
################################################################

## Use of store functions.

eval {

    ## Before work with any store function for Template, it will need create a Platform and Technology_type row inside 
    ## the database to get a real platform_id
    
    my $techtype1 = CXGN::GEM::TechnologyType->new($schema);
    $techtype1->set_technology_name('techtype1');
    $techtype1->set_description('description test for technology_type');

    $techtype1->store($metadbdata);
    my $techtype_id1 = $techtype1->get_technology_type_id();

    my $platform1 = CXGN::GEM::Platform->new($schema);
    $platform1->set_platform_name('exp1_test');
    $platform1->set_technology_type_id($techtype_id1);
    $platform1->set_description('description test for platform');
    $platform1->set_contact_id($creation_user_id);

    $platform1->store($metadbdata);
    my $platform_id1 = $platform1->get_platform_id();

    ## Now it will create the Template Object.
    
    my $template1 = CXGN::GEM::Template->new($schema);
    $template1->set_template_name('template1');
    $template1->set_template_type('type test');
    $template1->set_platform_id($platform_id1);

    $template1->store_template($metadbdata);


    ## Testing the platform data stored (TEST 23 TO 25)

    my $template_id1 = $template1->get_template_id();
    is($template_id1, $last_template_id+1, "TESTING STORE_TEMPLATE FUNCTION, checking template_id")
 	or diag "Looks like this failed";

    my $template2 = CXGN::GEM::Template->new($schema, $template_id1);
    is($template2->get_template_name(), 'template1', "TESTING STORE_TEMPLATE FUNCTION, checking template_name")
	or diag "Looks like this failed";
    is($template2->get_platform_id(), $platform_id1, "TESTING STORE_TEMPLATE FUNCTION, checking platform_id")
 	or diag "Looks like this failed";


    ## Testing the get_medatata function (TEST 26 to 28)

    my $obj_metadbdata = $template2->get_template_metadbdata();
    is($obj_metadbdata->get_metadata_id(), $last_metadata_id+1, "TESTING GET_METADATA FUNCTION, checking the metadata_id")
	 or diag "Looks like this failed";
    is($obj_metadbdata->get_create_date(), $creation_date, "TESTING GET_METADATA FUNCTION, checking create_date")
	 or diag "Looks like this failed";
    is($obj_metadbdata->get_create_person_id_by_username, $creation_user_name, 
        "TESING GET_METADATA FUNCTION, checking create_person by username")
	 or diag "Looks like this failed";
    
    ## Testing die for store_platform function (TEST 29 and 30)

    throws_ok { $template2->store_template() } qr/STORE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to store_template() function';
    
    throws_ok { $template2->store_template($schema) } qr/STORE ERROR: Metadbdata supplied/, 
    'TESTING DIE ERROR when argument supplied to store_template() is not a CXGN::Metadata::Metadbdata object';
    
    ## Testing if it is_obsolete (TEST 31)

    is($template2->is_template_obsolete(), 0, "TESTING IS_TEMPLATE_OBSOLETE FUNCTION, checking boolean")
	 or diag "Looks like this failed";

    ## Testing obsolete functions (TEST 32 to 35) 

    $template2->obsolete_template($metadbdata, 'testing obsolete');
    
    is($template2->is_template_obsolete(), 1, 
       "TESTING TEMPLATE_OBSOLETE FUNCTION, checking boolean after obsolete the template")
 	or diag "Looks like this failed";
    
    is($template2->get_template_metadbdata()->get_metadata_id, $last_metadata_id+2, 
       "TESTING TEMPLATE_OBSOLETE, checking metadata_id")
 	or diag "Looks like this failed";
    
    $template2->obsolete_template($metadbdata, 'testing obsolete', 'REVERT');
    
    is($template2->is_template_obsolete(), 0, 
       "TESTING REVERT TEMPLATE_OBSOLETE FUNCTION, checking boolean after revert obsolete")
 	or diag "Looks like this failed";

    is($template2->get_template_metadbdata()->get_metadata_id, $last_metadata_id+3, 
       "TESTING REVERT TEMPLATE_OBSOLETE, for metadata_id")
	or diag "Looks like this failed";

    ## Testing die for obsolete function (TEST 36 to 38)

    throws_ok { $template2->obsolete_template() } qr/OBSOLETE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_template() function';
    
    throws_ok { $template2->obsolete_template($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
    'TESTING DIE ERROR when argument supplied to obsolete_template() is not a CXGN::Metadata::Metadbdata object';
    
    throws_ok { $template2->obsolete_template($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
    'TESTING DIE ERROR when none obsolete note is supplied to obsolete_template() function';
    
    ## Testing store for modifications (TEST 39 to 42)

    $template2->set_template_type('another template type');
    $template2->store_template($metadbdata);
      
    is($template2->get_template_id(), $last_template_id+1, 
       "TESTING STORE_TEMPLATE for modifications, checking the template_id")
 	or diag "Looks like this failed";
    is($template2->get_template_name(), 'template1', 
       "TESTING STORE_TEMPLATE for modifications, checking the template_name")
 	or diag "Looks like this failed";
    is($template2->get_template_type(), 'another template type', 
       "TESTING STORE_TEMPLATE for modifications, checking template_type")
	or diag "Looks like this failed";

    my $obj_metadbdata2 = $template2->get_template_metadbdata();
    is($obj_metadbdata2->get_metadata_id(), $last_metadata_id+4, 
       "TESTING STORE_TEMPLATE for modifications, checking new metadata_id")
 	or diag "Looks like this failed";
    

    ## Testing new by name
    
    ## Die functions (TEST 43)
    
    throws_ok { CXGN::GEM::Template->new_by_name() } qr/PARAMETER ERROR: None schema/, 
    'TESTING DIE ERROR when none schema is supplied to constructor: new_by_name()';
    
    ## Warning function (TEST 44)
    warning_like { CXGN::GEM::Template->new_by_name($schema, 'fake element') } qr/DATABASE OUTPUT WARNING/, 
    'TESTING WARNING ERROR when the template_name do not exists into the database';
		   
    ## Constructor (TEST 45)
    
    my $template3 = CXGN::GEM::Template->new_by_name($schema, 'template1');
    is($template3->get_template_id(), $last_template_id+1, "TESTING NEW_BY_NAME, checking template_id")
	or diag "Looks like this failed";
    
    
    ############################################
    ## THIRD BLOCK: Template_Dbxref functions ##
    ############################################
    
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

    
    ## Testing the die when the wrong for the row accessions get/set_geexpdesigndbxref_rows (TEST 46 to 48)
    
    throws_ok { $template3->set_getemplatedbxref_rows() } qr/FUNCTION PARAMETER ERROR:None getemplatedbxref_row/, 
    'TESTING DIE ERROR when none data is supplied to set_getemplatedbxref_rows() function';
    
    throws_ok { $template3->set_getemplatedbxref_rows('this is not an integer') } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when data type supplied to set_getemplatedbxref_rows() function is not an array reference';
    
    throws_ok { $template3->set_getemplatedbxref_rows([$schema, $schema]) } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when the elements of the array reference supplied to set_getemplatedbxref_rows() function are not row objects';

    ## Check set/get for dbxref (TEST 49)

    $template3->add_dbxref($new_dbxref_id1);
    $template3->add_dbxref( 
  	                    { 
  		  	      accession => 'TESTDBACC02', 
  		              dbxname   => 'dbtesting',
  		            }
  	                  );

    my @dbxref_list = ($new_dbxref_id1, $new_dbxref_id2);
    my @dbxref_id_list = $template3->get_dbxref_list();
    my $expected_dbxref_id_list = join(',', sort {$a <=> $b} @dbxref_list);
    my $obtained_dbxref_id_list = join(',', sort {$a <=> $b} @dbxref_id_list);

    is($obtained_dbxref_id_list, $expected_dbxref_id_list, 'TESTING ADD_DBXREF and GET_DBXREF_LIST, checking dbxref_id list')
  	or diag "Looks like this failed";

    ## Store function (TEST 50)

    $template3->store_dbxref_associations($metadbdata);
    
    my $template4 = CXGN::GEM::Template->new($schema, $template3->get_template_id() );
    
    my @dbxref_id_list2 = $template4->get_dbxref_list();
    my $expected_dbxref_id_list2 = join(',', sort {$a <=> $b} @dbxref_list);
    my $obtained_dbxref_id_list2 = join(',', sort {$a <=> $b} @dbxref_id_list2);
    
    is($obtained_dbxref_id_list2, $expected_dbxref_id_list2, 'TESTING STORE DBXREF ASSOCIATIONS, checking dbxref_id list')
	or diag "Looks like this failed";

    ## Testing die for store function (TEST 51 AND 52)
    
    throws_ok { $template3->store_dbxref_associations() } qr/STORE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to store_dbxref_associations() function';
    
    throws_ok { $template3->store_dbxref_associations($schema) } qr/STORE ERROR: Metadbdata supplied/, 
    'TESTING DIE ERROR when argument supplied to store_dbxref_associations() is not a CXGN::Metadata::Metadbdata object';

    ## Testing obsolete functions (TEST 53 to 55)
     
    my $m = 0;
    foreach my $dbxref_assoc (@dbxref_id_list2) {
 	$m++;
  	is($template4->is_template_dbxref_obsolete($dbxref_assoc), 0, 
  	   "TESTING GET_TEMPLATE_DBXREF_METADATA AND IS_PLATFORM_DBXREF_OBSOLETE, checking boolean ($m)")
  	    or diag "Looks like this failed";
    }

    my %expdbxref_md1 = $template4->get_template_dbxref_metadbdata();
    is($expdbxref_md1{$dbxref_id_list[1]}->get_metadata_id, $last_metadata_id+1, 
       "TESTING GET_TEMPLATE_DBXREF_METADATA, checking metadata_id")
	or diag "Looks like this failed";

    ## TEST 56 TO 59

    $template4->obsolete_dbxref_association($metadbdata, 'obsolete test for dbxref', $dbxref_id_list[1]);
    is($template4->is_template_dbxref_obsolete($dbxref_id_list[1]), 1, 
       "TESTING OBSOLETE TEMPLATE DBXREF ASSOCIATIONS, checking boolean") 
  	or diag "Looks like this failed";

    my %templatedbxref_md2 = $template4->get_template_dbxref_metadbdata();
    is($templatedbxref_md2{$dbxref_id_list[1]}->get_metadata_id, $last_metadata_id+5, 
       "TESTING OBSOLETE TEMPLATE DBXREF FUNCTION, checking new metadata_id")
  	or diag "Looks like this failed";

    $template4->obsolete_dbxref_association($metadbdata, 'revert obsolete test for dbxref', $dbxref_id_list[1], 'REVERT');
    is($template4->is_template_dbxref_obsolete($dbxref_id_list[1]), 0, 
       "TESTING OBSOLETE DBXREF ASSOCIATIONS REVERT, checking boolean") 
  	or diag "Looks like this failed";

    my %templatedbxref_md2o = $template4->get_template_dbxref_metadbdata();
    my $templatedbxref_metadata_id2 = $templatedbxref_md2o{$dbxref_id_list[1]}->get_metadata_id();
    is($templatedbxref_metadata_id2, $last_metadata_id+6, "TESTING OBSOLETE DBXREF FUNCTION REVERT, checking new metadata_id")
  	or diag "Looks like this failed";
    
    ## Checking the errors for obsolete_dbxref_asociation (TEST 60 TO 63)
    
    throws_ok { $template4->obsolete_dbxref_association() } qr/OBSOLETE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_dbxref_association() function';

    throws_ok { $template4->obsolete_dbxref_association($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
    'TESTING DIE ERROR when argument supplied to obsolete_dbxref_association() is not a CXGN::Metadata::Metadbdata object';
    
    throws_ok { $template4->obsolete_dbxref_association($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
    'TESTING DIE ERROR when none obsolete note is supplied to obsolete_dbxref_association() function';
    
    throws_ok { $template4->obsolete_dbxref_association($metadbdata, 'test note') } qr/OBSOLETE ERROR: None dbxref_id/, 
    'TESTING DIE ERROR when none dbxref_id is supplied to obsolete_dbxref_association() function';

    ############################################
    ## FORTH BLOCK: Template_Dbiref functions ##
    ############################################
    
    ## Testing of the dbiref

    ## First, it need to add all the rows that the metadata schema use for dbiref
 
    my $dbipath1 = CXGN::Metadata::Dbipath->new($schema);
    $dbipath1->set_dbipath( 'gem', 'ge_platform', 'platform_id' );
    
    $dbipath1->store($metadbdata);
    my $dbipath_id1 = $dbipath1->get_dbipath_id();

    my $dbipath2 = CXGN::Metadata::Dbipath->new($schema);
    $dbipath2->set_dbipath( 'gem', 'ge_technology_type', 'technology_type_id' );
    
    $dbipath2->store($metadbdata);
    my $dbipath_id2 = $dbipath2->get_dbipath_id();


    my $dbiref1 = CXGN::Metadata::Dbiref->new($schema);
    $dbiref1->set_accession($platform_id1);
    $dbiref1->set_dbipath_id($dbipath_id1);

    $dbiref1->store($metadbdata);
    my $dbiref_id1 = $dbiref1->get_dbiref_id();

     my $dbiref2 = CXGN::Metadata::Dbiref->new($schema);
    $dbiref2->set_accession($techtype_id1);
    $dbiref2->set_dbipath_id($dbipath_id2);

    $dbiref2->store($metadbdata);
    my $dbiref_id2 = $dbiref2->get_dbiref_id();
    
    ## Testing the die when the wrong for the row accessions get/set_geexpdesigndbxref_rows (TEST 64 to 66)
    
    throws_ok { $template3->set_getemplatedbxref_rows() } qr/FUNCTION PARAMETER ERROR:None getemplatedbxref_row/, 
    'TESTING DIE ERROR when none data is supplied to set_getemplatedbxref_rows() function';
    
    throws_ok { $template3->set_getemplatedbxref_rows('this is not an integer') } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when data type supplied to set_getemplatedbxref_rows() function is not an array reference';
    
    throws_ok { $template3->set_getemplatedbxref_rows([$schema, $schema]) } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when the elements of the array reference supplied to set_getemplatedbxref_rows() function are not row objects';

    ## Check set/get for dbiref (TEST 67)

    $template3->add_dbiref($dbiref_id1);
    $template3->add_dbiref( 
  	                    { 
  		  	      accession => $techtype_id1, 
  		              dbipath   => ['gem' , 'ge_technology_type' , 'technology_type_id'],
  		            }
  	                  );

    my @dbiref_list = ($dbiref_id1, $dbiref_id2);
    my @dbiref_id_list = $template3->get_dbiref_list();
    my $expected_dbiref_id_list = join(',', sort {$a <=> $b} @dbiref_list);
    my $obtained_dbiref_id_list = join(',', sort {$a <=> $b} @dbiref_id_list);

    is($obtained_dbiref_id_list, $expected_dbiref_id_list, 'TESTING ADD_DBIREF and GET_DBIREF_LIST, checking dbiref_id list')
  	or diag "Looks like this failed";

    ## Store function (TEST 68)

    $template3->store_dbiref_associations($metadbdata);
    
    my $template5 = CXGN::GEM::Template->new($schema, $template3->get_template_id() );
    
    my @dbiref_id_list2 = $template5->get_dbiref_list();
    my $expected_dbiref_id_list2 = join(',', sort {$a <=> $b} @dbiref_list);
    my $obtained_dbiref_id_list2 = join(',', sort {$a <=> $b} @dbiref_id_list2);
    
    is($obtained_dbiref_id_list2, $expected_dbiref_id_list2, 'TESTING STORE DBIREF ASSOCIATIONS, checking dbiref_id list')
	or diag "Looks like this failed";

    ## Testing die for store function (TEST 69 AND 70)
    
    throws_ok { $template3->store_dbiref_associations() } qr/STORE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to store_dbiref_associations() function';
    
    throws_ok { $template3->store_dbiref_associations($schema) } qr/STORE ERROR: Metadbdata supplied/, 
    'TESTING DIE ERROR when argument supplied to store_dbiref_associations() is not a CXGN::Metadata::Metadbdata object';

    ## Testing obsolete functions (TEST 71 to 73)
     
    my $n = 0;
    foreach my $dbiref_assoc (@dbiref_id_list2) {
 	$n++;
  	is($template5->is_template_dbiref_obsolete($dbiref_assoc), 0, 
  	   "TESTING GET_TEMPLATE_DBIREF_METADATA AND IS_PLATFORM_DBIREF_OBSOLETE, checking boolean ($n)")
  	    or diag "Looks like this failed";
    }

    my %expdbiref_md1 = $template5->get_template_dbiref_metadbdata();
    is($expdbiref_md1{$dbiref_id_list[1]}->get_metadata_id, $last_metadata_id+1, 
       "TESTING GET_TEMPLATE_DBIREF_METADATA, checking metadata_id")
	or diag "Looks like this failed";

    ## TEST 74 TO 77

    $template5->obsolete_dbiref_association($metadbdata, 'obsolete test for dbiref', $dbiref_id_list[1]);
    is($template5->is_template_dbiref_obsolete($dbiref_id_list[1]), 1, 
       "TESTING OBSOLETE TEMPLATE DBIREF ASSOCIATIONS, checking boolean") 
  	or diag "Looks like this failed";

    my %templatedbiref_md2 = $template5->get_template_dbiref_metadbdata();
    is($templatedbiref_md2{$dbiref_id_list[1]}->get_metadata_id, $last_metadata_id+7, 
       "TESTING OBSOLETE TEMPLATE DBIREF FUNCTION, checking new metadata_id")
  	or diag "Looks like this failed";

    $template5->obsolete_dbiref_association($metadbdata, 'revert obsolete test for dbxref', $dbiref_id_list[1], 'REVERT');
    is($template5->is_template_dbiref_obsolete($dbiref_id_list[1]), 0, 
       "TESTING OBSOLETE DBIREF ASSOCIATIONS REVERT, checking boolean") 
  	or diag "Looks like this failed";

    my %templatedbiref_md2o = $template5->get_template_dbiref_metadbdata();
    my $templatedbiref_metadata_id2 = $templatedbiref_md2o{$dbiref_id_list[1]}->get_metadata_id();
    is($templatedbiref_metadata_id2, $last_metadata_id+8, "TESTING OBSOLETE DBIREF FUNCTION REVERT, checking new metadata_id")
  	or diag "Looks like this failed";
    
    ## Checking the errors for obsolete_dbxref_asociation (TEST 78 TO 81)
    
    throws_ok { $template4->obsolete_dbiref_association() } qr/OBSOLETE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_dbiref_association() function';

    throws_ok { $template4->obsolete_dbiref_association($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
    'TESTING DIE ERROR when argument supplied to obsolete_dbiref_association() is not a CXGN::Metadata::Metadbdata object';
    
    throws_ok { $template4->obsolete_dbiref_association($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
    'TESTING DIE ERROR when none obsolete note is supplied to obsolete_dbiref_association() function';
    
    throws_ok { $template4->obsolete_dbiref_association($metadbdata, 'test note') } qr/OBSOLETE ERROR: None dbiref_id/, 
    'TESTING DIE ERROR when none dbiref_id is supplied to obsolete_dbiref_association() function';


    #########################################
    ## FIFTH BLOCK: General Store function ##
    #########################################

    ## First, check if it die correctly (TEST 82 AND 83)

    throws_ok { $template4->store() } qr/STORE ERROR: None metadbdata/, 
    'TESTING DIE ERROR when none metadbdata object is supplied to store() function';
    
    throws_ok { $template4->store($schema) } qr/STORE ERROR: Metadbdata supplied/, 
    'TESTING DIE ERROR when argument supplied to store() is not a CXGN::Metadata::Metadbdata object';

    my $template6 = CXGN::GEM::Template->new($schema);
    $template6->set_template_name('template test2');
    $template6->set_template_type('type1');
    $template6->set_platform_id($platform_id1);
    
    $template6->add_dbxref($new_dbxref_id1);
    $template6->add_dbiref($dbiref_id1);

    $template6->store($metadbdata);

    ## Checking the parameters stored

    ## TEST 84 TO 86
    
    is($template6->get_template_id(), $last_template_id+2, 
       "TESTING GENERAL STORE FUNCTION, checking platform_id")
	or diag "Looks like this failed";

    my @dbxref_list3 = $template6->get_dbxref_list();
    is($dbxref_list3[0], $new_dbxref_id1, "TESTING GENERAL STORE FUNCTION, checking dbxref_id")
	or diag "Looks like this failed"; 

    my @dbiref_list3 = $template6->get_dbiref_list();
     is($dbiref_list3[0], $dbiref_id1, "TESTING GENERAL STORE FUNCTION, checking dbiref_id")
 	 or diag "Looks like this failed"; 
    

    #################################################################
    ## SIXTH BLOCK: Functions that interact with other GEM objects ##
    #################################################################
   
    ## Testing platform object (TEST 87 and 88)
     
    my $platform3 = $template5->get_platform();

    is(ref($platform3), 'CXGN::GEM::Platform', 
       "TESTING GET_PLATFORM function, testing object reference")
 	or diag "Looks like this failed";
    is($platform3->get_platform_name(), 'exp1_test', 
       "TESTING GET_PLATFORM function, testing platform_name")
 	or diag "Looks like this failed";

    ## Testing get dbiref objects (TEST 89 and 90)

    my @dbiref_obj_list = $template5->get_dbiref_obj_list();

    is(ref($dbiref_obj_list[0]), 'CXGN::Metadata::Dbiref', 
       "TESTING GET_DBIREF_OBJ_LIST function, testing object reference")
 	or diag "Looks like this failed";
    is($dbiref_obj_list[0]->get_dbiref_id(), $dbiref_id1, 
       "TESTING GET_DBIREF_OBJ_LIST function, testing dbiref_id")
 	or diag "Looks like this failed";
    
    ## Testing get_iref_accessions (TEST 91 and 92)

    my @iref_accessions1 = $template5->get_internal_accessions('platform');
    
    foreach my $iref_accession1 (@iref_accessions1) {
	is($iref_accession1, $platform_id1, 
       "TESTING GET_INTERNAL_ACCESSIONS function, testing platform_id")
 	or diag "Looks like this failed";
    }

     my @iref_accessions2 = $template5->get_internal_accessions('technology_type');
    
    foreach my $iref_accession2 (@iref_accessions2) {
	is($iref_accession2, $techtype_id1, 
       "TESTING GET_INTERNAL_ACCESSIONS function, testing technology_type_id")
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
