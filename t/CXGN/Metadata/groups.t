#!/usr/bin/perl

=head1 NAME

  groups.t
  A piece of code to test the CXGN::Metadata::Groups module

=cut

=head1 SYNOPSIS

 perl Groups.t

 Note: To run the complete test the database connection should be done as 
       postgres user 
 (web_usr have not privileges to insert new data into the sed tables)  

 prove Groups.t

=head1 DESCRIPTION

 This script check XX variables to test the right operation of the 
 CXGN::Metadata::Groups module:

 + Tests from 1 to 4 - use of modules;
 + Tests from 5 to 8 - BASIC SET/GET FUNCTIONS
 + Test 9 - STORE FUNCTION with a new group row
 + Tests from 10 to 19 - STORE FUNCTION METADBDATA INTERACTION
 + Test 20 - IS OBSOLETE FUNCTION TEST
 + Test 21 and 22 - STORE FUNCTION with a modified group row
 + Tests from 23 to 32 - STORE FUNCTION METADBDATA INTERACTION FOR MODIFICATIONS
 + Test 33 - OBSOLETE FUNCTION TEST
 + Tests from 34 to 43 - STORE FUNCTION METADBDATA INTERACTION FOR OBSOLETE
 + Test 44 - REVERT OBSOLETE FUNCTION TEST
 + Test from 45 to 54 - STORE FUNCTION METADBDATA INTERACTION FOR REVERT OBSOLETE
 + Test from 55 to 61 - SET/GET MEMBER 
 + Test from 62 to 94 - STORE MEMBERS and  STORE FUNCTION METADBDATA FOR MEMBER
 + Test 95 and 96 - OBSOLETE MEMBER FUNCTION
 + Test 97 - NEW_BY_GROUP_NAME CONSTRUCTOR
 + Test 98 - ADD MEMBER METHOD,
 + Test 99 - GENERAL STORE FUNCTION,
 + Test 100 - GET MEMBERS FUNCTION with OBSOLETE TAG, 
 + Test 101 - GET MEMBERS FUNCTION with NON OBSOLETE TAG
 + Test 102 - Warning for new_by_member
 + Test 103 - New_by_member

=cut

=head1 AUTHORS

 Aureliano Bombarely Gomez
 (ab782@cornell.edu)

=cut


use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 103 ;# qw | no_plan |; # while developing the test
use Test::Exception;
use Test::Warn;

use CXGN::DB::Connection;
use CXGN::DB::DBICFactory;

BEGIN {
    use_ok('CXGN::Metadata::Schema');               ## TEST1
    use_ok('CXGN::Metadata::Groups');               ## TEST2
    use_ok('CXGN::Metadata::Metadbdata');           ## TEST3
    use_ok('CXGN::Metadata::Dbiref')                ## TEST4
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


## Get the last values
my $all_last_ids_href = $schema->get_all_last_ids($schema);
my %last_ids = %{$all_last_ids_href};
my $last_metadata_id = $last_ids{'metadata.md_metadata_metadata_id_seq'};
my $last_group_id = $last_ids{'metadata.md_groups_group_id_seq'};
my $last_dbiref_id = $last_ids{'metadata.md_dbiref_dbiref_id_seq'};

## Create a empty metadata object to use in the database store functions
my $metadbdata = CXGN::Metadata::Metadbdata->new($schema, 'aure');
my $creation_date = $metadbdata->get_object_creation_date();
my $creation_user_id = $metadbdata->get_object_creation_user_by_id();

## FIRST TEST BLOCK (TEST FROM 5 TO 8)
## This is the first group of tests, to check if an empty object can store and after can return the data
## Create a new empty object; 

my $group = CXGN::Metadata::Groups->new($schema, undef); 

## Load of the eight different parameters for an empty object using a hash with keys=root name for tha function and
 ## values=value to test

my %test_values_for_empty_object=( group_id          => $last_group_id+1,
				   group_name        => 'group test',
				   group_type        => 'dbipath',
				   group_description => 'group testing using dbipaths',
                                  );

## Load the data in the empty object
my @function_keys = sort keys %test_values_for_empty_object;
foreach my $rootfunction (@function_keys) {
    my $setfunction = 'set_' . $rootfunction;
    if ($rootfunction eq 'group_id') {
	$setfunction = 'force_set_' . $rootfunction;
    } 
    $group->$setfunction($test_values_for_empty_object{$rootfunction});
}
## Get the data from the object and store in two hashes. The first %getdata with keys=root_function_name and 
 ## value=value_get_from_object and the second, %testname with keys=root_function_name and values=name for the test.

my (%getdata, %testnames);
foreach my $rootfunction (@function_keys) {
    my $getfunction = 'get_'.$rootfunction;
    my $data = $group->$getfunction();
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

     ### It will create a new object based in dbipath (TEST 9)
     my $group2 = CXGN::Metadata::Groups->new($schema);
     $group2->set_group_name('group test2');
     $group2->set_group_type('dbipath');
     $group2->set_group_description('group testing using dbipaths');

     ### It will store it

     my $group3_stored = $group2->store_group($metadbdata);
     my $group3_id = $group3_stored->get_group_id();
     
     is($group3_id, $last_group_id+1, 'STORE FUNCTION with a new group row, checking group_id')
	 or diag "Looks like this failed";

     ## Checking the metadbdata associated to this new creation (TEST 10 to 19)

     my $metadbdata3 = $group3_stored->get_metadbdata();
     my %metadbdata3 = $metadbdata3->get_metadata_by_rows();

     my %expected_metadata3 = ( metadata_id      => $last_metadata_id+1, 
			        create_date      => $creation_date, 
			        create_person_id => $creation_user_id, 
			        obsolete         => 0 
 	                      );

     foreach my $metadata_type3 (keys %metadbdata3) {
 	my $message3 = "STORE FUNCTION METADBDATA INTERACTION, get_metadbdata test, checking $metadata_type3";
 	
	is($metadbdata3{$metadata_type3}, $expected_metadata3{$metadata_type3}, $message3) 
	    or diag "Looks like this failed";
     }

     ## Checking the is_obsolete function (TEST 20)
     
     my $obsolete = $group3_stored->is_obsolete();
     is($obsolete, 0,"IS OBSOLETE FUNCTION TEST") or diag "Looks like this failed";

     ## Testing a modification in the row data (TEST 21 and 22)

     $group3_stored->set_group_description('testing modifications in the description');
     my $group4_modified = $group3_stored->store_group($metadbdata);
     my $group4_id = $group4_modified->get_group_id();

     is($group4_id, $last_group_id+1, 'STORE FUNCTION with a modified group row, checking group_id')
 	or diag "Looks like this failed";

     my $group4_desc = $group4_modified->get_group_description();
     is($group4_desc, 'testing modifications in the description', 'STORE FUNCTION with a modified group row, checking group_description')
 	or diag "Looks like this failed";

     ## Checking the metadbdata associated to this modification (TEST 23 to 32)

     my $metadbdata4 = $group4_modified->get_metadbdata();
     my %metadbdata4 = $metadbdata4->get_metadata_by_rows();
     my %expected_metadata4 = ( metadata_id          => $last_metadata_id+2, 
				create_date          => $creation_date, 
				create_person_id     => $creation_user_id,
				modified_date        => $creation_date,
				modified_person_id   => $creation_user_id,
				modification_note    => 'set value in group_description column',
				previous_metadata_id => $last_metadata_id+1,
				obsolete             => 0 
 	                    );

     foreach my $metadata_type4 (keys %metadbdata4) {
 	my $message4 = "STORE FUNCTION METADBDATA INTERACTION FOR MODIFICATIONS, get_metadbdata test, checking $metadata_type4";
 	is($metadbdata4{$metadata_type4}, $expected_metadata4{$metadata_type4}, $message4) or diag "Looks like this failed";
     }

     ## Test the obsolete function (TEST 33)
     
     my $group5_obsolete = $group4_modified->obsolete_group($metadbdata, 'change to obsolete test');
     my $obsolete5 = $group5_obsolete->is_obsolete();
     is($obsolete5, 1,"OBSOLETE FUNCTION TEST") or diag "Looks like this failed";

     ## Checking the metadata associated to this obsolete change (TEST 34 to 43)
     
     my $metadbdata5 = $group5_obsolete->get_metadbdata();
     my %metadbdata5 = $metadbdata5->get_metadata_by_rows();
     my %expected_metadata5 = ( metadata_id          => $last_metadata_id+3, 
				create_date          => $creation_date, 
				create_person_id     => $creation_user_id,
				modified_date        => $creation_date,
				modified_person_id   => $creation_user_id,
				modification_note    => 'change to obsolete',
				previous_metadata_id => $last_metadata_id+2,
				obsolete             => 1,
				obsolete_note        => 'change to obsolete test'
	                      );
               
     foreach my $metadata_type5 (keys %metadbdata5) {

 	my $message5 = "STORE FUNCTION METADBDATA INTERACTION FOR OBSOLETE, get_metadbdata test, checking $metadata_type5";
 	is($metadbdata5{$metadata_type5}, $expected_metadata5{$metadata_type5}, $message5) or diag "Looks like this failed";
     }

     ## Test the REVERT tag for the obsolete function (TEST 44)

     my $group6_revert = $group5_obsolete->obsolete_group($metadbdata, 'revert obsolete test', 'REVERT');
     my $obsolete6 = $group6_revert->is_obsolete();
     is($obsolete6, 0,"REVERT OBSOLETE FUNCTION TEST") or diag "Looks like this failed";

     ## Checking the metadata associated to this obsolete change (TEST 45 to 54)

     my $metadbdata6 = $group6_revert->get_metadbdata();
     my %metadbdata6 = $metadbdata6->get_metadata_by_rows();
     my %expected_metadata6 = ( metadata_id          => $last_metadata_id+4, 
				create_date          => $creation_date, 
				create_person_id     => $creation_user_id,
				modified_date        => $creation_date,
				modified_person_id   => $creation_user_id,
				modification_note    => 'revert obsolete',
				previous_metadata_id => $last_metadata_id+3,
				obsolete             => 0,
				obsolete_note        => 'revert obsolete test'
 	                      );

     foreach my $metadata_type6 (keys %metadbdata6) {
 	my $message6 = "STORE FUNCTION METADBDATA INTERACTION FOR REVERT OBSOLETE, get_metadbdata test, checking $metadata_type6";

 	is($metadbdata6{$metadata_type6}, $expected_metadata6{$metadata_type6}, $message6) or diag "Looks like this failed";
     }

### THIRD BLOCK, test the member code
     
     ## First, we need to add some dbiref's. It will create three based in md_metadata table with the metadata_id
     ## created before. (TEST 55 to 61)

     my @dbiref_list =();
     my @metadata_ids = ($last_metadata_id+2, $last_metadata_id+3, $last_metadata_id+4);

     my $dbipath_id = CXGN::Metadata::Dbipath->new_by_path( $schema, 
							    ['metadata', 'md_metadata', 'metadata_id'] )
                                             ->store($metadbdata)
                                             ->get_dbipath_id();

     foreach my $met_id (@metadata_ids) {
	 my $dbiref = CXGN::Metadata::Dbiref->new($schema, undef); 
	 $dbiref->set_accession($met_id);
	 $dbiref->set_dbipath_id($dbipath_id);

	 my $dbiref_id = $dbiref->store($metadbdata)
	                        ->get_dbiref_id();

	 push @dbiref_list, $dbiref_id;
     }

     my $group7 = CXGN::Metadata::Groups->new($schema, $last_group_id+1);
     $group7->set_member_ids(\@dbiref_list);
     
     my @member_ids = $group7->get_member_ids();
     my $obj_member_ids = join(',', sort @member_ids);
     my $exp_member_ids = join(',', sort @dbiref_list);
     
     is($obj_member_ids, $exp_member_ids, 'SET/GET MEMBER IDS over the group object, checking dbiref_id list') 
	 or diag "Looks like this failed";

     my @members = $group7->get_members();
     my $n = 0;

     foreach my $member (@members) {
	 my @dbipath_elements = $member->get_dbipath_obj()
	                               ->get_dbipath();

	 my $g_dbipath_name = join('.', @dbipath_elements);
	 my $g_accession = $member->get_accession();
	 
	 my $c = $n + 1;	 
	 is($g_accession, $metadata_ids[$n], "SET/GET MEMBER $c the group object, checking dbiref object (dbiref_id)") 
	     or diag "Looks like this failed";
	 
	 $n++;
	     
	 is($g_dbipath_name, 'metadata.md_metadata.metadata_id', "SET/GET MEMBER $c over group object, checking dbiref object (dbipath)") 
	     or diag "Looks like this failed";
     }
     
     ## Test store member functions (TEST 62 to 94)
    
     my $group8_stored = $group7->store_members($metadbdata);
     my @stored_members = $group8_stored->get_members();
     my %member_metadata = $group8_stored->get_metadbdata_for_members($metadbdata);
     
     my $test1 = join(',', keys %member_metadata);
     my $test2 = join(',', values %member_metadata);


     my $m = 0;
     
     foreach my $stored_member (@stored_members) {
	 my $s_accession = $stored_member->get_accession();
	 my $s_dbiref_id = $stored_member->get_dbiref_id();

	 my $d = $m + 1;	 
	 is($s_accession, $metadata_ids[$m], "STORE MEMBERS ($d) the group object, checking dbiref object (dbiref_id)") 
	     or diag "Looks like this failed";
	 
	 $m++;
    
	 my %member_metadbdata8 = $member_metadata{$s_dbiref_id}->get_metadata_by_rows();
	 my %expected_metadata8 = ( metadata_id          => $last_metadata_id+1, 
				    create_date          => $creation_date, 
				    create_person_id     => $creation_user_id,
				    obsolete             => 0,
	                          );
	 foreach my $metadata_type8 (keys %member_metadbdata8) {
	     my $message8 = "STORE FUNCTION METADBDATA FOR MEMBER ($d), get_metadbdata test, checking $metadata_type8";

	     is($member_metadbdata8{$metadata_type8}, $expected_metadata8{$metadata_type8}, $message8) or diag "Looks like this failed";
	 }
     }

     ### Test obsolete member... and imagine that i don't remember the dbiref_id for the accession=$last_metadata_id+2 (TEST 95, 96)
     
     my $obsolete_dbiref_id = CXGN::Metadata::Dbiref->new_by_accession( $schema, 
									$last_metadata_id+2, 
									['metadata', 
									 'md_metadata', 
									 'metadata_id'] )
	                                            ->get_dbiref_id();
     my $non_obsolete_dbiref_id = CXGN::Metadata::Dbiref->new_by_accession( $schema, 
									    $last_metadata_id+3, 
									    ['metadata', 
									     'md_metadata', 
									     'metadata_id'] )
	                                                ->get_dbiref_id();

     my $group9 = $group8_stored->obsolete_member( $metadbdata, 
	                                           $obsolete_dbiref_id,
						   'obsolete a member test'
                                                 );
     my $obsolete_member1 = $group9->is_obsolete_member( $obsolete_dbiref_id );
     is($obsolete_member1, 1, "OBSOLETE MEMBER FUNCTION, is_obsolete_member test, ckecking boolean, true") 
	 or diag "Looks like this failed";
     my $obsolete_member2 = $group9->is_obsolete_member( $non_obsolete_dbiref_id );
     is($obsolete_member2, 0, "OBSOLETE MEMBER FUNCTION, is_obsolete_member test, ckecking boolean, false") 
	 or diag "Looks like this failed";

     ### Test new_by_group_name (TEST 97)

     my $group_name = $group7->get_group_name();
     
     my $group10 = CXGN::Metadata::Groups->new_by_group_name($schema, $group_name);
     
     is($group10->get_group_id(), $last_group_id+1, "NEW_BY_GROUP_NAME CONSTRUCTOR, checking group_id")
	 or diag "Looks like this failed";

     ## Test add a member

     ## It will create an empty object and set the values instead to create the object with these values
     ## because when it is created a new object with an accession that do not exists into the database return
     ## a warning message

     my $new_dbiref = CXGN::Metadata::Dbiref->new( $schema );
     $new_dbiref->set_accession($last_metadata_id+1);
     $new_dbiref->set_dbipath_id_by_dbipath_elements( ['metadata', 'md_metadata', 'metadata_id'] );
     
     my $new_dbiref_id = $new_dbiref->store($metadbdata)
				    ->get_dbiref_id();
     
     my $group11 = $group10->add_member($new_dbiref_id)
                           ->store($metadbdata);
     
     my @accessions = ();

     my @m_members = $group11->get_members();
     foreach my $m_member (@m_members) {
	 my $accession = $m_member->get_accession();
	 push @accessions, $accession;
     }

     ## The members should be the @metadata_ids + this $last_metadata_id+4 (TEST 98)
     
     push @metadata_ids, $last_metadata_id+1;
     my $expected_members = join(',', sort {$a <=> $b} @metadata_ids);
     my $obtained_members = join(',', sort {$a <=> $b} @accessions);
     is($obtained_members, $expected_members, "ADD MEMBER METHOD, cheking a list of member (dbiref_ids)")
	 or diag "Looks like this failed";

     ## Group11 also should have a group_id = $last_group_id+1 (TEST 99)

     is($group11->get_group_id(), $last_group_id+1, "GENERAL STORE FUNCTION, checking group_id")
	 or diag "Looks like this failed";
     
     ## Check the obsolete tag to get members, it will take $last_metadata_id+2, (TEST 100)
     my @obsolete_members = $group11->get_members('OBSOLETE');
     my $obs_accession = $obsolete_members[0]->get_accession();
     
     is($obs_accession, $last_metadata_id+2, "GET MEMBERS FUNCTION with OBSOLETE TAG, checking accessions for members")
	 or diag "Looks like this failed";

     ## Test the non obsolete too (TEST 101)
     my @non_obsolete_members = $group11->get_members('NON_OBSOLETE');

     my @non_obsolete_acc = ();
     foreach my $non_obsolete_member (@non_obsolete_members) {
	 my $non_obs_acc = $non_obsolete_member->get_accession();
	 push @non_obsolete_acc, $non_obs_acc;
     }
     
     my $obtained_non_obs = join(',', sort {$a <=> $b} @non_obsolete_acc);
     my $expected_non_obs = join(',', sort {$a <=> $b} ($last_metadata_id+3, $last_metadata_id+4, $last_metadata_id+1 ) );
     
     is($obtained_non_obs, $expected_non_obs, "GET MEMBERS FUNCTION with NON OBSOLETE TAG, checking accessions for members")
	 or diag "Looks like this failed";


     ## Testing new by members.

     my @members12 = ();
     foreach my $m_metadata_id (@metadata_ids) {
	 my $m_dbiref_id = CXGN::Metadata::Dbiref->new_by_accession( $schema, 
								     $m_metadata_id, 
									['metadata', 
									 'md_metadata', 
									 'metadata_id'] )
	                                            ->get_dbiref_id();
	 push @members12, $m_dbiref_id;
     }

     my $group12;
     warning_like { $group12 = CXGN::Metadata::Groups->new_by_members($schema, \@members12);  } qr/DATABASE COHERENCE/, 
    'TESTING WARNING ERROR when do not existsa group with the specified elements into the database';

     my $group12_id = $group12->get_group_id();
     
     ## This is to test if fail to find the group to store the new group and check the new group_id
     unless (defined $group12_id) {
	 $group12_id = $group12->store($metadbdata)
	                       ->get_group_id();
     }
     
     is($group12_id, $last_group_id+2, "NEW_BY_MEMBERS CONSTRUCTOR, checking the group_id") or diag "Looks like this failed";

	 


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

###
1;#
###
