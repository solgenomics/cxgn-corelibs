#!/usr/bin/perl

=head1 NAME

  protocol.t
  A piece of code to test the CXGN::Biosource::ProtocolTool module

=cut

=head1 SYNOPSIS

 perl protocoltool.t

 Note: To run the complete test the database connection should be done as 
       postgres user 
 (web_usr have not privileges to insert new data into the sed tables)  

 prove protocoltool.t

=head1 DESCRIPTION

 This script check 58 variables to test the right operation of the 
 CXGN::Biosource::ProtocolTool module:

  - Test 1 to 3 - use modules
  - Test 4 to 9 - BASIC SET/GET FUNCTIONS
  - Test 10 to 20 - TESTING DIE ERROR for BASIC ACCESSORS
  - Test 21 and 22 - TESTING STORE FUNCTIONS
  - Test 23 to 25 - TESTING GET_METADATA FUNCTION
  - Test 26 and 27 - TESTING DIE ERROR for store() function
  - Test 28 to 30 - TESTING STORE FUNCTION for modification
  - Test 31 - TESTING GET/SET FILE BY NAME, cheking full file name
  - Test 32 to 37 - TESTING OBSOLETE FUNCTIONS AND ERRORS
  - Test 38 - TESTING NEW_BY_NAME, checking tool_type
  - Test 39 to 44 - TESTING GET/SET TOOL DATA FUNCTIONS for new_by_name()
  - Test 45 to 47 - TESTING ADD_PUBLICATION and GET_PUBLICATION_LIST
  - Test 48 to 50- TESTING STORE PUB ASSOCIATION and ERRORS
  - Test 51 to 53 - TESTING GET_TOOL_PUB_METADATA AND IS_TOOL_PUB_OBSOLETE.
  - Test 54 to 58- TESTING OBSOLETE PUB ASSOCIATIONS and DIE ERRORS

=cut

=head1 AUTHORS

 Aureliano Bombarely Gomez
 (ab782@cornell.edu)

=cut


use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 58; #qw | no_plan |; # while developing the test
use Test::Exception;

use CXGN::DB::Connection;
use CXGN::DB::DBICFactory;

BEGIN {
    use_ok('CXGN::Biosource::Schema');               ## TEST1
    use_ok('CXGN::Biosource::ProtocolTool');         ## TEST2
    use_ok('CXGN::Metadata::Metadbdata');            ## TEST3
}

#if we cannot load the CXGN::Biosource::Schema module, no point in continuing
CXGN::Biosource::Schema->can('connect')
    or BAIL_OUT('could not load the CXGN::Biosource::Schema module');


## The biosource schema contain all the metadata classes so don't need to create another Metadata schema


## The triggers need to set the search path to tsearch2 in the version of psql 8.1
my $psqlv = `psql --version`;
chomp($psqlv);

my @schema_list = ('biosource', 'metadata', 'public');
if ($psqlv =~ /8\.1/) {
    push @schema_list, 'tsearch2';
}

my $schema = CXGN::DB::DBICFactory->open_schema( 'CXGN::Biosource::Schema', 
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
my $last_tool_id = $last_ids{'biosource.bs_protocol_protocol_id_seq'};
my $last_file_id = $last_ids{'metadata.md_files_file_id_seq'};

## Create a empty metadata object to use in the database store functions
my $metadbdata = CXGN::Metadata::Metadbdata->new($schema, 'aure');
my $creation_date = $metadbdata->get_object_creation_date();
my $creation_user_id = $metadbdata->get_object_creation_user_by_id();

## FIRST TEST BLOCK (TEST FROM 4 TO 9)
## This is the first group of tests, to check if an empty object can store and after can return the data
## Create a new empty object; 

my $tool = CXGN::Biosource::ProtocolTool->new($schema, undef); 

## Load of the eight different parameters for an empty object using a hash with keys=root name for tha function and
 ## values=value to test

my %test_values_for_empty_object=( tool_id             => $last_tool_id+1,
				   tool_name           => 'protocol test',
				   tool_type           => 'test',
				   tool_description    => 'this is a test',
				   tool_weblink        => 'www.tooltest.com',
				   file_id             => $last_file_id+1,
                                  );

## Load the data in the empty object
my @function_keys = sort keys %test_values_for_empty_object;
foreach my $rootfunction (@function_keys) {
    my $setfunction = 'set_' . $rootfunction;
    if ($rootfunction eq 'tool_id') {
	$setfunction = 'force_set_' . $rootfunction;
    } 
    $tool->$setfunction($test_values_for_empty_object{$rootfunction});
}
## Get the data from the object and store in two hashes. The first %getdata with keys=root_function_name and 
 ## value=value_get_from_object and the second, %testname with keys=root_function_name and values=name for the test.

my (%getdata, %testnames);
foreach my $rootfunction (@function_keys) {
    my $getfunction = 'get_'.$rootfunction;
    my $data = $tool->$getfunction();
    $getdata{$rootfunction} = $data;
    my $testname = 'BASIC SET/GET FUNCTION for ' . $rootfunction.' test';
    $testnames{$rootfunction} = $testname;
}

## And now run the test for each function and value

foreach my $rootfunction (@function_keys) {
    is($getdata{$rootfunction}, $test_values_for_empty_object{$rootfunction}, $testnames{$rootfunction}) 
	or diag "Looks like this failed.";
}

## Testing the die results (TEST 10 to 20)

throws_ok { CXGN::Biosource::ProtocolTool->new() } qr/PARAMETER ERROR: None schema/, 
    'TESTING DIE ERROR when none schema is supplied to new() function';

throws_ok { CXGN::Biosource::ProtocolTool->new($schema, 'no integer')} qr/DATA TYPE ERROR/, 
    'TESTING DIE ERROR when a non integer is used to create a tool object with new() function';

throws_ok { CXGN::Biosource::ProtocolTool->new($schema)->set_bstool_row() } qr/PARAMETER ERROR: None bstool_row/, 
    'TESTING DIE ERROR when none schema is supplied to set_bstool_row() function';

throws_ok { CXGN::Biosource::ProtocolTool->new($schema)->set_bstool_row($schema) } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_bstool_row() is not a CXGN::Biosource::Schema::BsTool row object';

throws_ok { CXGN::Biosource::ProtocolTool->new($schema)->force_set_tool_id() } qr/PARAMETER ERROR: None tool_id/, 
    'TESTING DIE ERROR when none tool_id is supplied to set_force_tool_id() function';

throws_ok { CXGN::Biosource::ProtocolTool->new($schema)->force_set_tool_id('non integer') } qr/DATA TYPE ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_force_tool_id() is not an integer';

throws_ok { CXGN::Biosource::ProtocolTool->new($schema)->set_tool_name() } qr/PARAMETER ERROR: None data/, 
    'TESTING DIE ERROR when none data is supplied to set_tool_name() function';

throws_ok { CXGN::Biosource::ProtocolTool->new($schema)->set_tool_type() } qr/PARAMETER ERROR: None data/, 
    'TESTING DIE ERROR when none data is supplied to set_tool_type() function';

throws_ok { CXGN::Biosource::ProtocolTool->new($schema)->set_file_id('non integer') } qr/DATA TYPE ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_file_id() is not an integer';

throws_ok { CXGN::Biosource::ProtocolTool->new($schema)->set_file_id_by_name() } qr/PARAMETER ERROR:/, 
    'TESTING DIE ERROR when none data is supplied to set_file_id_by_name() function';

throws_ok { CXGN::Biosource::ProtocolTool->new($schema)->set_file_id_by_name('/test/non existing file') } qr/DATABASE ASSOCIATED ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_file_id_by_name() do not exists into the database';

### SECOND TEST BLOCK
### Use of store functions.

 eval {

     my $tool2 = CXGN::Biosource::ProtocolTool->new($schema);
     $tool2->set_tool_name('tool_test');
     $tool2->set_tool_type('test');
     $tool2->set_tool_description('This is a tool description test');

     $tool2->store($metadbdata);

     ## Testing the tool_id and tool_name for the new object stored (TEST 21 and 22)

     is($tool2->get_tool_id(), $last_tool_id+1, "TESTING STORE FUNCTION, checking the tool_id")
 	or diag "Looks like this failed";
     is($tool2->get_tool_name(), 'tool_test', "TESTING STORE FUNCTION, checking the tool_name")
 	or diag "Looks like this failed";

     ## Testing the get_medatata function (TEST 23 to 25)

     my $obj_metadbdata = $tool2->get_metadbdata();
     is($obj_metadbdata->get_metadata_id(), $last_metadata_id+1, "TESTING GET_METADATA FUNCTION, checking the metadata_id")
 	or diag "Looks like this failed";
     is($obj_metadbdata->get_create_date(), $creation_date, "TESTING GET_METADATA FUNCTION, checking create_date")
 	or diag "Looks like this failed";
     is($obj_metadbdata->get_create_person_id_by_username, 'aure', "TESTING GET_METADATA FUNCTION, checking create_person by username")
 	or diag "Looks like this failed";
    
     ## Testing die for store function (TEST 26 and 27)

     throws_ok { $tool2->store() } qr/STORE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to store() function';

     throws_ok { $tool2->store($schema) } qr/STORE ERROR: Metadbdata supplied/, 
     'TESTING DIE ERROR when argument supplied to store() is not a CXGN::Metadata::Metadbdata object';

     ## It will test the functions associated to the file_id so we need a a file_id. (TEST 28 and 31)

     my $file_row = $schema->resultset('MdFiles')->new({ 
	                                                 basename    => 'filetest', 
							 dirname     => 'dirtest/', 
							 filetype    => 'txt',
						         metadata_id => $obj_metadbdata->get_metadata_id(),
						       });
     my $file_id = $file_row->insert()
	                    ->discard_changes()
			    ->get_column('file_id');

     $tool2->set_file_id_by_name('dirtest/filetest');
     $tool2->store($metadbdata);

     is($tool2->get_tool_id(), $last_tool_id+1, "TESTING STORE FUNCTION for modification, checking tool_id")
	 or diag "Looks like this failed";

     is($tool2->get_metadbdata()->get_metadata_id(), $last_metadata_id+2, "TESTING STORE FUNCTION for modification, checking metadata_id")
	 or diag "Looks like this failed";

     is($tool2->get_metadbdata()->get_modified_date(), $creation_date, "TESTING STORE FUNCTION for modification, checking modif date")
	 or diag "Looks like this failed";

     is($tool2->get_file_name(), 'dirtest/filetest', "TESTING GET/SET FILE BY NAME, cheking full file name")
	 or diag "Looks like this failed";

     ## Testing if it is obsolete (TEST 32)

     is($tool2->is_obsolete(), 0, "TESTING IS_OBSOLETE FUNCTION, checking boolean")
 	or diag "Looks like this failed";

     ## Testing obsolete (TEST 33 and 34)

     $tool2->obsolete($metadbdata, 'testing obsolete');
    
     is($tool2->is_obsolete(), 1, "TESTING OBSOLETE FUNCTION, checking boolean after obsolete the tool")
 	or diag "Looks like this failed";

     $tool2->obsolete($metadbdata, 'testing obsolete', 'REVERT');
    
     is($tool2->is_obsolete(), 0, "TESTING REVERT OBSOLETE FUNCTION, checking boolean after revert obsolete")
 	or diag "Looks like this failed";

     ## Testing die for obsolete function (TEST 35 to 37)

     throws_ok { $tool2->obsolete() } qr/OBSOLETE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to obsolete() function';

     throws_ok { $tool2->obsolete($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
     'TESTING DIE ERROR when argument supplied to obsolete() is not a CXGN::Metadata::Metadbdata object';

     throws_ok { $tool2->obsolete($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
     'TESTING DIE ERROR when none obsolete note is supplied to obsolete() function';
    
     ## Testing new by name (TEST 38)

     my $tool3 = CXGN::Biosource::ProtocolTool->new_by_name($schema, 'tool_test');
     is($tool3->get_tool_type(), 'test', "TESTING NEW_BY_NAME, checking tool_type")
 	or diag "Looks like this failed";


     ## Testing get/set_tool_data function (TEST 39 to 44)

     $tool3->set_tool_data({ tool_type => 'another_test', tool_description => 'another_test_description' });
     
     my %new_tool_data = $tool3->store($metadbdata)
	                       ->get_tool_data();
    
     is($new_tool_data{'tool_id'}, $last_tool_id+1, 'TESTING GET/SET TOOL DATA FUNCTIONS, checking unchanged tool_id')
	 or diag "Looks like this failed";
     is($new_tool_data{'tool_type'}, 'another_test', 'TESTING GET/SET TOOL DATA FUNCTIONS, checking changed tool_type')
	 or diag "Looks like this failed";
     is($new_tool_data{'tool_description'}, 'another_test_description', 'TESTING GET/SET TOOL DATA FUNCTIONS, checking changed tool_desc')
	 or diag "Looks like this failed";
     is($tool3->get_metadbdata()->get_metadata_id, $last_metadata_id+5, 'TESTING GET/SET TOOL DATA FUNCTIONS, checking new metadata_id')
	 or diag "Looks like this failed";

     throws_ok { $tool3->set_tool_data() } qr/FUNCTION PARAMETER ERROR: None hash ref/, 
     'TESTING DIE ERROR when none hash reference is supplied to set_tool_data() function';

     throws_ok { $tool3->set_tool_data('this is not a hash reference') } qr/DATA TYPE ERROR: The hash ref/, 
     'TESTING DIE ERROR when argument supplied to set_tool_data() is not a hash reference';

     ### testing the publications functions. (TEST 45 to 47)

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

     my $new_dbxref_id = $schema->resultset('General::Dbxref')
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

     my $new_cvterm_id = $schema->resultset('Cv::Cvterm')
	                        ->new( 
                                   { 
				      cv_id      => $new_cv_id,
                                      name       => 'testingcvterm',
                                      definition => 'this is a test for add tool-pub relation',
                                      dbxref_id  => $new_dbxref_id,
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
					 type_id        => $new_cvterm_id,
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
				        type_id        => $new_cvterm_id,
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
				        type_id        => $new_cvterm_id,
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
				        dbxref_id => $new_dbxref_id,   
                                      }
                                    )
			       ->insert();


     $tool3->add_publication($new_pub_id1);
     $tool3->add_publication({ title => 'testingtitle2' });
     $tool3->add_publication({ dbxref_accession => 'TESTDBACC01' });

     my @pub_id_list = $tool3->get_publication_list();
     my $expected_pub_id_list = join(',', sort {$a <=> $b} @pub_list);
     my $obtained_pub_id_list = join(',', sort {$a <=> $b} @pub_id_list);

     is($obtained_pub_id_list, $expected_pub_id_list, 'TESTING ADD_PUBLICATION and GET_PUBLICATION_LIST, checking pub_id list')
	 or diag "Looks like this failed";

     my @pub_title_list = $tool3->get_publication_list('title');
     my $expected_pub_title_list = 'testingtitle1,testingtitle2,testingtitle3';
     my $obtained_pub_title_list = join(',', sort @pub_title_list);
     
     is($obtained_pub_title_list, $expected_pub_title_list, 'TESTING GET_PUBLICATION_LIST TITLE, checking pub_title list')
	 or diag "Looks like this failed";


     ## Only the third pub has associated a dbxref_id (the rest will be undef)
     my @pub_accession_list = $tool3->get_publication_list('accession');
     my $expected_pub_accession_list = 'TESTDBACC01';
     my $obtained_pub_accession_list = $pub_accession_list[2];   
     
     is($obtained_pub_accession_list, $expected_pub_accession_list, 'TESTING GET_PUBLICATION_LIST ACCESSION, checking pub_accession list')
	 or diag "Looks like this failed";

     ## Store functions (TEST 48)

     $tool3->store_pub_associations($metadbdata);
     
     my $tool4 = CXGN::Biosource::ProtocolTool->new($schema, $tool3->get_tool_id() );
     
     my @pub_id_list2 = $tool4->get_publication_list();
     my $expected_pub_id_list2 = join(',', sort {$a <=> $b} @pub_list);
     my $obtained_pub_id_list2 = join(',', sort {$a <=> $b} @pub_id_list2);

     is($obtained_pub_id_list2, $expected_pub_id_list2, 'TESTING STORE PUB ASSOCIATIONS, checking pub_id list')
	 or diag "Looks like this failed";

     ## Testing die for store function (TEST 49 and 50)

     throws_ok { $tool3->store_pub_associations() } qr/STORE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to store_pub_associations() function';

     throws_ok { $tool3->store_pub_associations($schema) } qr/STORE ERROR: Metadbdata supplied/, 
     'TESTING DIE ERROR when argument supplied to store_pub_associations() is not a CXGN::Metadata::Metadbdata object';

     ## Testing obsolete functions (TEST 51 to 54)
     
     my $n = 0;
     foreach my $pub_assoc (@pub_id_list2) {
	 $n++;
	 is($tool4->is_tool_pub_obsolete($pub_assoc), 0, "TESTING GET_TOOL_PUB_METADATA AND IS_TOOL_PUB_OBSOLETE, checking boolean ($n)")
	     or diag "Looks like this failed";
     }

     $tool4->obsolete_pub_association($metadbdata, 'obsolete test', $pub_id_list[1]);
     is($tool4->is_tool_pub_obsolete($pub_id_list[1]), 1, "TESTING OBSOLETE PUB ASSOCIATIONS, checking boolean") 
	 or diag "Looks like this failed";

     ## Checking the errors for obsolete_pub_asociation (TEST 55 to 58)

     throws_ok { $tool4->obsolete_pub_association() } qr/OBSOLETE ERROR: None metadbdata/, 
     'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_pub_association() function';

     throws_ok { $tool4->obsolete_pub_association($schema) } qr/OBSOLETE ERROR: Metadbdata/, 
     'TESTING DIE ERROR when argument supplied to obsolete_pub_association() is not a CXGN::Metadata::Metadbdata object';

     throws_ok { $tool4->obsolete_pub_association($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
     'TESTING DIE ERROR when none obsolete note is supplied to obsolete_pub_association() function';

     throws_ok { $tool4->obsolete_pub_association($metadbdata, 'test note') } qr/OBSOLETE ERROR: None pub_id/, 
     'TESTING DIE ERROR when none pub_id is supplied to obsolete_pub_association() function';
     

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

