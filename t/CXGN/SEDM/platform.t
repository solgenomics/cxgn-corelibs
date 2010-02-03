#!/usr/bin/perl

=head1 NAME

  platform.t
  A piece of code to test the CXGN::SEDM::Platform module

=cut

=head1 SYNOPSIS

 perl platform.t

 Note: To run the complete test the database connection should be done as postgres user 
 (web_usr have not privileges to insert new data into the sed tables)  

=head1 DESCRIPTION

 This script check 29 variables to test the right operation of the CXGN::SEDM::Metadata module:
 
 + test from 1 to 16: Standard get/set methods for technology_type, platform and platform design
 + test from 17 to 20: Test for get/set data method for technology_type and platform
 + test for 21 and 22: Test for get/set data for platform_design_data methods
 + test 23: test for get/set platform_design_organism_list methods
 + test from 24 to 34: store function, and create a new objects using a platform_id 
 + test from 35 to 51: store function, check two different platform_design rows for the same platform object
 + test for 52 and 53: get platform design data function for a specific search 
 + test from 54 to 59: get platform design data using organism list function   
 + test from 60 to 67: search function and create a new object using technology_type_id

=cut

=head1 AUTHORS

 Aureliano Bombarely Gomez
 (ab782@cornell.edu)

=cut


use strict;
use Data::Dumper;
use Test::More tests=>73;  # use  qw | no_plan | while developing the tests

use CXGN::DB::Connection;


### Test 1 to 3, check the module use

BEGIN {
    use_ok('CXGN::SEDM::Schema');
    use_ok('CXGN::SEDM::Metadata');
    use_ok('CXGN::SEDM::Platform');
}


my $schema = CXGN::SEDM::Schema->connect( sub { CXGN::DB::Connection->new( { dbuser =>'postgres', 
									     dbpass =>'Eise!Th9',
									                         } )->get_actual_dbh() },
                                            { on_connect_do => ['SET search_path TO sed;'],
                                            },
                                            );



 ## FIRST TEST BLOCK; 

  ## Create an empty object (test 3 to 20)

my $platform = CXGN::SEDM::Platform->new($schema, undef); 

## 

my ($last_metadata_id) = $schema->get_last_primary_keys('metadata');
my ($last_technology_type_id) = $schema->get_last_primary_keys('technology_types');
my ($last_platform_id) = $schema->get_last_primary_keys('platforms');
my ($last_platform_design_id) = $schema->get_last_primary_keys('platforms_designs');
my ($last_group_id) = $schema->get_last_primary_keys('groups');
my ($last_group_linkage_id) = $schema->get_last_primary_keys('group_linkage');

my %test_values_empty_object = (    technology_type_id          => $last_technology_type_id+1, 
				    technology_type_name        => 'test technology type name', 
				    technology_type_description => 'test technology type description',
				    technology_type_metadata_id => $last_metadata_id+1,
				    platform_id                 => $last_platform_id+1, 
			            platform_name               => 'test platform name', 
			            platform_description        => 'test platform description',
			            contact_person_id           => 984,
			            platform_metadata_id        => $last_metadata_id+1,
                                );

my %test_values_platform_design = (  platform_design_id => $last_platform_design_id+1,
				     organism_group_id => 1, 
				     sequence_type => 'test sequence_type',
				     dbiref_id     => 1,
				     dbiref_type   => 'unigene',
				     description   => 'test platform_design',
				     metadata_id   => $last_metadata_id+1,
				     );

## Load the data in the empty object
my @function_keys=keys %test_values_empty_object;
foreach my $rootfunction (@function_keys) {
    my $setfunction='set_'.$rootfunction;
    $platform->$setfunction( $test_values_empty_object{$rootfunction} );
}

$platform->add_platform_design_data({%test_values_platform_design});

## Get the data from the object and store in two hashes. The first %getdata with keys=root_function_name and 
 ## value=value_get_from_object and the second, %testname with keys=root_function_name and values=name for the test.

my (%getdata, %testnames);
foreach my $rootfunction (@function_keys) {
    my $getfunction = 'get_'.$rootfunction;
    my $data = $platform->$getfunction();
    $getdata{$rootfunction} = $data;
    my $testname = 'SET/GET VALUES IN AN EMPTY OBJECT (' . $rootfunction .') technology_type and platform test';
    $testnames{$rootfunction} = $testname;
}

## And now run the test for each function and value

foreach my $rootfunction (@function_keys) {
    is($getdata{$rootfunction}, $test_values_empty_object{$rootfunction}, $testnames{$rootfunction}) 
	or diag "Looks like this failed.";
}

my ($platform_design_data_href) = $platform->get_platform_design_data();
my %platform_design_data = %{ $platform_design_data_href };
my @columns_for_platform_design = keys %test_values_platform_design;
my $n = 0;
foreach my $platform_design_col (@columns_for_platform_design) {
    my $expected_data = $test_values_platform_design{$platform_design_col};
    my $result_data = $platform_design_data{$platform_design_col};
    my $test_message = 'SET/GET/ADD VALUES IN AN EMPTY OBJECT (' . $platform_design_col . ') platform design test';
    is($result_data, $expected_data, $test_message) or diag "Looks like this failed";
}
$platform->delete_platform_design_data();
my ($platform_design_data_href_deleted) = $platform->get_platform_design_data();
is ($platform_design_data_href_deleted, undef, 'DELETE PLATFORM DESIGN DATA IN AN EMPTY OBJECT test') or diag "Looks like this failed";

 ## SECOND TEST BLOCK
## This block test the store function in two ways, as store a new metadata and modifing a data (it create a new one too). 
 ## It was runned as eval { }, because in the end of the test we need restore the database data (and if die... )
  ##  now we are going to store, but before could be a good idea get the last_id to set the seq after all the process.

### IF YOU REMOVE THE eval and RUN THE SCRIPT AND it die, the seq values will not be set to original values.

eval {

 ## Create a new empty object and set the values using set_platform_data, set_technology_type_data and set_platform_design_data.
 ## (test 21 to 27)

    my @check_platform_design_data;   ### Create an array to put all the platform design data that we want to check

    my $a_platform = CXGN::SEDM::Platform->new($schema, undef);
    $a_platform->set_technology_type_data( { technology_name =>'oligotest', description => 'test1' } );
    $a_platform->set_platform_data( { platform_name => 'affytest', description => 'test2'} );
    my %platform_design_data1 = ( sequence_type => 'esttest', description => 'test3' ); 
    push @check_platform_design_data, \%platform_design_data1;
    $a_platform->add_platform_design_data( { %platform_design_data1 });
    my ($a_platform_design_row) = $a_platform->get_platform_design_dbic_rows( { sequence_type => 'esttest' } );
    
    ## if none search parameter is used, it should set all the organism for all the platform_design_rows, in this case, the
    ## only platform_design that is inside the object.

    $a_platform->set_platform_design_organism_list({}, ['Nicotiana tabacum'] );

 ## We do not set any platform_id or technology_type_id because they do not exists yet into the database. These data will have
 ## platform_id and technology_type_id when they are stored into the database.
 ## Now we are going to see if these data are into the object.

    my %a_tech_type = $a_platform->get_technology_type_data();
    my %a_platform = $a_platform->get_platform_data();
    is ($a_tech_type{'technology_name'}, 'oligotest', 'GET/SET VALUES (technology_name) USING technology_type_data METHOD')
	or diag "Looks like this failed";
    is ($a_tech_type{'description'}, 'test1', 'GET/SET VALUES (description) USING technology_type_data METHOD') 
        or diag "Looks like this failed";
    is ($a_platform{'platform_name'}, 'affytest', 'GET/SET VALUES (platform_name) USING platform_data METHOD')
	or diag "Looks like this failed";
    is ($a_platform{'description'}, 'test2', 'GET/SET VALUES (description) USING platform_data METHOD')
	or diag "Looks like this failed";
    my ($a_platform_design_href) = $a_platform->get_platform_design_data({});
    my %a_platform_design = %{ $a_platform_design_href };
    is ($a_platform_design{'sequence_type'}, 'esttest', 'GET/SET VALUES (sequence_type) USING platform_design_data METHODS')
        or diag "Looks like this failed";
    is ($a_platform_design{'description'}, 'test3', 'GET/SET VALUES (description) USING platform_design_data METHODS')
        or diag "Looks like this failed";


    my @organism_list = $a_platform->get_platform_design_organism_list({});
    is ($organism_list[0], 'Nicotiana tabacum', 'GET/SET VALUES (organism_list) USING platform_design_organism_list METHODS')
        or diag "Looks like this failed";
    
## Difficult functions: Store (test 28)

    my $metadata = CXGN::SEDM::Metadata->new($schema, 'Aubombarely');
    my $new_platform_id = $a_platform->store($metadata);
    is ($new_platform_id, $last_platform_id+1, 'STORE FUNCTION, returning platform_id TEST') || diag "Looks like this failed";    

## Create a new platform object using the $new_platform_id (test 29 to 39)

    my $b_platform = CXGN::SEDM::Platform->new($schema, $new_platform_id);
    my %b_tech_type = $b_platform->get_technology_type_data();
    my %b_platform = $b_platform->get_platform_data();
    my ($b_platform_design_href) = $b_platform->get_platform_design_data({});
    my @b_organism_list = $b_platform->get_platform_design_organism_list({});
    is ($b_tech_type{'technology_type_id'}, $last_technology_type_id+1, 'STORE FUNCTION, new platform object TESTING technology_type_id')
	or diag "Looks like this failed";
    my $message = 'STORE FUNCTION, new platform object TESTING ';
    my @prev_tech_type_columns = keys %a_tech_type;
    foreach my $tech_col (@prev_tech_type_columns) {
	my $techmessage = $message . $tech_col;
	is ($b_tech_type{$tech_col}, $a_tech_type{$tech_col}, $techmessage) or diag "Looks like this failed";
    }
    is ($b_platform{'platform_id'}, $last_platform_id+1, 'STORE FUNCTION, new platform object TESTING platform_id') or
	diag "Looks like this failed";
    my @prev_platform_columns = keys %a_platform;
    foreach my $platf_col (@prev_platform_columns) {
	my $platfmessage = $message . $platf_col;
	is ($b_platform{$platf_col}, $a_platform{$platf_col}, $platfmessage) or diag "Looks like this failed";
    }
    my %b_platform_design = %{ $b_platform_design_href };
    my @prev_platform_design_col = keys %a_platform_design;
    is ($b_platform_design{'platform_design_id'}, $last_platform_design_id+1, 
	'STORE FUNCTION, new platform object TESTING platform design id') or diag "Looks like this failed";
    is ($b_platform_design{'platform_id'}, $last_platform_id+1, 'STORE FUNCTION, new platform object TESTING platform_design.platform_id')
	or diag "Looks like this failed";
    foreach my $platf_design_col (@prev_platform_design_col) {
	my $platfdesmessage = $message . $platf_design_col;
	is ($b_platform_design{$platf_design_col}, $a_platform_design{$platf_design_col}, $platfdesmessage) or 
	    diag "Looks like this failed";
    }

## Testing multiple elements for platform design.(test 40 to 55)

    my $organism_group_id1 = CXGN::SEDM::Platform->get_organism_group_id_from_db_by_organism_list($schema, ['Nicotiana tabacum']);
    my $organism_group_id2 = CXGN::SEDM::Platform->get_organism_group_id_from_db_by_organism_list($schema, ['Nicotiana sylvestris']);
    unless ( defined($organism_group_id2) ) {
	$organism_group_id2 = $b_platform->store_organism_group($metadata, ['Nicotiana sylvestris']);
    }
    my @organism_group_id_list = ( $organism_group_id1, $organism_group_id2 );
    my %platform_design_data2 = ( organism_group_id => $organism_group_id2, 
      			          sequence_type     => 'unigenetest',  
			          description       => 'description test4' );
    push @check_platform_design_data, \%platform_design_data2;
    $b_platform->add_platform_design_data( { %platform_design_data2 } );
    $b_platform->store($metadata, ['platforms_designs']);
    my @platform_design_href_list = $b_platform->get_platform_design_data({});
    is (scalar(@platform_design_href_list), 2, 
	'STORE FUNCTION, add new platform design TESTING element number in platform_design_href_list') or diag "Looks like this failed";
    my $n = 0;
    foreach my $platform_design_href (@platform_design_href_list) {
	my %platform_design = %{ $platform_design_href };
	my %expected_platform_design = %{ $check_platform_design_data[$n] };
	my @col = keys %platform_design;
	foreach my $col (@col) {
	    my $message1 = "STORE FUNCTION, add new platform design TESTING array_element[$n] for $col";
	    if ($col eq 'platform_design_id') {
		is($platform_design{$col}, $last_platform_design_id+$n+1, $message1) or diag("Looks like this failed");
	    } elsif ($col eq 'platform_id') {
		is($platform_design{$col}, $last_platform_id+1, $message1) or diag("Looks like this failed");
	    } elsif ($col eq 'organism_group_id') {
		is($platform_design{$col}, $organism_group_id_list[$n], $message1) or diag("Looks like this failed");
	    } elsif ($col eq 'metadata_id') {
		is($platform_design{$col}, $last_metadata_id+1, $message1) or diag("Looks like this failed");
	    } else {
		is($platform_design{$col}, $expected_platform_design{$col}, $message1) or diag("Looks like this failed");
	    }
	}
	$n++;
    }

## Testing get_platform_design_data using search parameters (test 56 to 57)

    my @platform_design_data_href_selected1 = $b_platform->get_platform_design_data( { sequence_type => 'unigenetest' } );
    
    ## We expected only one platform_design_data with sequence_type = 'unigenetest'

    is(scalar(@platform_design_data_href_selected1), 1, "GET platform design data function TESTING specific search, elements number") 
	or diag("Looks like this failed");
    my %platform_design_data_selected1 = %{ $platform_design_data_href_selected1[0] };
    is($platform_design_data_selected1{'sequence_type'},'unigenetest',"GET platform design data function TESTING specific search, value")
	or diag("Looks like this failed");
    
## Testing set/get platform_design_data_using_organism_list (test 58 to 63)

    $b_platform->set_platform_design_data_using_organism_list( { organism_list => ['Nicotiana sylvestris'] }, 
	                                                       { sequence_type => 'genome_sequence_test'} 
	                                                     );
    $b_platform->store($metadata, ['platforms_designs']);

    my @platform_design_data_href_selected2 = 
	$b_platform->get_platform_design_data_using_organism_list( { organism_list => ['Nicotiana sylvestris'] });
    my %platform_design_data_selected2 = %{ $platform_design_data_href_selected2[0] };

    is( scalar(@platform_design_data_href_selected2), 1, 
	"GET/SET platform design data by organism_list function TESTING specific search, elements number") 
	or diag("Looks like this failed");    
    is($platform_design_data_selected2{'sequence_type'}, 'genome_sequence_test',
       "GET/SET platform design data by organism_list function TESTING specific search, value set")
	or diag("Looks like this failed");
    my @organism_list = @{ $platform_design_data_selected2{'organism_list'} };
    is($organism_list[0], 'Nicotiana sylvestris', 
	"GET/SET platform design data by organism_list function TESTING specific search, organism value")
	or diag("Looks like this failed");
    is($platform_design_data_selected2{'platform_design_id'}, $last_platform_design_id+2,
       "GET/SET platform design data by organism_list function TESTING specific search, platform_design_id")
	or diag("Looks like this failed");
    is($platform_design_data_selected2{'platform_id'}, $last_platform_id+1,
       "GET/SET platform design data by organism_list function TESTING specific search, platform_id")
	or diag("Looks like this failed");
    is($platform_design_data_selected2{'metadata_id'}, $last_metadata_id+2,
       "GET/SET platform design data by organism_list function TESTING specific search, new metadata id for value updated")
	or diag("Looks like this failed");

## Testing search function (test 64 to 69)

    my @a_platform_id = CXGN::SEDM::Platform->search_platform_id($schema, { technology_types => { technology_name => 'oligotest'} });
    is (scalar(@a_platform_id), 1, "SEARCH METHOD, searching by technology_name, TESTING results number") or 
	diag("Looks like this failed");
    is ($a_platform_id[0], $last_platform_id+1, "SEARCH METHOD, searching by technology_name, TESTING result value") or 
	diag("Looks like this failed");
    my @b_platform_id = CXGN::SEDM::Platform->search_platform_id($schema, { platforms => { platform_name => 'affytest' } });
    is (scalar(@b_platform_id), 1, "SEARCH METHOD, searching by platform_name, TESTING results number") or 
	diag("Looks like this failed");
    is ($b_platform_id[0], $last_platform_id+1, "SEARCH METHOD, searching by platform_name, TESTING result value") or 
	diag("Looks like this failed");
    my @c_platform_id = CXGN::SEDM::Platform->search_platform_id($schema, { platforms_designs => { 
	                                                                                      organism_list => ['Nicotiana tabacum'] } });
    is (scalar(@c_platform_id), 1, "SEARCH METHOD, searching by organism_list, TESTING results number") or 
	diag("Looks like this failed");
    is ($c_platform_id[0], $last_platform_id+1, "SEARCH METHOD, searching by organism_list, TESTING result value") or 
	diag("Looks like this failed");

## Adding a new platform to see if the code get in the right way more than one platform_id (test 70 to 73)

    my $c_platform = CXGN::SEDM::Platform->create_new_with_technology_type_id($schema, $last_technology_type_id+1 );
    is( $c_platform->get_technology_type_name(), $a_tech_type{'technology_name'}, 
	"CREATE PLATFORM OBJECT using technology_type_id TESTING technology_name") or diag("Looks like this failed");

    $c_platform->set_platform_data( { platform_name      => 'affytest2', 
				      description        => 'this is another test'
				   } );
    $c_platform->add_platform_design_data( { sequence_type => 'esttest',
					     organism_list => ['Nicotiana tabacum'],
					     description   => 'this is another test'
					   } );
    my $c_platform_id = $c_platform->store($metadata);
    is ( $c_platform_id, $last_platform_id+2, "STORE PLATFORM OBJECT created using technology_type_id TESTING platform_id") or
	diag("Looks like this failed");
    my @platform_ids = CXGN::SEDM::Platform->search_platform_id( $schema, 
								 { platforms_designs => { organism_list => ['Nicotiana tabacum'] } } 
	                                                       );
    is ( scalar(@platform_ids), 2, "SEARCH METHOD, searching organism list for multiple platform, TESTING elements number") or
	diag("Looks like this failed");
    is ( $platform_ids[1], $last_platform_id+2, "SEARCH METHOD, searching organism list for multiple platform, TESTING platform_id") or
	diag("Looks like this failed");



};
if ($@) {
    print "\nEVAL ERROR:\n\n$@\n";
}

$schema->storage()->dbh->rollback();

## The transaction change the values in the sequence, so if we want set the original value, before the changes
 ## we have two options:
  ##     1) SELECT setval (<sequence_name>, $last_value_before_change, true); that said, ok your last true value was...
   ##    2) SELECT setval (<sequence_name>, $last_value_before_change+1, false); It is false that your last value was ... so the 
    ##      next time take the value before this.
     ##  
      ##   The option 1 leave the seq information in a original state except if there aren't any value in the seq, that it is
       ##   more as the option 2 

if ($last_metadata_id == 0) {
    $schema->storage->dbh->do("SELECT setval ('sed.metadata_metadata_id_seq', 1, false)");
} else {    
    $schema->storage->dbh->do("SELECT setval ('sed.metadata_metadata_id_seq', $last_metadata_id, true)");
}
if ($last_technology_type_id == 0) {
    $schema->storage->dbh->do("SELECT setval ('sed.technology_types_technology_type_id_seq', 1, false)");
} else {    
    $schema->storage->dbh->do("SELECT setval ('sed.technology_types_technology_type_id_seq', $last_technology_type_id, true)");
}
if ($last_platform_id == 0) {
    $schema->storage->dbh->do("SELECT setval ('sed.platforms_platform_id_seq', 1, false)");
} else {    
    $schema->storage->dbh->do("SELECT setval ('sed.platforms_platform_id_seq', $last_platform_id, true)");
}
if ($last_platform_design_id == 0) {
    $schema->storage->dbh->do("SELECT setval ('sed.platforms_designs_platform_design_id_seq', 1, false)");
} else {    
    $schema->storage->dbh->do("SELECT setval ('sed.platforms_designs_platform_design_id_seq', $last_platform_design_id, true)");
}
if ($last_group_id == 0) {
    $schema->storage->dbh->do("SELECT setval ('sed.groups_group_id_seq', 1, false)");
} else {    
    $schema->storage->dbh->do("SELECT setval ('sed.groups_group_id_seq', $last_group_id, true)");
}
if ($last_group_linkage_id == 0) {
    $schema->storage->dbh->do("SELECT setval ('sed.group_linkage_group_linkage_id_seq', 1, false)");
} else {    
    $schema->storage->dbh->do("SELECT setval ('sed.group_linkage_group_linkage_id_seq', $last_group_linkage_id, true)");
}
